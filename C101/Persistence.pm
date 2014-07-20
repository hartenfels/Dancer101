package C101::Persistence;
use strict;
use warnings;
use Exporter;
use Storable qw(store retrieve);
use YAML;

use vars qw(@ISA @EXPORT_OK);
@ISA       = ('Exporter');
@EXPORT_OK = qw(serialize unserialize parse unparse);

sub serialize   {      store(@_) }
sub unserialize {   retrieve(@_) }
sub parse       { YAML::Load(@_) }
sub unparse     { YAML::Dump(@_) }

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

