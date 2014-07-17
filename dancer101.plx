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

sub make_config {
    my @add    = ('company');
    my @ops    = (0, 'cut', 'depth', 'median', 'total');
    my @mod    = (0, 'edit', 'delete');
    my $config = {
        method  => {
            name        => 'ajax',
            tree_url    => '/tree',
            action_urls => {
                restructure => '/restructure',
            },
        },
        types   => {
            root       => {
                icon     => '/plus.png',
                actions  => [@add, @ops],
                children => ['company'],
            },
            company    => {
                icon     => '/comp_icon.png',
                actions  => [@add, 'department', @ops, @mod],
                children => ['department'],
            },
            department => {
                icon    => '/dept_icon.png',
                actions => [@add, 'employee', 'department', @ops, @mod],
                children => ['department', 'employee'],
            },
            employee   => {
                icon     => '/empl_icon.png',
                actions  => [@add, @ops, @mod],
                printf   => {
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
    while (my ($k, $v) = each $config->{actions}) {
        $config->{method}{action_urls}{$k} = $v;
    }
    return $config;
}

my $server = C101::Server->new;
my $config = make_config;

ajax '/' => sub {
    my $type = param('type');
    if ($type eq 'config') {
        return $config;
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

