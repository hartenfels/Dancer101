package C101::Unparsing;
use strict;
use warnings;
use Data::Structure::Util;
use Exporter;
use JSON::XS;
use Storable;

use vars qw(@ISA @EXPORT_OK);
@ISA       = ('Exporter');
@EXPORT_OK = ('unparse');

sub unparse {
    my $object = shift;
    my $plain  = Data::Structure::Util::unbless(Storable::dclone($object));
    return JSON::XS->new->utf8->canonical->indent->space_after->encode($plain);
}

1;

