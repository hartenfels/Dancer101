Implementation for [101 Companies](http://101companies.org/), see
[http://101companies.org/wiki/Contribution:dancer](http://101companies.org/wiki/Contribution:dancer) for details.

# Requirements

Since this contribution is written in it, you will need [Perl](http://www.perl.org/)
(Perl 5 that is). If you are using any kind of Unix-like system (e.g. Linux or Mac OSX),
you probably already have it installed.

You will also need a few Perl packages that are not part of the standard distribution.
They are all in [CPAN](http://www.cpan.org/), so you can use any kind of CPAN installer
like [cpan](http://search.cpan.org/dist/CPAN/lib/CPAN.pm) or
[cpanminus](http://search.cpan.org/dist/App-cpanminus/lib/App/cpanminus.pm).

To install the packages with said installer, just run its command _as root_ with the
packages as parameters:
`cpan Dancer Data::Structure::Util Data::UUID File::Slurp JSON::XS Moops` (or replace
`cpan` with whatever the command for your installer is called).

# Testing

To ensure everything works, `cd` into this project's folder and run `test101.plx`.
This will test all available features and report the result.

# Dancing

To run the intersting feature of this contribution, namely the web UI, once again `cd`
into the project's folder, run `dancer101.plx` and then point your browser to
[http://localhost:3000/](http://localhost:3000/), preferably with JavaScript enabled.

# Documentation

See the `doc` folder for the interface documentation and the `.plx` and `.pm` files
themselves for the documented code itself.
