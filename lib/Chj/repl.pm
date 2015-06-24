#
# Copyright 2004-2014 by Christian Jaeger, ch at christianjaeger . ch
# Published under the same terms as perl itself
#

=head1 NAME

Chj::repl

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
    my ($opt_package)=@_;
    my $r= new Chj::Util::Repl;
    $r->set_package($opt_package) if $opt_package;
    #$r->run;
    my $m= $r->can("run"); @_=($r); goto $m
}

*Chj::repl= \&repl;

1
