#
# Copyright (c) 2015 Christian Jaeger, copying@christianjaeger.ch
# Published under the same terms as perl itself
#

=head1 NAME

Chj::Trapl

=head1 SYNOPSIS

 use Chj::Trapl;
 die "fun"; # opens a repl from Chj::repl

=head1 DESCRIPTION

Dead-simple wrapper around Chj::WithRepl that simply enables trapping
globally.

NOTE: the name is not set in stone yet, also, perhaps it should be
*merged* with Chj::WithRepl.

=head1 SEE ALSO

L<Chj::WithRepl>

=cut


package Chj::Trapl;

use Chj::WithRepl;

push_withrepl (0);

1
