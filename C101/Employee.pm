package C101::Employee;
use Moose;
use Moose::Util::TypeConstraints;
use C101::Company;
use C101::Department;
use C101::Identifiable;

subtype 'UnsignedNum'
     => as      'Num'
     => where   { $_ >= 0 }
     => message { "$_ cannot be negative" };


extends 'C101::Identifiable';

has 'name' => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
);

has 'address' => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
);

has 'salary' => (
    is       => 'rw',
    isa      => 'UnsignedNum',
    required => 1,
);

sub visit {
    my ($self, $visitor, $parent, $index) = @_;
    &{$visitor->begin_employee}($visitor, $self, $parent, $index);
    &{$visitor->end_employee}  ($visitor, $self, $parent, $index);
}

1;
__END__

=head2 C101::Company

A class to model an Employee. Is a L</C101::Identifiable>.

=head3 Properties

=over 4

=item name (Str, required)

The Employee's name.

=item address (Str, required)

The Employee's address.

=item salary (UnsignedNum, required)

The Employee's salary. Cannot be negative.

=back

=head3 visit($self, $visitor)

Hosts a visit for the given L<$visitor|/C101::Visitor>. Will call C<begin_employee> and
then immediately call C<end_employee>.

=cut

