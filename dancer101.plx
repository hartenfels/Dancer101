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
use C101::Validator;

my $server    = C101::Server->new;
my $forms     = YAML::LoadFile('forms.yml');
my $validator = C101::Validator->new(forms => $forms);
my $config    = YAML::LoadFile('web_ui.yml');

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
    my $o = $server->get($id)
        or return (0, {type => 'error', text => "$id does not exist."});
    return $o;
}

sub op {
    my ($o,     $error   ) = object_from(param 'id');
    return $error if not $o;
    my ($title, $callback) = @_;
    return {
        messages => "$title: " . $callback->(ref $o eq 'ARRAY' ? @$o : $o),
    };
}

ajax '/depth'  => sub { op('Depth',  \&depth ) };
ajax '/median' => sub { op('Median', \&median) };
ajax '/total'  => sub { op('Total',  \&total ) };

ajax '/cut' => sub {
    my ($o, $error) = object_from(param 'id');
    return $error if not $o;
    my @commands;
    for (cut(ref $o eq 'ARRAY' ? @$o : $o)) {
        push @commands, {type => 'edit', node => $_}
    }
    return {commands => \@commands};
};

ajax '/edit' => sub {
    {message => {type => 'error', text => 'This operation is not supported yet.'}};
};

ajax '/delete' => sub {
    my ($o, $error) = object_from(param 'id');
    return $error if not $o;
    return {type => 'error', text => "Can't delete root."} if ref $o eq 'ARRAY';
    $server->remove($o);
    return {commands => {type => 'delete', id => $o->uuid}};
};

ajax '/restructure' => sub {
    my ($source, $error) = object_from(param 'id');
    return $error if not $source;
    (my $target, $error) = object_from(param 'target');
    return $error if not $target;

    $target->can_adopt($source) or return {
        type => 'error',
        text => 'Restructure: Incompatible types.'
    };

    my $list   = $target->children;
    my $pos    = param 'pos' // $#$list;
    my ($rm)   = remove(sub { $_[0] == $source }, $server->companies);
    my $offset = $rm && $rm->{list} == $list && $pos >= $rm->{index}
               ? $pos - 1
               : $pos;
    splice $list, $offset, 0, $source;

    return {
        commands => {
            type   => 'move',
            source => $source->uuid,
            target => $target->uuid,
            pos    => $pos,
        },
    };
};

ajax '/company' => sub {{
    commands => {
        type   => 'form',
        title  => 'Create Company',
        submit => '/create_company',
        fields => $forms->{company},
    },
}};

ajax '/create_company' => sub {
    my ($valid, $result) = $validator->validate(company => scalar params);
    if ($valid) {
        my $node = C101::Company->new($result);
        push @{$server->companies}, $node;
        return {
            form     => {valid => 1},
            messages => "Added company $result->{name}.",
            commands => {
                type   => 'add',
                parent => 'root',
                node   => $node,
            },
        };
    } else {
        return {
            form     => {errors => $result},
            messages => {text => 'Invalid form data.', type => 'error'},
        };
    }
};

get '/' => sub { send_file '/web_ui.html' };


# Exit gracefully on interrupt
$SIG{INT} = sub {
    $server->save;
    exit;
};


dance;

