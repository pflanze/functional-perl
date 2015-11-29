#
# Copyright (c) 2015 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

Chj::AutoTrapl -- use Chj::Trapl on tty, Chj::Backtrace otherwise

=head1 SYNOPSIS

  use Chj::AutoTrapl;

=head1 DESCRIPTION

This checks whether stdin and stdout are going to a tty, if so, then
activate Chj::Trapl to trap errors in a repl, otherwise just activate
Chj::Backtrace.

=head1 SEE ALSO

L<Chj::Trapl>, L<Chj::Backtrace>

=cut


package Chj::AutoTrapl;

use strict; use warnings; use warnings FATAL => 'uninitialized';

# Interesting, Chj::Repl::maybe_tty works differently; well makes
# sense. So this is the "non-forcing" way to check:
use POSIX qw(isatty);

if (isatty(0) and isatty(1)) {
    require Chj::WithRepl;
    import Chj::WithRepl;
    push_withrepl (0);
} else {
    require Chj::Backtrace;
    import Chj::Backtrace;
}


1
