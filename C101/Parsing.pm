package C101::Parsing;
use strict;
use warnings;
use Data::Structure::Util;
use Exporter;
use JSON::XS;
use Storable;
use C101::Company;
use C101::Department;
use C101::Employee;
use C101::Visitor;

use vars qw(@ISA @EXPORT_OK);
@ISA       = ('Exporter');
@EXPORT_OK = ('parse');

sub has_keys {
    my $hash = shift;
    for (@_) { return 0 unless exists($hash->{$_}) }
    return 1;
}

sub parse {
    my $json    = shift;
    my $hash    = JSON::XS->new->utf8->decode($json);

    # Moose doesn't construct its objects in-place like bless does, it creates
    # a new reference. That's not what is wanted here though, since it would
    # mean that the entire tree has to be rebuilt too. Instead, the visitor just
    # checks if each object constructs fine with Moose, then tosses the result
    # and uses bless on its own.
    my $visitor = C101::Visitor->new({
        'end_employee'   => sub {
            C101::Employee->new($_[1]);
            bless $_[1] => 'C101::Employee';
        },

        'end_department'   => sub {
            C101::Department->new($_[1]);
            bless $_[1] => 'C101::Department';
        },

        'end_company'      => sub {
            C101::Company->new($_[1]);
            bless $_[1] => 'C101::Company';
        },
    });

    # Automatic type detection works fine unless one omits empty lists in the JSON.
    # In that case, the distinction between a company and a department may get lost.
    my $type = shift || '';
    if (     $type eq 'employee'   || has_keys($hash, qw(name address salary))) {
        C101::Employee::visit($hash, $visitor);
    } elsif ($type eq 'department' || has_keys($hash, qw(name departments employees))) {
        C101::Department::visit($hash, $visitor);
    } elsif ($type eq 'company'    || has_keys($hash, qw(name departments))) {
        C101::Company::visit($hash, $visitor);
    } else {
        die "Could not figure out type to unparse: $type $json";
    }

    return $hash;
}

1;

