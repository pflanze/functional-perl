#
# Copyright (c) 2015 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

Chj::Trapl

=head1 SYNOPSIS

 use Chj::Trapl;
 die "fun"; # opens a repl from Chj::Repl

=head1 DESCRIPTION

Dead-simple wrapper around Chj::WithRepl that simply enables trapping
globally.

NOTE: the name is not set in stone yet, also, perhaps it should be
*merged* with Chj::WithRepl.

=head1 SEE ALSO

L<Chj::WithRepl>, L<Chj::AutoTrapl>

=cut


package Chj::Trapl;

use strict; use warnings; use warnings FATAL => 'uninitialized';

use Chj::WithRepl;

push_withrepl (0);

1
