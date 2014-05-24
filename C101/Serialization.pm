package C101::Serialization;
use strict;
use warnings;
use Exporter;
use Storable;

use vars qw(@ISA @EXPORT_OK);
@ISA       = ('Exporter');
@EXPORT_OK = ('serialize', 'unserialize');

sub serialize {
    Storable::store(@_);
}

sub unserialize {
    Storable::retrieve(@_);
}

1;

