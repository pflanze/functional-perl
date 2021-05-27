#
# Copyright (c) 2021 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

Chj::Packages

=head1 SYNOPSIS

    use Chj::Packages qw(
        package_to_requirepath
        require_package
        fallible_require_package_by_path
        xrequire_package_by_path
        );
    my $packagename = "Chj::Packages";
    my $possibly_previously_loaded_path = require_package $packagename;
    my $true_or_failure = fallible_require_package_by_path $packagename;
    # xrequire_package_by_path turns the failure into an exception.

    # related (mess?):
    # use FP::Predicates qw($package_re);

=head1 DESCRIPTION

Dealing with packages, and their loading, yet again.

=head1 TODO

What is the proper upstream way? And do I have other code somewhere?

Also, FP::Fallible may not be the best idea (instead make a proper sum
type and offer an `Ok` value? A modified L<FP::Either>?)

=head1 SEE ALSO

L<FP::Fallible>

=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut

package Chj::Packages;
use strict;
use utf8;
use warnings;
use warnings FATAL => 'uninitialized';
use experimental 'signatures';
use Exporter "import";

our @EXPORT    = qw();
our @EXPORT_OK = qw(
    package_to_requirepath
    require_package
    fallible_require_package_by_path
    xrequire_package_by_path
);
our %EXPORT_TAGS = (all => [@EXPORT, @EXPORT_OK]);

use FP::Docstring;
use Chj::TEST ":all";

#use Chj::Package::OfPath qw(package_of_path);
# Uh, that's expensive, so: XXX better
sub path_to_package__cheap($path) {
    $path =~ s{^\./}{};
    my $package = $path;
    while ($package =~ s{^\../}{}) { }
    $package =~ s{^(lib|meta)/}{};
    $package =~ s/\.pm$//;
    $package =~ s|/|::|sg;
    $package
}

TEST { path_to_package__cheap "meta/FunctionalPerl/Indexing.pm" }
'FunctionalPerl::Indexing';

sub package_to_requirepath($package) {
    $package =~ s|::|/|g;
    $package .= ".pm";
    $package
}

sub require_package($package) {
    __ 'require the package whose namespace is given; return the path
        actually loaded';
    my $requirepath = package_to_requirepath($package);
    require $requirepath;
    $INC{$requirepath}
}

use Cwd 'abs_path';
use FP::Failure;    # worrying dependency

sub fallible_require_package_by_path($path) {
    my $path_abs = abs_path $path;
    my $package  = path_to_package__cheap $path;   # XX hack, how to generalize?
         # Can't load by path (at least not 'properly'), so, load and then
         # check:
    my $path2     = require_package $package;
    my $path_abs2 = abs_path $path2;
    if ($path_abs eq $path_abs2) {
        1
    } else {
        failure "require_package_by_path('$path'): the actually loaded package "
            . "is '$path_abs2', not '$path_abs'"
    }
}

sub xrequire_package_by_path ($path) {
    my $res = fallible_require_package_by_path($path);
    $res or die $res
}

1
