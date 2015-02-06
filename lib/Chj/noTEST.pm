#
# Copyright 2013 by Christian Jaeger, ch at christianjaeger ch
# Published under the same terms as perl itself
#

=head1 NAME

Chj::noTEST

=head1 SYNOPSIS

 use Chj::noTEST; # instead of `use Chj::TEST;`
 TEST { foo } "bar"; # will be ignored / garbage collected right away

=head1 DESCRIPTION

Disable TEST and TEST_STDOUT forms within a package, perhaps because
they currently fail or are slow, or so that they never use memory.

Note that you can alternatively ignore *all* test forms within the
whole program by setting the TEST environment variable to 0. Also you
can pass package names to `run_tests` to limit the tests to run to
those within the given packages.

=head1 SEE ALSO

 Chj::TEST

=cut


package Chj::noTEST;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(TEST TEST_STDOUT perhaps_run_tests);
@EXPORT_OK=qw();
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict; use warnings FATAL => 'uninitialized';

sub TEST (&$) {
    ()
}

sub TEST_STDOUT (&$) {
    ()
}

sub perhaps_run_tests {
    ()
}


1
