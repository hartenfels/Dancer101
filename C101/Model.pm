package C101;
use feature qw(state);
use Moops;

library Types101 extends Types::Standard declares UnsignedNum {
    declare UnsignedNum, as Num, where { $_ >= 0 };
}


class Model {
    use Data::UUID;
    use C101::Operations qw(remove_uuids);

    our %uuids;

    fun create_uuid {
        state $ug = new Data::UUID;
        return $ug->create_str();
    }

    has 'text' => (
        is       => 'rw',
        isa      => 'Str',
        required => 1,
    );

    has 'id' => (
        is       => 'rw',
        isa      => 'Str',
        required => 1,
        default  => \&create_uuid,
    );

    has 'children' => (
        is       => 'rw',
        isa      => 'ArrayRef[C101::Model]',
        required => 1,
        default  => sub { [] },
    );

    method BUILD   { $uuids{$self->id} = $self    }
    method DESTROY { remove_uuids(\%uuids, $self) }

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

    method TO_JSON {{type => $self->type_name, state => {opened => 1}, %$self}}

    method type_name   { 'root'         }
    method child_types { {company => 1} }
}


class Company    extends Model {
    method type_name   { 'company'         }
    method child_types { {department => 1} }
}


class Department extends Model {
    method type_name   { 'department'                     }
    method child_types { {department => 1, employee => 1} }
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

    method type_name   { 'employee' }
    method child_types { {}         }
}

__END__

=head2 C101::Model

The object model for 101Companies. Contains classes for Companies, Departments
and Employees, which are all extensions of the Model class.

Each model object has a text and a UUID, the latter of which will be generated
automatically.

=head3 Classes

=over

=item I<Company> extends Model

=item I<Department> extends Model

=item I<Employee> extends Model

=back

=cut

