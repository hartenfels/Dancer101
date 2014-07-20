#!/usr/bin/perl
use strict;
use warnings;
use Storable;
use File::Slurp       qw(slurp);
use Test::More        tests => 8;
use C101::Sample;
use C101::Operations  qw(cut depth median total uuids);
use C101::Persistence qw(serialize unserialize parse unparse);

my $c1 = C101::Sample::create;
eval { uuids($c1) };
ok(!$@, 'uuids');

my $c2 = Storable::dclone($c1);
is_deeply($c2, $c1, 'clone');

cmp_ok(total($c2), '==', 399747, 'total');

cmp_ok(sprintf('%.2f', median($c2)), '==', 57106.71, 'median');

cmp_ok(depth($c2), '==', 3, 'depth');

cut($c2);
cmp_ok(total($c2), '==', 199873.5, 'cut');

serialize($c1, 'serialized.bin');
is_deeply(unserialize('serialized.bin'), $c1, 'serialize/unserialize');

is_deeply(parse(unparse($c1)), $c1, 'parsing/unparsing');

