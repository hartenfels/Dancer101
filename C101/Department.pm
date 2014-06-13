package C101::Department;
use Moose;
use C101::Company;
use C101::Employee;
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

has 'employees' => (
    is       => 'rw',
    isa      => 'ArrayRef[C101::Employee]',
    required => 1,
    default  => sub { [] },
);

sub visit {
    my ($self, $visitor) = @_;
    &{$visitor->begin_department}($visitor, $self);
    C101::Employee::visit  ($_, $visitor) for @{$self->{employees  }};
    C101::Department::visit($_, $visitor) for @{$self->{departments}};
    &{$visitor->end_department}($visitor, $self);
}

1;
__END__

=head2 C101::Department

A class to model a Department. Is a L</C101::Identifiable>.

=head3 Properties

=over 4

=item name (Str, required)

The name for the Department.

=item departments ([C101::Department])

The Department's subdepartments. Defaults to C<[]>.

=item employees ([C101::Employee])

The Department's employees. Defaults to C<[]>.

=back

=head3 visit($self, $visitor)

Hosts a visit for the given L<$visitor|/C101::Visitor>. Will call C<begin_department>,
visit all of $self's L<employees|/C101::Employee>, L<departments|/C101::Department> and
then call C<end_department>.

=cut

