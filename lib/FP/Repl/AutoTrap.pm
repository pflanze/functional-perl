#
# Copyright (c) 2015 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FP::Repl::AutoTrap -- use FP::Repl::Trap on tty, Chj::Backtrace otherwise

=head1 SYNOPSIS

  use FP::Repl::AutoTrap;

=head1 DESCRIPTION

This checks whether stdin and stdout are going to a tty, if so, then
activate FP::Repl::Trap to trap errors in a repl, otherwise just activate
Chj::Backtrace.

=head1 SEE ALSO

L<FP::Repl::Trap>, L<Chj::Backtrace>

=head1 NOTE

This is alpha software! Read the package README.

=cut


package FP::Repl::AutoTrap;

use strict; use warnings; use warnings FATAL => 'uninitialized';

# Interesting, FP::Repl::Repl::maybe_tty works differently; well makes
# sense. So this is the "non-forcing" way to check:
use POSIX qw(isatty);

if (isatty(0) and isatty(1)) {
    require FP::Repl::WithRepl;
    import FP::Repl::WithRepl;
    push_withrepl (0);
} else {
    require Chj::Backtrace;
    import Chj::Backtrace;
}


1
