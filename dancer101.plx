#!/usr/bin/perl
use strict;
use warnings;
use feature              qw(say switch);
use Dancer;
use Dancer::Plugin::Ajax;
use Data::Dumper;
use C101::Operations     qw(cut median total);
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
    engines      => {
        JSON => {
            allow_blessed   => 1,
            convert_blessed => 1,
        },
    },
);


my $server = C101::Server->new;

ajax '/' => sub {
    my $type = param('type');
    if ($type eq 'config') {
        my @add = ('company');
        my @ops = (0, 'cut', 'depth', 'median', 'total');
        my @mod = (0, 'edit', 'delete');
        return {
            method  => {
                name        => 'ajax',
                tree_url    => '/tree',
                action_urls => {
                    company => '/company',
                },
            },
            types   => {
                root       => {
                    icon    => '/plus.png',
                    actions => [@add, @ops],
                },
                company    => {
                    icon    => '/comp_icon.png',
                    actions => [@add, 'department', @ops, @mod],
                },
                department => {
                    icon    => '/dept_icon.png',
                    actions => [@add, 'employee', 'department', @ops, @mod],
                },
                employee   => {
                    icon    => '/empl_icon.png',
                    actions => [@add, @ops, @mod],
                    printf  => {
                        format => '%s, %s, $%.2f',
                        args   => ['text', 'address', 'salary'],
                    },
                },
            },
            actions => {
                company    => {text => 'Create Company', icon => '/comp_add.png'},
                department => {text => 'Add Department', icon => '/dept_add.png'},
                employee   => {text => 'Add Employee',   icon => '/empl_add.png'},
                cut        => 'Cut',
                depth      => 'Depth',
                median     => 'Median',
                total      => 'Total',
                edit       => 'Edit',
                delete     => 'Delete',
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

ajax '/tree' => sub {{
    type     => 'root',
    text     => 'Companies',
    state    => {'opened' => 1},
    children => $server->companies,
}};

get '/' => sub { send_file '/web_ui.html' };


# Exit gracefully so that all destructors will be called.
$SIG{INT} = sub {
    $server->save;
    exit;
};


dance;

