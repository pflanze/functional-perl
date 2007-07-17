# Fri Oct 29 16:30:48 2004  Chris Tarnutzer, tarnutzer@ethlife.ethz.ch
# 
# Copyright 2004 by Chris Tarnutzer
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Backtrace

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::Backtrace;
use strict;
use Carp;

# Carp::longmess 'usually' inserts a needless repetition
# if the argument was already created by confess:
#   Hello at (eval 35) line 1.
#    at (eval 35) line 1
#           eval 'package calc; no strict \'vars\';  die "Hello"
#   ...
# Clean removes this needless second line/repetition.
# (croak creates a different text so the double duty is not removed.)

sub Clean {
    my ($str)=@_;
    $str=~ s/(at [^\n]* line \d+)\.\n (at [^\n]* line \d+)\n/
       if ($1 eq $2) {
          $1.".\n"
       } else {
          $1.".\n ".$2."\n"
       }
    /se;
    $str
}

our $singlestep=0;#?.
our $only_confess_if_not_already=1;
our $do_confess_objects=0;

sub import {
    $SIG{__DIE__} = sub {
	$DB::single=1 if $singlestep;
	if ($only_confess_if_not_already) {
	    if (!$do_confess_objects and ref $_[0]) { # exception object  (ah well, confess macht diesen check sowieso!)
		die @_
	    } else {
		#print STDERR "\n------\n@_\n------\n";
		if ($_[0]=~ /^[^\n]*line \d+\.\n/s) { # die, not confess.
		    die Clean Carp::longmess @_
		} elsif ($_[0]=~ /^[^\n]*line \d+\n\t/s) { # confess
		    die @_
		} else { # unsure
		    die Clean Carp::longmess @_
		}
	    }
	} else {
	    die Clean Carp::longmess @_
	}
    };
}


1;
