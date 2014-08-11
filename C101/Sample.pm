package C101::Sample;
use strict;
use warnings;
use C101::Model;

use vars qw(@ISA @EXPORT_OK);
@ISA       = qw(Exporter);
@EXPORT_OK = qw(create);

sub create {
    C101::Model->new(
        text     => 'Companies',
        children => [
            C101::Company->new(
                text     => 'ACME Corporation',
                children => [
                    C101::Department->new(
                        text     => 'Research',
                        children => [
                            C101::Employee->new(
                                text    => 'Craig',
                                address => 'Redmond',
                                salary  => 123456,
                            ),
                            C101::Employee->new(
                                text    => 'Erik',
                                address => 'Utrecht',
                                salary  => 12345,
                            ),
                            C101::Employee->new(
                                text    => 'Ralf',
                                address => 'Koblenz',
                                salary  => 1234,
                            ),
                        ],
                    ),
                    C101::Department->new(
                        text     => 'Development',
                        children => [
                            C101::Employee->new(
                                text    => 'Ray',
                                address => 'Redmond',
                                salary  => 234567,
                            ),
                            C101::Department->new(
                                text     => 'Dev1',
                                children => [
                                    C101::Employee->new(
                                        text    => 'Klaus',
                                        address => 'Boston',
                                        salary  => 23456,
                                    ),
                                    C101::Department->new(
                                        text     => 'Dev1.1',
                                        children => [
                                            C101::Employee->new(
                                                text    => 'Karl',
                                                address => 'Riga',
                                                salary  => 2345,
                                            ),
                                            C101::Employee->new(
                                                text    => 'Joe',
                                                address => 'Wifi City',
                                                salary  => 2344,
                                            ),
                                        ],
                                    )
                                ],
                            ),
                        ],
                    ),
                ],
            )
        ]
    );
}
1;
__END__

=head2 C101::Sample

=head3 create()

Returns the sample model. It'll always be the same, only the UUIDs will differ.

=cut

