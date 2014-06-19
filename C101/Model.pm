package C101;

use feature qw(state);
use Moops;

library Types101 extends Types::Standard declares UnsignedNum {
    declare UnsignedNum, as Num, where { $_ >= 0 };
}

class Model {
    use Data::UUID;

    has 'name' => (
        is       => 'rw',
        isa      => 'Str',
        required => 1,
    );

    has 'uuid' => (
        is       => 'rw',
        isa      => 'Str',
        required => 1,
        default  => \&_create_uuid,
    );

    method renew_uuid {
        my $old  = $self->uuid;
        $self->uuid(_create_uuid());
        return $old;
    }

    fun _create_uuid {
        state $ug = new Data::UUID;
        return $ug->create_str();
    }

    method visit(C101::Visitor $visitor, $parent?, $index?) {
        my $vn    = $self->visit_name;
        my $begin = "begin_$vn";
        my $end   = "end_$vn";

        &{$visitor->$begin}($visitor, $self, $parent, $index);

        if ($self->does('C101::Employees')) {
            my $empls = $self->employees;
            for (my $i = 0; $i < @$empls; ++$i) {
                $empls->[$i]->visit($visitor, $empls, \$i);
            }
        }

        if ($self->does('C101::Departments')) {
            my $depts = $self->departments;
            for (my $i = 0; $i < @$depts; ++$i) {
                $depts->[$i]->visit($visitor, $depts, \$i);
            }
        }

        &{$visitor->$end}($visitor, $self, $parent, $index);
    }
}


role Departments {
    has 'departments' => (
        is       => 'rw',
        isa      => 'ArrayRef[C101::Department]',
        required => 1,
        default  => sub { [] },
    );
}

role Employees {
    has 'employees' => (
        is       => 'rw',
        isa      => 'ArrayRef[C101::Employee]',
        required => 1,
        default  => sub { [] },
    );
}


class Company    extends Model with Departments {
    method visit_name { 'company' }
}

class Department extends Model with Departments, Employees {
    method visit_name { 'department' }
}

class Employee   extends Model types Types101 {
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

    method visit_name { 'employee' }
}

__END__

=head2 C101::Model

The object model for 101Companies. Contains classes for Companies, Departments and
Employees, which are all extensions of the Model class.

Each model object has a name and a UUID, the latter of which will be generated
automatically and can be renewed with L<renew_uuid|/method C101::Model::renew_uuid>.

There is also the two roles I<Departments> and I<Employees>, which give a model class
a list of Departments or Employees respectively.

=head3 Classes

=over 4

=item I<Company> extends Model with Departments

=item I<Department> extends Model with Departments, Employees

=item I<Employee> extends Model

=back

=head3 method C101::Model::renew_uuid

Gives the object a newly generated UUID. The old UUID is returned.

=head3 method C101::Model::visit(C101::Visitor $visitor, $parent?, $index?)

Hosts a visit for the given $visitor. This will call the visitor's appropriate I<begin>
callback, then visit all its Employees and then Departments (if the object implements
those respective roles) and finally call the visitor's appropriate I<end> callback.

When visiting Employees or Departments, the list that is being iterated through and a
reference to the iteration index will be passed as $parent and $index respectively. When
calling this method from somewhere else, make sure to pass such a list and index
reference if your visitor needs it.

See also L</C101::Visitor>.

=cut

