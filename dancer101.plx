#!/usr/bin/perl
use strict;
use warnings;
use Dancer;
use Data::Dumper;
use File::Slurp;
use Template;
use C101::Sample;
use C101::Persistence qw(serialize unserialize);
use C101::Operations  qw(uuids);

set( 
    session      => 'Simple',
    template     => 'template_toolkit',
    logger       => 'console',
    log          => 'debug',
    show_errors  => 1,
    startup_info => 1,
    warnings     => 1,
    companies    => 'companies.bin',
);


my $companies = -e setting('companies')
              ? unserialize(setting('companies'))
              : [ C101::Sample::create ];
my $uuids     = uuids(@$companies);


get '/' => sub {
    template 'index.tt' => {
        companies => $companies,
    };
};

$SIG{INT} = sub {
    serialize($companies, 'companies.bin');
    exit;
};

dance;

