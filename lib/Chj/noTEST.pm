#
# Copyright 2013 by Christian Jaeger, ch at christianjaeger ch
# Published under the same terms as perl itself
#

=head1 NAME

Chj::noTEST

=head1 SYNOPSIS

 use Chj::noTEST;
 TEST { foo } "bar"; # will be ignored / garbage collected right away

=head1 DESCRIPTION

Disable TEST forms within a package, so that they don't take up memory
or clutter your test output. (Note that you can always restrict which
packages to run tests on by giving arguments to run_tests, though. But
they *will* take up some memory even when never used, hence
Chj::noTEST.)

=head1 SEE ALSO

 Chj::TEST

=cut


package Chj::noTEST;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(TEST);
@EXPORT_OK=qw();
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict; use warnings FATAL => 'uninitialized';

sub TEST (&$) {
    ()
}

sub TEST_STDOUT (&$) {
    ()
}

1
