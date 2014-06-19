package C101;
use Moops;

class Visitor {
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
}

__END__

=head2 C101::Visitor

Visitor class for traversing the object tree of Companies, Departments and Employees.

The class provides the following six callbacks that are called when the traversal enters
or exits the given type ($self being the visitor itself):

=over 4

=item C<begin_company($self, $company, $parent?, $index?)>

=item C<begin_department($self, $department, $parent?, $index?)>

=item C<begin_employee($self, $employee, $parent?, $index?)>

=item C<end_employee($self, $employee, $parent?, $index?)>

=item C<end_department($self, $department, $parent?, $index?)>

=item C<end_company($self, $company, $parent?, $index?)>

=back

=head3 Regular Visits

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

=head3 Advanced Visits

More complicated structural operations like additions or deletions are still possible
with visitors, but they require a bit more reflection. So in the callbacks, $parent is a
reference to the list that is currently being iterated through and of which the current
element is a part of and $index is a reference to the iteration index. At top level, you
may not be iterating through a list at all (e.g. because you're only visiting a single
company), which is why those parameters are optional.

You need to make sure that when modifying the parent list, you probably also need to
modify the iteration $index. For example, when you want to fire every employee with a
salary over 9999.99 as part of a 99% ralley, you need to decrement the index every time
that happens. Otherwise the index would be incremented normally on the next iteration and
you'd potentially skip over a part of the 1%.

    my $visitor = C101::Visitor->new({
        begin_employee => sub {
            my ($self, $employee, $parent, $index) = @_;
            delete $parent->[$$index--] if $employee->salary > 9999.99;
        },
    });
    $obj->visit($visitor);

=cut

