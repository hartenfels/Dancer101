package C101::Operations;
use strict;
use warnings;
use feature 'state';
use Exporter;
use C101::Visitor;

use vars qw(@ISA @EXPORT_OK);
@ISA       = qw(Exporter);
@EXPORT_OK = qw(cut depth median remove remove_uuids total uuids);


sub cut {
    my @cut;
    my $visitor = C101::Visitor->new({
        begin_employee => sub {
            my $e = $_[1];
            if ($e->salary) {
                $e->salary($e->salary / 2);
                push @cut, $e;
            }
        },
    });
    $_->visit($visitor) for @_;
    return wantarray ? @cut : \@cut;
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

sub remove {
    my ($should_remove, $list) = @_;

    my @removed;
    my $callback = sub {
        my (undef, $obj, $list, $index) = @_;
        if ($should_remove->($obj)) {
            push @removed, {obj => $obj, list => $list, index => $$index};
            splice($list, $$index--, 1);
        }
    };

    my $visitor = C101::Visitor->new({
        begin_company    => $callback,
        begin_department => $callback,
        begin_employee   => $callback,
    });

    for (my $i = 0; $i < @$list; ++$i) {
        $list->[$i]->visit($visitor, $list, \$i);
    }
    return wantarray ? @removed : \@removed;
}

sub remove_uuids {
    my $uuids = shift;

    my $callback = sub { delete $uuids->{$_[1]->id} };
    my $visitor = C101::Visitor->new({
        begin_root       => $callback,
        begin_company    => $callback,
        begin_department => $callback,
        begin_employee   => $callback,
    });

    $_->visit($visitor) for @_;
    return undef;
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
    my $uuids = \%C101::Model::uuids;
    my $callback = sub { $_[1]->BUILD };
    my $visitor  = C101::Visitor->new({
        begin_root       => $callback,
        begin_company    => $callback,
        begin_department => $callback,
        begin_employee   => $callback,
    });
    $_->visit($visitor) for @_;
    return @_;
}

1;
__END__

=head2 C101::Operations

Simple feature implementations, like total and cut. Each of the operations
takes a list of zero or more Companies, Departments and Employees (or a mix of
them).

=head3 cut(Company|Department|Employee, ...)

Implements Feature:Cut.

Halves all employees' salaries, salaries of 0 are left alone. Depending on
context a list or list reference of the employees whose salary was cut is
returned.

=head3 depth(Company|Department|Employee, ...)

Implements Feature:Depth.

Returns the maximum depth of the given objects.

=head3 median(Company|Department|Employee, ...)

Implements Feature:Median.

Returns the median salary of all given employees. If there are no employees,
0 will be returned.

=head3 total(Company|Department|Employee, ...)

Implements Feature:Total.

Returns the sum of all given employees' salaries.

=head3 uuids(Company|Department|Employee, ...)

Returns a hash reference mapping from UUIDs to the objects with that UUID. Dies
if one of the UUIDs is not as unique as it ought to be.

=cut

