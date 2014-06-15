#!/usr/bin/perl
use strict;
use warnings;
use feature           qw(state switch);
use Dancer;
use File::Slurp;
use List::Util        qw(first);
use Scalar::Util      qw(looks_like_number);
use Template;
use C101::Sample;
use C101::Persistence qw(serialize unserialize);
use C101::Operations  qw(remove uuids);

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
    my ($list, $obj) = @_;
    my $entries = [];
    for my $pair (@$list) {
        my $key = $pair->[0];
        push($entries => {
            name  => $key,
            label => ucfirst($key),
            value => defined($_ = param($key)) ? $_ : $obj && $obj->$key,
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
    for my $pair (@$list) {
        my ($key, $type) = @$pair;
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
            default { die "Don't know how to validate $type" }
        }
    }
    return $result;
}

sub handle_add($) {
    my $args   = shift;
    my $type   = $args->{type};
    my $uuid   = param('uuid');
    my $list   = $args->{list};
    my $parent = $uuid ? $uuids->{$uuid} : undef;

    if ($list && !$parent) {
        set_message("The UUID $uuid does not correspond to anything. "
                  . 'Either you accessed a broken link or the object was modified.');
        return redirect '/';
    }

    if (request->method eq 'POST') {
        my $valid = validate($args->{validate});
        if (defined $valid) {
            my $obj = eval { "C101::$type"->new($valid) };
            if ($@) {
                $@ =~ /^([^\n]*)/;
                set_message("Error: $1");
            } else {
                push(($list ? $parent->$list : $companies), $obj);
                $uuids->{$obj->uuid} = $obj;
                return redirect '/';
            }
        }
    }

    template 'form.tt' => {
        title => $list ? "Add $type to ${\$parent->name}" : "Create $type",
        messages,
        entries($args->{validate}),
    };
}

sub handle_edit($) {
    my $args = shift;
    my $type = $args->{type};
    my $uuid = param('uuid');
    my $obj  = $uuid ? $uuids->{$uuid} : undef;

    if (!$obj || !$obj->isa("C101::$type")) {
        set_message("The UUID $uuid does not correspond to any $type. "
                  . 'Either you accessed a broken link or the object was modified.');
        return redirect '/';
    }

    if (request->method eq 'POST') {
        my $valid = validate($args->{validate});
        if (defined $valid) {
            my $old = {};
            eval {
                while (my ($k, $v) = each($valid)) {
                    $old->{$k} = $obj->$k;
                    $obj->$k($v);
                }
            };
            if ($@) {
                $@ =~ /^([^\n]*)/;
                set_message("Error: $1");
                # attempt to restore old values
                while (my ($k, $v)) {
                    eval { $obj->$k($old->{$k}) if $old->{$k} };
                }
            } else {
                delete $uuids->{$obj->renew_uuid};
                $uuids->{$obj->uuid} = $obj;
                return redirect '/';
            }
        }
    }

    template 'form.tt' => {
        title => sprintf($args->{title}, $obj->name),
        messages,
        entries($args->{validate}, $obj),
    };
}


get '/' => sub {
    template 'index.tt' => {
        title     => 'Contribution:Dancer',
        companies => $companies,
        messages,
    };
};

any ['get', 'post'] => '/add' => sub {
    return handle_add {
        type     => 'Company',
        validate => [[name => 'Str']],
    };
};

any ['get', 'post'] => '/edit/company/:uuid' => sub {
    return handle_edit {
        title    => 'Edit Company %s',
        type     => 'Company',
        validate => [[name => 'Str']],
    };
};

any ['get', 'post'] => '/add/department/:uuid' => sub {
    return handle_add {
        type     => 'Department',
        list     => 'departments',
        validate => [[name => 'Str']],
    };
};

any ['get', 'post'] => '/edit/department/:uuid' => sub {
    return handle_edit {
        title    => 'Edit Department %s',
        type     => 'Department',
        validate => [[name => 'Str']],
    };
};

any ['get', 'post'] => '/add/employee/:uuid' => sub {
    return handle_add {
        type     => 'Employee',
        list     => 'employees',
        validate => [[name => 'Str'], [address => 'Str'], [salary => 'UnsignedNum']],
    };
};

any ['get', 'post'] => '/edit/employee/:uuid' => sub {
    return handle_edit {
        title    => 'Edit Employee %s',
        type     => 'Employee',
        validate => [[name => 'Str'], [address => 'Str'], [salary => 'UnsignedNum']],
    };
};

any ['get', 'post'] => '/edit/address/:uuid' => sub {
    return handle_edit {
        title    => 'Edit Address of Employee %s',
        type     => 'Employee',
        validate => [[address => 'Str']],
    };
};

any ['get', 'post'] => '/edit/salary/:uuid' => sub {
    return handle_edit {
        title    => 'Edit Salary of Employee %s',
        type     => 'Employee',
        validate => [[salary => 'UnsignedNum']],
    };
};

any ['get', 'post'] => '/delete/:uuid' => sub {
    my $uuid = param('uuid');
    my $obj  = $uuid ? $uuids->{$uuid} : undef;

    if (!$obj) {
        set_message("The UUID $uuid does not correspond to anything. "
                  . 'Either you accessed a broken link or the object was modified.');
        return redirect '/';
    }

    if (request->method eq 'POST') {
        $obj->visit(C101::Visitor->new({
            begin_company    => sub { delete $uuids->{$_[1]->uuid} },
            begin_department => sub { delete $uuids->{$_[1]->uuid} },
            begin_employee   => sub { delete $uuids->{$_[1]->uuid} },
        }));
        remove(sub { $_[0] == $obj }, $companies);
        return redirect '/';
    }

    template 'delete.tt' => {
        title  => "Deletion of ${\$obj->name}",
        object => $obj,
        messages,
    };
};

$SIG{INT} = sub {
    serialize($companies, 'companies.bin');
    exit;
};

dance;

