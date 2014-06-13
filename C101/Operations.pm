package C101::Operations;
use strict;
use warnings;
use feature 'state';
use Exporter;
use Data::UUID;
use C101::Visitor;

use vars qw(@ISA @EXPORT_OK);
@ISA       = ('Exporter');
@EXPORT_OK = qw(cut depth median total uuids);


sub cut {
    my $visitor = C101::Visitor->new({
        begin_employee => sub {
            my $e = $_[1];
            $e->salary($e->salary / 2) if $e->salary;
        },
    });
    $_->visit($visitor) for @_;
}

sub depth {
    my $max   = 0;
    my $depth = 0;
    my $visitor = C101::Visitor->new({
        begin_department => sub {
            $max = $depth if ++$depth > $max;
        },
        end_department   => sub {
            --$depth;
        },
    });
    $_->visit($visitor) for @_;
    return $max;
}

sub median {
    my $total   = 0;
    my $count   = 0;
    my $visitor = C101::Visitor->new({
        begin_employee => sub {
            $total += $_[1]->salary;
            ++$count;
        },
    });
    $_->visit($visitor) for @_;
    return $count ? $total / $count : 0;
}

sub total {
    my $total   = 0;
    my $visitor = C101::Visitor->new({
        begin_employee => sub {
            $total += $_[1]->salary;
        },
    });
    $_->visit($visitor) for @_;
    return $total;
}

sub uuids {
    my $uuids    = {};
    my $callback = sub {
        my $u = $_[1]->uuid;
        die "$u is not unique" if $uuids->{$u};
        $uuids->{$u} = $_[1];
    };
    my $visitor  = C101::Visitor->new({
        begin_company    => $callback,
        begin_department => $callback,
        begin_employee   => $callback,
    });
    $_->visit($visitor) for @_;
    return $uuids;
}

1;
__END__

=head1 C101::Operations

Simple feature implementations, like total and cut. Each of the operations takes a list
of zero or more Companies, Departments and Employees (or a mix of them).

=head2 C<cut(Company|Department|Employee, ...)>

Implements Feature:Cut. Halves all employees' salaries, salaries of 0 are left alone.
Nothing is returned.

=head2 C<depth(Company|Department|Employee, ...)>

Implements Feature:Depth. Returns the maximum depth of the given objects.

=head2 C<median(Company|Department|Employee, ...)>

Implements Feature:Median. Returns the median salary of all given employees. If there are
no employees, 0 will be returned.

=head2 C<total(Company|Department|Employee, ...)>

Implements Feature:Total. Returns the sum of all given employees' salaries.

=head2 C<uuids(Company|Department|Employee, ...)>

Returns a reference to a hash mapping from UUIDs to their respective Company, Department
or Employee. Dies if one of the UUIDs is not actually unique.

=cut

