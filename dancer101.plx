#!/usr/bin/perl
use strict;
use warnings;
use Dancer;
use Dancer::Plugin::Ajax;
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
);


my $server = C101::Server->new;

my $index = sub {
    $server->handle_index;
};

my $add_company = sub {
    $server->handle_add({
        type     => 'Company',
        validate => [[name => 'Str']],
    })
};

my $edit_company = sub {
    $server->handle_edit({
        title    => 'Edit Company %s',
        type     => 'Company',
        validate => [[name => 'Str']],
    })
};

my $add_department = sub {
    $server->handle_add({
        type     => 'Department',
        list     => 'departments',
        validate => [[name => 'Str']],
    })
};

my $edit_department = sub {
    $server->handle_edit({
        title    => 'Edit Department %s',
        type     => 'Department',
        validate => [[name => 'Str']],
    })
};

my $add_employee = sub {
    $server->handle_add({
        type     => 'Employee',
        list     => 'employees',
        validate => [[name => 'Str'], [address => 'Str'], [salary => 'UnsignedNum']],
    })
};

my $edit_employee = sub {
    $server->handle_edit({
        title    => 'Edit Employee %s',
        type     => 'Employee',
        validate => [[name => 'Str'], [address => 'Str'], [salary => 'UnsignedNum']],
    })
};

my $edit_address = sub {
    $server->handle_edit({
        title    => 'Edit Address of Employee %s',
        type     => 'Employee',
        validate => [[address => 'Str']],
    })
};

my $edit_salary = sub {
    $server->handle_edit({
        title    => 'Edit Salary of Employee %s',
        type     => 'Employee',
        validate => [[salary => 'UnsignedNum']],
    })
};

my $delete = sub {
    $server->handle_delete;
};


get                    '/'                      => $index;
ajax                   '/add'                   => $add_company;
any ['get', 'post'] => '/add'                   => $add_company;
ajax                   '/edit/company/:uuid'    => $edit_company;
any ['get', 'post'] => '/edit/company/:uuid'    => $edit_company;
ajax                   '/add/department/:uuid'  => $add_department;
any ['get', 'post'] => '/add/department/:uuid'  => $add_department;
ajax                   '/edit/department/:uuid' => $edit_department;
any ['get', 'post'] => '/edit/department/:uuid' => $edit_department;
ajax                   '/add/employee/:uuid'    => $add_employee;
any ['get', 'post'] => '/add/employee/:uuid'    => $add_employee;
ajax                   '/edit/employee/:uuid'   => $edit_employee;
any ['get', 'post'] => '/edit/employee/:uuid'   => $edit_employee;
ajax                   '/edit/address/:uuid'    => $edit_address;
any ['get', 'post'] => '/edit/address/:uuid'    => $edit_address;
ajax                   '/edit/salary/:uuid'     => $edit_salary;
any ['get', 'post'] => '/edit/salary/:uuid'     => $edit_salary;
ajax                   '/delete/:uuid'          => $delete;
any ['get', 'post'] => '/delete/:uuid'          => $delete;


# Exit gracefully so that all destructors will be called.
$SIG{INT} = sub {
    $server->save;
    exit;
};


dance;

