#!/usr/bin/perl
use strict;
use warnings;
use Storable;
use Test::More tests => 6;
use C101::Sample;
use C101::Cut           'cut';
use C101::Depth         'depth';
use C101::Median        'median';
use C101::Serialization 'serialize', 'unserialize';
use C101::Total         'total';

my $c1 = C101::Sample::create;

my $c2 = Storable::dclone($c1);
is_deeply($c2, $c1, 'clone');

cmp_ok(total($c2), '==', 399747, 'total');

cmp_ok(sprintf('%.2f', median($c2)), '==', 57106.71, 'median');

cmp_ok(depth($c2), '==', 3, 'depth');

cut($c2);
cmp_ok(total($c2), '==', 199873.5, 'cut');

serialize($c1, 'serialized.bin');
is_deeply(unserialize('serialized.bin'), $c1, 'serialization');

