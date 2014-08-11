package C101::Sample;
use strict;
use warnings;
use C101::Model;

use vars qw(@ISA @EXPORT_OK);
@ISA       = qw(Exporter);
@EXPORT_OK = qw(create);

sub create {
    C101::Company->new({
        name     => 'ACME Corporation',
        children => [
            C101::Department->new({
                name     => 'Research',
                children => [
                    C101::Employee->new({
                        name    => 'Craig',
                        address => 'Redmond',
                        salary  => 123456,
                    }),
                    C101::Employee->new({
                        name    => 'Erik',
                        address => 'Utrecht',
                        salary  => 12345,
                    }),
                    C101::Employee->new({
                        name    => 'Ralf',
                        address => 'Koblenz',
                        salary  => 1234,
                    }),
                ],
            }),
            C101::Department->new({
                name     => 'Development',
                children => [
                    C101::Employee->new({
                        name    => 'Ray',
                        address => 'Redmond',
                        salary  => 234567,
                    }),
                    C101::Department->new({
                        name     => 'Dev1',
                        children => [
                            C101::Employee->new({
                                name    => 'Klaus',
                                address => 'Boston',
                                salary  => 23456,
                            }),
                            C101::Department->new({
                                name     => 'Dev1.1',
                                children => [
                                    C101::Employee->new({
                                        name    => 'Karl',
                                        address => 'Riga',
                                        salary  => 2345,
                                    }),
                                    C101::Employee->new({
                                        name    => 'Joe',
                                        address => 'Wifi City',
                                        salary  => 2344,
                                    }),
                                ],
                            })
                        ],
                    }),
                ],
            }),
        ],
    });
}

1;
__END__

=head2 C101::Sample

=head3 create()

Returns the sample Company. It will always be the same company, only the
UUIDs will differ.

=cut

