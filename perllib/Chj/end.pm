# Sun Feb  6 12:43:13 2005  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2004 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::end

=head1 SYNOPSIS

 use Chj::end();
 sub foo {
     my $recursive;
     my $_end= Chj::end{undef $recursive}; # one way to prevent the closure from leaking
                                        # (another way is the usage of WeakRef's)
     $recursive=sub {
         ...
         $recursive->(..)
     };
     $recursive->(..);
 }

=head1 DESCRIPTION

Same thing as the cpan 'end' (or End?) module. I made my private version only since
it was easier to distribute on my machines.

=cut


package Chj::end;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(end);

use strict;

sub new {
    bless $_[1],$_[0]
}

sub end ( & ) {
    bless $_[0],__PACKAGE__;
}

*Chj::end= *end{CODE};


sub DESTROY {
    #warn "DESTROY";
    local ($@,$!,$?);
    &{$_[0]}
}
