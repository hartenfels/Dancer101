#!/usr/bin/perl
use strict;
use warnings;
use feature              qw(say switch);
use Dancer;
use Dancer::Plugin::Ajax;
use Data::Dumper;
use C101::Operations     qw(cut median total);
use C101::Persistence    qw(plainify);
use C101::Server;

set( 
    session      => 'Simple',
    template     => 'template_toolkit',
    layout       => 'main',
    logger       => 'console',
    log          => 'debug',
    show_errors  => 1,
    startup_info => 1,
    warnings     => 1,
    serializer   => 'JSON',
);


my $server = C101::Server->new;

ajax '/' => sub {
    my $type = param('type');
    if ($type eq 'config') {
        return {
            method => 'ajax',
            urls   => {
                tree => '/tree',
            },
            types  => {
                company    => {
                    icon           => '/comp_icon.png',
                    valid_children => ['department'],
                },
                department => {
                    icon           => '/dept_icon.png',
                    valid_children => ['department', 'employee'],
                },
                employee   => {
                    icon           => '/empl_icon.png',
                    text           => {
                        format => '%s, %s, $%.2f',
                        args   => ['name', 'address', 'salary'],
                    },
                },
            },
        };
    } else {
        return {
            messages => {
                text => "Unknown request: $type",
                type => 'error'
            },
        };
    }
};

ajax '/tree' => sub { 
    return {companies => plainify(@{$server->companies})};
};

get '/' => sub { send_file '/web_ui.html' };


# Exit gracefully so that all destructors will be called.
$SIG{INT} = sub {
    $server->save;
    exit;
};


dance;

