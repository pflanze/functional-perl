#
# Copyright (c) 2013-2019 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

Chj::noTEST

=head1 SYNOPSIS

    use Chj::noTEST; # instead of `use Chj::TEST;`
    TEST { foo() } "bar"; # will be ignored / garbage collected right away

=head1 DESCRIPTION

Disable TEST and TEST_STDOUT forms within a package, perhaps because
they currently fail or are slow, or so that they never use memory.

Note that you can alternatively ignore *all* test forms within the
whole program by setting the TEST environment variable to 0. Also you
can pass package names to `run_tests` to limit the tests to run to
those within the given packages.

=head1 SEE ALSO

L<Chj::TEST>

=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut

package Chj::noTEST;
@ISA = "Exporter";
require Exporter;
@EXPORT      = qw(TEST TEST_STDOUT TEST_EXCEPTION GIVES perhaps_run_tests);
@EXPORT_OK   = qw();
%EXPORT_TAGS = (all => [@EXPORT, @EXPORT_OK]);

use strict;
use warnings;
use warnings FATAL => 'uninitialized';

use Chj::TEST ();

*import = *Chj::TEST::import;

sub TEST (&$) { () }

sub TEST_STDOUT (&$) { () }

sub TEST_EXCEPTION (&$) { () }

sub GIVES (&) { () }

sub perhaps_run_tests { () }

1
