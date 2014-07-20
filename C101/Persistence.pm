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

=head3 serialize($thing, $filename)/unserialize($filename)

Implements Feature:Serialization. Serializes the given thing to the given file and
unserializes a thing from the given file. The thing must be some kind of scalar.

=head3 parse($yaml)/unparse(@stuff)

Implements Feature:Parsing and Feature:Unparsing.
Parses/unparses the given YAML string/Perl stuff into Perl stuff/YAML.

=cut

