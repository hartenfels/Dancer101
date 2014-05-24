package C101::Visitor;
use Moose;
use C101::Company;
use C101::Department;
use C101::Employee;

my %params = (
    is       => 'rw',
    isa      => 'CodeRef',
    required => 1,
    default  => sub { sub {} },
);

has 'begin_company'    => %params;
has 'begin_department' => %params;
has 'begin_employee'   => %params;
has 'end_employee'     => %params;
has 'end_department'   => %params;
has 'end_company'      => %params;

1;

