package C101::Operations;
use strict;
use warnings;
use Exporter;
use C101::Visitor;

use vars qw(@ISA @EXPORT_OK);
@ISA       = ('Exporter');
@EXPORT_OK = qw(cut depth median total serialize unserialize);

sub cut {
    my $visitor = C101::Visitor->new({
        begin_employee => sub {
            my $e = $_[1];
            $e->salary($e->salary / 2);
        },
    });
    shift->visit($visitor);
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
    shift->visit($visitor);
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
    shift->visit($visitor);
    return $count ? $total / $count : 0;
}

sub total {
    my $total   = 0;
    my $visitor = C101::Visitor->new({
        begin_employee => sub {
            $total += $_[1]->salary;
        },
    });
    shift->visit($visitor);
    return $total;
}

1;

