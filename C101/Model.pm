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

    has 'children' => (
        is       => 'rw',
        isa      => 'ArrayRef[C101::Model]',
        required => 1,
        default  => sub { [] },
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
        my $type  = $self->type_name;
        my $begin = "begin_$type";
        my $end   = "end_$type";

        &{$visitor->$begin}($visitor, $self, $parent, $index);

        my $children = $self->children;
        for (my $i = 0; $i < @$children; ++$i) {
            $children->[$i]->visit($visitor, $children, \$i);
        }

        &{$visitor->$end}($visitor, $self, $parent, $index);
    }

    method can_adopt($t) {
        $t = $t->type_name if ref $t;
        if      ($t eq 'department') {
            return $self->does('C101::Departments');
        } elsif ($t eq 'employee'  ) {
            return $self->does('C101::Employees'  );
        }
        return 0;
    }

    method TO_JSON {{
        type     => $self->type_name,
        id       => $self->uuid,
        text     => $self->name,
        children => $self->children,
    }}
}


role Departments {}

role Employees   {}


class Company    extends Model with Departments {
    method type_name { 'company' }
}

class Department extends Model with Departments, Employees {
    method type_name { 'department' }
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

    method type_name { 'employee' }

    method TO_JSON {{
        type    => $self->type_name,
        id      => $self->uuid,
        text    => $self->name,
        address => $self->address,
        salary  => $self->salary,
    }}
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

