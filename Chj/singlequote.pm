# Mon Aug  2 03:06:28 2004  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2004 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

# mann so lang hat das gebraucht bis ich das gmacht hab?.

=head1 NAME

Chj::singlequote

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::singlequote;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(singlequote);
@EXPORT_OK=qw(singlequote_sh singlequote_many many);# importing many is rather depreciated.
%EXPORT_TAGS=(all=>[qw(singlequote singlequote_sh singlequote_many)]);

use strict;

sub singlequote($ ;$ ) {
    my ($str,$alternative)=@_;
    if (defined $str) {
	$str=~ s/\'/\\\'/sg;
	"'$str'"
    } else {
	defined($alternative)? $alternative:"undef"
    }
}
sub singlequote_sh($ ;$ ) {
    my ($str,$alternative)=@_;
    if (defined $str) {
	$str=~ s/\'/'\\\''/sg;
	"'$str'"
    } else {
	defined($alternative)? $alternative:"undef"
    }
}

*Chj::singlequote= \&singlequote;
*Chj::singlequote_sh= \&singlequote_sh;

sub many {
    if (wantarray) {
	map { singlequote($_) } @_
    } else {
	join ", ", map { singlequote($_) } @_
    }
}
*singlequote_many= \&many;


1;
