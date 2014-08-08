package C101;
use Moops;

class Server {
    use Dancer;
    use File::Slurp           qw(slurp write_file);
    use C101::Operations      qw(remove uuids);
    use C101::Persistence     qw(parse unparse);
    use C101::Sample;

    has 'companies' => (
        is       => 'ro',
        isa      => 'ArrayRef[C101::Company]',
        required => 1,
        default  => sub {
            my $path = setting('company_file');
            -e $path ? parse(scalar slurp($path)) : [C101::Sample::create];
        },
    );

    has 'uuids' => (
        is       => 'rw',
        isa      => 'HashRef[C101::Model]',
    );

    method BUILD {
        $self->uuids(uuids(@{$self->companies}));
    }

    method get(Str $id) {
        $id eq 'root' ? $self->companies : $self->uuids->{$id};
    }

    method save() {
        write_file setting('company_file'), unparse($self->companies);
    }

    method remove(C101::Model $obj) {
        delete $self->uuids->{$obj->uuid};
        remove(sub { $_[0] == $obj }, $self->companies);
    }

}

__END__

=head2 C101::Server

A class for a bunch of helper operations for the Web UI feature. No parameters are
needed for construction.

Has a companies array reference that is deserialized from the file I<companies.bin> upon
construction. There is also a hash of UUIDs mapping to their respective objects, but
that's private.

=head3 method save()

Serializes the companies into the file I<companies.bin>. Returns nothing interesting.

=cut

