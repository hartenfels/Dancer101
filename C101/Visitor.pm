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
__END__

=head2 C101::Visitor

Visitor class for traversing the object tree of Companies, Departments and Employees.

The class provides the following six callbacks that are called when the traversal enters
or exits the given type ($self being the visitor itself):

=over 4

=item C<begin_company($self, $company)>

=item C<begin_department($self, $department)>

=item C<begin_employee($self, $employee)>

=item C<end_employee($self, $employee)>

=item C<end_department($self, $department)>

=item C<end_company($self, $company)>

=back

To actually visit something, fill the callbacks you need with appropriate subs and call a
Company's, Department's or Employee's C<visit> function. For example, a visitor to print
the structure of an object tree C<$obj>:

    my $depth   = 0;
    my $visitor = C101::Visitor->new({
        begin_company => sub {
            my ($self, $company) = @_;
            print "\t" x $depth++, "Company: ${\$company->name}\n";
        },
        begin_department => sub {
            my ($self, $department) = @_;
            print "\t" x $depth++, "Department: ${\$department->name}\n";
        },
        begin_employee => sub {
            my ($self, $employee) = @_;
            print "\t" x $depth++, "Employee: ${\$employee->name}\n";
        },
        end_employee => sub {
            my ($self, $employee) = @_;
            print "\t" x $depth,   "Address: ${\$employee->salary}\n";
            print "\t" x $depth--,  "Salary: ${\$employee->salary}\n";
        },
        end_department => sub {
            --$depth;
        },
        end_company => sub {
            --$depth;
        },
    });
    $obj->visit($visitor);

=cut

