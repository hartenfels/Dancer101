#!/usr/bin/perl
use strict;
use warnings;
use feature qw(state switch);
use Dancer;
use Data::Dumper;
use File::Slurp;
use Scalar::Util      qw(looks_like_number);
use Template;
use C101::Sample;
use C101::Persistence qw(serialize unserialize);
use C101::Operations  qw(uuids);

set( 
    session      => 'Simple',
    template     => 'template_toolkit',
    layout       => 'main',
    logger       => 'console',
    log          => 'debug',
    show_errors  => 1,
    startup_info => 1,
    warnings     => 1,
    companies    => 'companies.bin',
);


my $companies = -e setting('companies')
              ? unserialize(setting('companies'))
              : [ C101::Sample::create ];
my $uuids     = uuids(@$companies);


sub entries {
    my $list    = shift;
    my $entries = [];
    for (my $i = 0; $i < scalar @$list; $i += 2) {
        $_ = $list->[$i];
        push($entries => {
            name  => $_,
            label => ucfirst,
            value => param($_),
        });
    }
    return entries => $entries;
}

sub set_message {
    session(messages => []) unless session('messages');
    push(session('messages'), $_) for @_;
}

sub messages {
    my $messages = session('messages');
    session(messages => []);
    return messages => $messages;
}

sub validate {
    my $list   = shift;
    my $result = {};
    for (my $i = 0; $i < scalar @$list; $i += 2) {
        my $key   = $list->[$i];
        my $type  = $list->[$i + 1];
        my $value = param($key);
        given ($type) {
            when ('Str') {
                if ($value =~ /^\s*(.+?)\s*$/) {
                    $result->{$key} = $value if defined $result;
                } else {
                    set_message("Please enter a non-empty $key.");
                    $result = undef;
                }
            }
            when ('UnsignedNum') {
                if (looks_like_number($value) && $value >= 0) {
                    $result->{$key} = $value + 0 if defined $result;
                } else {
                    set_message("Please enter a non-negative number for $key.");
                    $result = undef;
                }
            }
            default { die "Don't know how to validate $key => $type" }
        }
    }
    return $result;
}

sub handle_form($) {
    my $args = shift;

    my $uuid   = param('uuid');
    my $parent = $uuid ? $uuids->{$uuid} : undef;
    my $parkey = $args->{parent};
    if ($parkey && !$parent) {
        set_message("The UUID $uuid does not correspond to anything. "
                  . 'Either you accessed a broken link or the object was modified.');
        return redirect '/';
    }

    my $type = $args->{type};
    my $edit = $args->{edit};
    if (request->method eq 'POST') {
        my $valid = validate($args->{validate});
        if (defined $valid) {
            if ($edit) {
                # TODO
            } else {
                my $obj = eval { "C101::$type"->new($valid) };
                if ($@) {
                    $@ =~ /^([^\n]*)/;
                    set_message("Error: $1");
                } else {
                    push(($parkey ? $parent->$parkey : $companies), $obj);
                    
                    delete($uuids->{$obj->renew_uuid()}) if $edit;
                    $uuids->{$obj->uuid} = $obj;

                    return redirect '/';
                }
            }
        }
    }

    my $title;
    if ($edit) {
        $title = "Edit $type";
    } else {
        $title = $parkey ? "Add $type to ${\$parent->name}" : "Create $type";
    }

    template 'form.tt' => {
        title => $title,
        messages(),
        entries($args->{validate}),
    };
}


get '/' => sub {
    template 'index.tt' => {
        title     => 'Contribution:Dancer',
        companies => $companies,
        messages(),
    };
};

any ['get', 'post'] => '/add' => sub {
    return handle_form{
        type     => 'Company',
        edit     => 0,
        validate => [name => 'Str'],
    };
};

any ['get', 'post'] => '/add/department/:uuid' => sub {
    return handle_form{
        type     => 'Department',
        parent   => 'departments',
        edit     => 0,
        validate => [name => 'Str'],
    };
};

any ['get', 'post'] => '/add/employee/:uuid' => sub {
    return handle_form{
        type     => 'Employee',
        parent   => 'employees',
        edit     => 0,
        validate => [name => 'Str', address => 'Str', salary => 'UnsignedNum'],
    };
};

$SIG{INT} = sub {
    serialize($companies, 'companies.bin');
    exit;
};

dance;

