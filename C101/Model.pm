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
        is       => 'ro',
        isa      => 'Str',
        required => 1,
        default  => \&_create_uuid,
    );

    method renew_uuid {
        my $old  = $self->uuid;
        $self->{uuid} = _create_uuid();
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

