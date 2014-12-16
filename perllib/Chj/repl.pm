# Wed Jan  5 17:01:15 2005  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2004 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::repl

=head1 SYNOPSIS

 use Chj::repl;
 repl;
 # -or-
 use Chj::repl();
 Chj::repl;

=head1 DESCRIPTION

for a simple parameterless start.

=head1 SEE ALSO

L<Chj::Util::Repl>

=cut


package Chj::repl;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(repl);

use strict;
use Chj::Util::Repl;

sub repl {
    my ($opt_package)=@_;
    my $r= new Chj::Util::Repl;
    $r->set_package($opt_package || caller);
    $r->run;
}

*Chj::repl= \&repl;

1
