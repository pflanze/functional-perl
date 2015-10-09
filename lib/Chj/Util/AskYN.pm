# Sun Jun 22 01:15:07 2003  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2001 by ethlife renovation project people
# Published under the terms of the GNU General Public License
#
# $Id$

=head1 NAME

Chj::Util::AskYN

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::Util::AskYN;
@ISA="Exporter"; require Exporter;
@EXPORT= qw(askyn);


use strict;

sub askyn {
    my ($prompt)=@_;
  ASK:{
	if (defined $prompt) {
	    local $|=1;
	    print $prompt;
	}
	my $ans=<STDIN>;
	if (! $ans) {
	    print "\n";# enter nachholen damit die shell zeile nicht auf derselben zeile landet.
	    return # undef!
	}
	if ($ans=~ /^n(?:o|ein|ada|on)?$/i) {
	    return 0;
	} elsif ($ans=~ /^(?:ja|yes|j|y|oui)$/i){
	    return 1;
	} else {
	    redo ASK;
	}
    }
}

1;
