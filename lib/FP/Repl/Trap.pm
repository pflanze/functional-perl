#
# Copyright (c) 2015 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FP::Repl::Trap

=head1 SYNOPSIS

    use FP::Repl::Trap;
    die "fun"; # opens a repl from FP::Repl

=head1 DESCRIPTION

Dead-simple wrapper around FP::Repl::WithRepl that simply enables trapping
globally.

NOTE: the name is not set in stone yet, also, perhaps it should be
*merged* with FP::Repl::WithRepl.

=head1 SEE ALSO

L<FP::Repl::WithRepl>, L<FP::Repl::AutoTrap>

=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut

package FP::Repl::Trap;

use strict;
use warnings;
use warnings FATAL => 'uninitialized';

use FP::Repl::WithRepl;

if (($ENV{RUN_TESTS} // '') eq '1') {
    warn "not activating since running in test mode";
} else {
    push_withrepl(0);
}

1
