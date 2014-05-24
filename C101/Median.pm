package C101::Median;
use strict;
use warnings;
use Exporter;
use C101::Visitor;

use vars qw(@ISA @EXPORT_OK);
@ISA       = ('Exporter');
@EXPORT_OK = ('median');

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

1;

