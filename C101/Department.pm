package C101::Department;
use Moose;
use C101::Company;
use C101::Employee;

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
    for my $e (@{$self->employees}) {
        $e->visit($visitor);
    }
    for my $d (@{$self->departments}) {
        $d->visit($visitor);
    }
    &{$visitor->end_department}($visitor, $self);
}

1;

