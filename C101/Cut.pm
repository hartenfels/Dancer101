package C101::Cut;
use strict;
use warnings;
use Exporter;
use C101::Visitor;

use vars qw(@ISA @EXPORT_OK);
@ISA       = ('Exporter');
@EXPORT_OK = ('cut');

sub cut {
    my $visitor = C101::Visitor->new({
        begin_employee => sub {
            my $e = $_[1];
            $e->salary($e->salary / 2);
        },
    });
    shift->visit($visitor);
}

1;

