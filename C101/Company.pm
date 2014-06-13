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
    for my $d (@{$self->{departments}}) {
        C101::Department::visit($d, $visitor);
    }
    &{$visitor->end_company}($visitor, $self);
}

1;

