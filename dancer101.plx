#!/usr/bin/perl
use strict;
use warnings;
use Dancer;
use Dancer::Plugin::Ajax;
use File::Slurp       qw(slurp write_file);
use YAML;
use C101::Operations  qw(cut depth median total uuids remove);
use C101::Persistence qw(parse unparse);
use C101::Sample;
use C101::Validator;


sub load_model {
    my $path = setting('company_file');
    if (-e $path) {
        return uuids(parse(scalar slurp($path)));
    } else {
        return C101::Sample::create;
    }
}

my ($model)   = load_model;
my $uuids     = \%C101::Model::uuids;
my $web_ui    = YAML::LoadFile('web_ui.yml');
my $forms     = YAML::LoadFile('forms.yml');
my $validator = C101::Validator->new(forms => $forms);


sub err {
    my @err = (messages => [{type => 'error', text => shift}]);
    return wantarray ? @err : {@err};
}

sub object_from {
    my $id  = shift         or return (0, scalar err('No ID given.'       ));
    my $obj = $uuids->{$id} or return (0, scalar err("$id does not exist."));
    return $obj;
}


get  '/' => sub { send_file '/web_ui.html' };
ajax '/' => sub { $web_ui                  };


ajax '/tree' => sub { $model };


sub op {
    my ($obj,   $error   ) = object_from(param 'id');
    return $error if not $obj;
    my ($title, $callback) = @_;
    return {messages => "$title: " . $callback->($obj)};
}

ajax '/depth'  => sub { op('Depth',  \&depth ) };
ajax '/median' => sub { op('Median', \&median) };
ajax '/total'  => sub { op('Total',  \&total ) };


ajax '/cut' => sub {
    my ($obj, $error) = object_from(param 'id');
    return $error if not $obj;
    my @commands;
    push @commands, {type => 'edit', node => $_} for cut($obj);
    return {commands => \@commands};
};


ajax '/delete' => sub {
    my ($obj, $error) = object_from(param 'id');
    return $error if not $obj;
    return err("Can't delete root.") if $obj->type_name eq 'root';
    for my $rm (remove(sub { $_[0] == $obj }, $model->children)) {
        delete $uuids->{$rm->{obj}->id};
    }
    return {commands => {type => 'delete', id => $obj->id}};
};


ajax '/restructure' => sub {
    my ($source, $error) = object_from(param 'id');
    return $error if not $source;
    (my $target, $error) = object_from(param 'target');
    return $error if not $target;

    $target->child_types->{$source->type_name}
        or return err('Restructure: Incompatible types.');

    my $list   = $target->children;
    my $pos    = param 'pos' // $#$list;
    my ($rm)   = remove(sub { $_[0] == $source }, $model->children);
    my $offset = $rm && $rm->{list} == $list && $pos >= $rm->{index}
               ? $pos - 1
               : $pos;
    splice $list, $offset, 0, $source;

    return {
        commands => {
            type   => 'move',
            source => $source->id,
            target => $target->id,
            pos    => $pos,
        },
    };
};

sub field_values {
    my ($o, $fields) = @_;
    my @values;
    for my $f (@$fields) {
        my $method = $f->{name};
        push @values, {%$f, value => $o->$method};
    }
    return \@values;
}

while (my ($type, $form) = each %$forms) {
    ajax "/$type" => sub {{
        commands => {
            type   => 'form',
            title  => "Create $form->{label}",
            submit => "/save/add/$type/${\param 'id'}",
            fields => $form->{fields},
        },
    }};
}


ajax '/edit' => sub {
    my ($o, $error) = object_from(param 'id');
    return $error if not $o;
    my $type = $o->type_name;
    my $form = $forms->{$type} or return err("Don't know how to edit a $type.");
    return {
        commands => {
            type   => 'form',
            title  => "Edit $form->{label}",
            submit => "/save/edit/$type/" . $o->id,
            fields => field_values($o, $form->{fields}),
        },
    };
};


ajax '/save/*/*/*' => sub {
    my ($action, $type, $id) = splat;
    my ($valid,  $result   ) = $validator->validate($type => scalar params);
    $valid or return {
        form => {errors => $result},
        err('The form data entered was invalid.'),
    };

    if ($action eq 'add') {
        my ($parent, $list);
        if ($type eq 'company') {
            ($parent, $list) = ($model->id, $model->children);
        } else {
            my $t = $uuids->{$id}    or return err("$id does not exist."   );
            $t->child_types->{$type} or return err("$id can't adopt $type.");
            ($parent, $list) = ($t->id, $t->children);
        }

        my $node = $forms->{$type}{class}->new($result);
        # $uuids{$node->id} = $node;
        push @$list, $node;

        return {
            form     => {valid => 1},
            messages => "Added $result->{text}.",
            commands => {
                type   => 'add',
                parent => $parent,
                node   => $node,
            },
        };
    } else {
        my $node = $uuids->{$id}  or return err("$id does not exist.");
        $node->type_name eq $type or return err("$id is not a $type.");

        while (my ($k, $v) = each %$result) { $node->$k($v) }

        return {
            form     => {valid => 1},
            messages => "Modified $result->{text}",
            commands => {type => 'edit', node => $node},
        };
    }
};


# Exit gracefully on interrupt
$SIG{INT} = sub {
    write_file setting('company_file'), unparse($model);
    exit;
};

dance;
