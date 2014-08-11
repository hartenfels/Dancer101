#!/usr/bin/perl
use strict;
use warnings;
use Dancer;
use Dancer::Plugin::Ajax;
use YAML;
use C101::Operations     qw(cut depth median total remove);
use C101::Server;
use C101::Validator;


my $forms     = YAML::LoadFile('forms.yml');
my $web_ui    = YAML::LoadFile('web_ui.yml');
my $server    = C101::Server->new;
my $validator = C101::Validator->new(forms => $forms);


sub err {
    my @err = (messages => [{type => 'error', text => shift}]);
    return wantarray ? @err : {@err};
};

sub object_from {
    my $id = shift             or return (0, err('No ID given.'       ));
    my $o  = $server->get($id) or return (0, err("$id does not exist."));
    return $o;
}


get  '/' => sub { send_file '/web_ui.html' };
ajax '/' => sub { $web_ui                  };


ajax '/tree' => sub {{
    type     => 'root',
    id       => 'root',
    text     => 'Companies',
    state    => {'opened' => 1},
    children => $server->companies,
}};


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


ajax '/delete' => sub {
    my ($o, $error) = object_from(param 'id');
    return $error if not $o;
    return err("Can't delete root.") if ref $o eq 'ARRAY';
    $server->remove($o);
    return {commands => {type => 'delete', id => $o->uuid}};
};


ajax '/restructure' => sub {
    my ($source, $error) = object_from(param 'id');
    return $error if not $source;
    (my $target, $error) = object_from(param 'target');
    return $error if not $target;

    $target->can_adopt($source)
        or return err('Restructure: Incompatible types.');

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

sub field_values {
    my ($o, $fields) = @_;
    my @values;
    for my $f (@$fields) {
        my $method = $f->{name};
        push @values, {%$f, value => $o->$method};
    }
    return \@values;
}

sub get_form {

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
            submit => "/save/edit/$type/" . $o->uuid,
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
            ($parent, $list) = ('root', $server->companies);
        } else {
            my $t = $server->get($id) or return err("$id does not exist."   );
            $t->can_adopt($type)      or return err("$id can't adopt $type.");
            ($parent, $list) = ($t->uuid, $t->children);
        }

        my $node = $forms->{$type}{class}->new($result);
        $server->uuids->{$node->uuid} = $node;
        push @$list, $node;

        return {
            form     => {valid => 1},
            messages => "Added $result->{name}.",
            commands => {
                type   => 'add',
                parent => $parent,
                node   => $node,
            },
        };
    } else {
        my $node = $server->get($id) or return err("$id does not exist.");
        $node->type_name eq $type    or return err("$id is not a $type.");

        while (my ($k, $v) = each %$result) { $node->$k($v) }

        return {
            form     => {valid => 1},
            messages => "Modified $result->{name}",
            commands => {type => 'edit', node => $node},
        };
    }
};


# Exit gracefully on interrupt
$SIG{INT} = sub {
    $server->save;
    exit;
};


dance;
