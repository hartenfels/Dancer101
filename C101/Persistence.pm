package C101::Persistence;
use strict;
use warnings;
use Data::Structure::Util qw(unbless);
use Exporter;
use JSON::XS;
use Storable              qw(store retrieve dclone);

use vars qw(@ISA @EXPORT_OK);
@ISA       = ('Exporter');
@EXPORT_OK = qw(serialize unserialize plainify unparse);

sub serialize   {    store(@_) }

sub unserialize { retrieve(@_) }

sub plainify {
    my $list = [];
    push($list, unbless(dclone($_))) for @_;
    return $list;
}

sub unparse {
    JSON::XS->new->utf8->canonical->indent->space_after->encode(plainify(@_));
}

# private
sub _has_keys {
    my $hash = shift;
    for (@_) { return 0 unless exists($hash->{$_}) }
    return 1;
}

1;
__END__

=head2 C101::Persistence

Contains serialization and parsing features.

=head3 serialize($thing, $filename)>/unserialize($filename)

Implements Feature:Serialization. Serializes the given thing to the given file and
unserializes a thing from the given file. The thing must be some kind of scalar.

=head3 parse($json, [$type])>/unparse(Company|Department|Employee)

Implements Feature:Parsing and Feature:Unparsing.
Parses the given JSON string into a Company, Department or Employee object and unparses
such an object into a JSON string. For parsing, the type of the parsed object can be
given (C<'company'>, C<'department'> or C<'employee'>), otherwise it will be guessed.

=cut

