#!/usr/bin/perl
use strict;
use warnings;
use feature              qw(say switch);
use Dancer;
use Dancer::Plugin::Ajax;
use Data::Dumper;
use YAML;
use C101::Operations     qw(cut depth median total remove);
use C101::Server;

my $server = C101::Server->new;
my $config = YAML::LoadFile('web_ui.yml');

ajax '/' => sub {
    my $type = param 'type';
    if ($type eq 'config') {
        return $config;
    } else {
        return {
            messages => {
                text => "Unknown request: $type",
                type => 'error'
            },
        };
    }
};

ajax '/tree' => sub {{
    type     => 'root',
    id       => 'root',
    text     => 'Companies',
    state    => {'opened' => 1},
    children => $server->companies,
}};


sub object_from {
    my $id  = shift
        or return (0, {type => 'error', text => 'No ID given.'       });
    my $obj = $server->get($id)
        or return (0, {type => 'error', text => "$id does not exist."});
    return $obj;
}

sub op {
    my ($obj,   $error   ) = object_from(param 'id');
    return $error if not $obj;
    my ($title, $callback) = @_;
    return {messages => "$title: " . &$callback(ref $obj eq 'ARRAY' ? @$obj : $obj)};
}

ajax '/depth'  => sub { op('Depth',  \&depth ) };
ajax '/median' => sub { op('Median', \&median) };
ajax '/total'  => sub { op('Total',  \&total ) };

ajax '/cut' => sub {
    my ($obj, $error) = object_from(param 'id');
    return $error if not $obj;
    my @commands;
    push @commands, {type => 'edit', node => $_} for cut(ref $obj eq 'ARRAY' ? @$obj : $obj);
    return {commands => \@commands};
};

ajax '/edit' => sub {
    {message => {type => 'error', text => 'This operation is not supported yet.'}};
};

ajax '/delete' => sub {
    my ($obj, $error) = object_from(param 'id');
    return $error if not $obj;
    return {type => 'error', text => "Cannot delete root."} if ref $obj eq 'ARRAY';
    $server->remove($obj);
    return {commands => {type => 'delete', id => $obj->uuid}};
};

ajax '/restructure' => sub {
    my ($source, $error) = object_from(param 'id');
    return $error if not $source;
    (my $target, $error) = object_from(param 'target');
    return $error if not $target;

    return {type => 'error', text => 'Restructuring Error: Incompatible types.'}
        if not $target->can_adopt($source);

    my $list   = $target->children;
    my $pos    = param 'pos' // $#$list;
    my ($rm)   = remove(sub { $_[0] == $source }, $server->companies);
    my $offset = $rm && $rm->{list} == $list && $pos >= $rm->{index} ? $pos - 1 : $pos;
    splice $list, $offset, 0, $source;

    return {commands => {
        type   => 'move',
        source => $source->uuid,
        target => $target->uuid,
        pos    => $pos,
    }};
};

get '/' => sub { send_file '/web_ui.html' };


# Exit gracefully so that all destructors will be called.
$SIG{INT} = sub {
    $server->save;
    exit;
};


dance;

