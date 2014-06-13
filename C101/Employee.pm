package C101::Employee;
use Moose;
use C101::Company;
use C101::Department;
use C101::Identifiable;

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
    isa      => 'Num',
    required => 1,
);

sub visit {
    my ($self, $visitor) = @_;
    &{$visitor->begin_employee}($visitor, $self);
    &{$visitor->end_employee}($visitor, $self);
}

1;

