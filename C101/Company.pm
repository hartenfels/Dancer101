package C101::Company;
use Moose;
use C101::Department;
use C101::Identifiable;

extends 'C101::Identifiable';

has 'name' => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
);

has 'departments' => (
    is       => 'rw',
    isa      => 'ArrayRef[C101::Department]',
    required => 1,
    default  => sub { [] },
);

sub visit {
    my ($self, $visitor) = @_;
    &{$visitor->begin_company}($visitor, $self);
    C101::Department::visit($_, $visitor) for @{$self->{departments}};
    &{$visitor->end_company}($visitor, $self);
}

1;
__END__

=head2 C101::Company

A class to model a Company. Is a L</C101::Identifiable>.

=head3 Properties

=over 4

=item name (Str, required)

The name for the Company.

=item departments ([C101::Department])

The Company's departments. Defaults to C<[]>.

=back

=head3 visit($self, $visitor)

Hosts a visit for the given L<$visitor|/C101::Visitor>. Will call C<begin_company>,
visit all of $self's L<departments|/C101::Department> and then call C<end_company>.

=cut

