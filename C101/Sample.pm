package C101::Sample;
use strict;
use warnings;
use C101::Company;
use C101::Department;
use C101::Employee;

sub create {
    C101::Company->new({
        name        => 'ACME Corporation',
        departments => [
            C101::Department->new({
                name      => 'Research',
                employees => [
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
                name      => 'Development',
                employees => [
                    C101::Employee->new({
                        name    => 'Ray',
                        address => 'Redmond',
                        salary  => 234567,
                    }),
                ],
                departments => [
                    C101::Department->new({
                        name      => 'Dev1',
                        employees => [
                            C101::Employee->new({
                                name    => 'Klaus',
                                address => 'Boston',
                                salary  => 23456,
                            }),
                        ],
                        departments => [
                            C101::Department->new({
                                name      => 'Dev1.1',
                                employees => [
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

Calling C<sample()> will return a newly created sample Company. It's always the same
company, only the UUIDs will differ.

=cut

