#
# Copyright (c) 2004-2014 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

Chj::repl - read-eval-print loop

=head1 SYNOPSIS

 use Chj::repl;
 repl;
 # -or-
 use Chj::repl();
 Chj::repl;

=head1 DESCRIPTION

For a simple parameterless start of `Chj::Util::Repl`.

=head1 SEE ALSO

L<Chj::Util::Repl>

=cut


package Chj::repl;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(repl);

use strict;
use Chj::Util::Repl;

sub repl {
    my ($maybe_skip)=@_;
    my $r= new Chj::Util::Repl;
    #$r->run ($maybe_skip);
    my $m= $r->can("run"); @_=($r, $maybe_skip); goto $m
}

*Chj::repl= \&repl;

1
