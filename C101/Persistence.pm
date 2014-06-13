package C101::Persistence;
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
@EXPORT_OK = qw(serialize unserialize parse unparse);

sub serialize {
    Storable::store(@_);
}

sub unserialize {
    Storable::retrieve(@_);
}

sub parse {
    my $json    = shift;
    my $hash    = JSON::XS->new->utf8->decode($json);

    # Moose doesn't construct its objects in-place like bless does, it creates
    # a new reference. That's not what is wanted here though, since it would
    # mean that the entire tree has to be rebuilt too. Instead, the visitor just
    # checks if each object constructs fine with Moose, takes the UUID from that
    # constructed object (which was either parsed from the JSON file or newly generated
    # by the constructor) and then blesses the object on its own.
    my $visitor = C101::Visitor->new({
        'end_employee'   => sub {
            $_[1]->{uuid} = C101::Employee->new($_[1])->uuid;
            bless $_[1] => 'C101::Employee';
        },

        'end_department'   => sub {
            $_[1]->{uuid} = C101::Department->new($_[1])->uuid;
            bless $_[1] => 'C101::Department';
        },

        'end_company'      => sub {
            $_[1]->{uuid} = C101::Company->new($_[1])->uuid;
            bless $_[1] => 'C101::Company';
        },
    });

    # Automatic type detection works fine unless one omits empty lists in the JSON.
    # In that case, the distinction between a company and a department may get lost.
    my $type = shift || '';
    if (     $type eq 'employee'   || _has_keys($hash, qw(name address salary))) {
        C101::Employee::visit($hash, $visitor);
    } elsif ($type eq 'department' || _has_keys($hash, qw(name departments employees))) {
        C101::Department::visit($hash, $visitor);
    } elsif ($type eq 'company'    || _has_keys($hash, qw(name departments))) {
        C101::Company::visit($hash, $visitor);
    } else {
        die "Could not figure out type to unparse: $type $json";
    }

    return $hash;
}

sub unparse {
    my $object = shift;
    my $plain  = Data::Structure::Util::unbless(Storable::dclone($object));
    return JSON::XS->new->utf8->canonical->indent->space_after->encode($plain);
}

# private
sub _has_keys {
    my $hash = shift;
    for (@_) { return 0 unless exists($hash->{$_}) }
    return 1;
}

1;
__END__

=head1 C101::Persistence

Contains serialization and parsing features.

=head2 C<serialize($thing, $filename)>/C<unserialize($filename)>

Implements Feature:Serialization. Serializes the given thing to the given file and
unserializes a thing from the given file. The thing must be some kind of scalar.

=head2 C<parse($json, [$type])>/C<unparse(Company|Department|Employee)>

Implements Feature:Parsing and Feature:Unparsing.
Parses the given JSON string into a Company, Department or Employee object and unparses
such an object into a JSON string. For parsing, the type of the parsed object can be
given (C<'company'>, C<'department'> or C<'employee'>), otherwise it will be guessed.

=cut

