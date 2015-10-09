#
# Copyright (c) 2003-2015 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

Chj::Util::AskYN

=head1 SYNOPSIS

 use Chj::Util::AskYN;

 LP: {
     if (maybe_askyn "Do you want to retry?") {
         redo LP;
     }
 }

=head1 DESCRIPTION

Simply ask for a boolean question on stdout/stdin. Accept y/n, yes/no
in english, german and french and return those as boolean
true/false. If the user closes the input (using ctl-d), undef is
returned.

=head1 TODO

Delete this and use something else?

=cut


package Chj::Util::AskYN;
@ISA="Exporter"; require Exporter;
@EXPORT= qw(maybe_askyn);

use strict;

sub maybe_askyn {
    my ($prompt)=@_;
  ASK:{
	if (defined $prompt) {
	    local $|=1;
	    print $prompt;
	}
	my $ans=<STDIN>;
	if (defined $ans) {
	    if ($ans=~ /^n(?:o|ein|ada|on)?$/i) {
		''
	    } elsif ($ans=~ /^(?:ja|yes|j|y|oui)$/i){
		1
	    } else {
		redo ASK;
	    }
	} else {
	    # EOF, i.e. ctl-d
	    print "\n";
	    undef
	}
    }
}

1
