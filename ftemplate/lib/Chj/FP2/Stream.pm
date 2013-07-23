#
# Copyright 2013 by Christian Jaeger, ch at christianjaeger ch
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::FP2::Stream - functions for lazily generated, singly linked (purely functional) lists

=head1 SYNOPSIS

 use Chj::FP2::Stream ':all';

 stream_length stream_iota 5
 # => 5;
 stream_length stream_iota 5000000
 # => 5000000;

 use Chj::FP2::Lazy;
 Force stream_fold_right sub { my ($n,$rest)=@_; $n + Force $rest }, 0, stream_iota 5
 # => 10;


=head1 DESCRIPTION

Create and dissect sequences using pure functions. Lazily.

=cut


package Chj::FP2::Stream;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(
	      stream_iota
	      stream_length
	      stream_map
	      stream_filter
	      stream_fold_right
	      stream__array_fold_right
	      array2stream
	      stream_for_each
	      stream_take
	      stream_zip2
	      stream2array
	      stream_mixed_flatten
	 );
@EXPORT_OK=qw(F);
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict;

use Chj::FP2::Lazy;

#use Chj::FP2::Pair; ?
use Chj::FP2::List ":all";

use Scalar::Util 'weaken';

sub stream_iota {
    my ($maybe_n,$maybe_start)= @_;
    my $start= $maybe_start || 0;
    if (defined $maybe_n) {
	my $end = $start + $maybe_n;
	my $rec; $rec= sub {
	    my ($i)=@_;
	    Delay {
		if ($i<$end) {
		    cons ($i, &$rec($i+1))
		} else {
		    undef
		}
	    }
	};
	my $_rec= $rec;
	weaken $rec;
	@_=($start); goto $_rec;
    } else {
	my $rec; $rec= sub {
	    my ($i)=@_;
	    Delay {
		cons ($i, &$rec($i+1))
	    }
	};
	my $_rec= $rec;
	weaken $rec;
	@_=($start); goto $_rec;
    }
}

sub stream_length ($) {
    my ($l)=@_;
    weaken $_[0];
    my $len=0;
    $l= Force $l;
    while (defined $l) {
	$len++;
	$l= Force cdr $l;
    }
    $len
}

sub stream_map ($ $);
sub stream_map ($ $) {
    my ($fn,$l)=@_;
    weaken $_[1];
    Delay {
	$l= Force $l;
	$l and cons(&$fn(car $l), stream_map ($fn,cdr $l))
    }
}

sub stream_zip2 ($$);
sub stream_zip2 ($$) {
    my ($l,$m)=@_;
    do {weaken $_ if defined $_ } for @_; #needed?
    Delay {
	$l= Force $l;
	$m= Force $m;
	($l and $m) and
	  cons([car $l, car $m], stream_zip2 (cdr $l, cdr $m))
    }
}

sub stream_filter ($ $);
sub stream_filter ($ $) {
    my ($fn,$l)=@_;
    weaken $_[1];
    Delay {
	$l= Force $l;
	$l and do {
	    my $a= car $l;
	    my $r= stream_filter ($fn,cdr $l);
	    (&$fn($a) ? cons($a, $r) : $r)
	}
    }
}

sub stream_fold_right ($ $ $);
sub stream_fold_right ($ $ $) {
    my ($fn,$start,$l)=@_;
    weaken $_[2];
    Delay {
	$l= Force $l;
	if (pairP $l) {
	    &$fn (car $l, stream_fold_right ($fn,$start,cdr $l))
	} elsif (nullP $l) {
	    $start
	} else {
	    die "improper list"
	}
    }
}

sub stream__array_fold_right ($$$) {
    @_==3 or die;
    my ($fn,$tail,$a)=@_;
    my $rec; $rec= sub {
	my ($i)=@_;
	Delay {
	    if ($i < @$a) {
		&$fn($$a[$i], &$rec($i+1))
	    } else {
		$tail
	    }
	}
    };
    my $rec_= $rec;
    weaken $rec;
    &$rec_(0)
}

sub array2stream ($;$) {
    my ($a,$tail)=@_;
    stream__array_fold_right (\&cons, $tail, $a)
}

sub stream_for_each ($ $ ) {
    my ($proc, $s)=@_;
    weaken $_[1];
  LP: {
	$s= Force $s;
	if (defined $s) {
	    &$proc(car $s);
	    $s= cdr $s;
	    redo LP;
	}
    }
}

sub stream_take ($ $);
sub stream_take ($ $) {
    my ($s, $n)=@_;
    weaken $_[0];
    Delay {
	if ($n > 0) {
	    $s= Force $s;
	    cons(car $s, stream_take( cdr $s, $n - 1))
	} else {
	    undef
	}
    }
}

# force everything deeply
sub F ($);
sub F ($) {
    my ($v)=@_;
    #weaken $_[0]; since I usually use it interactively, and should
    # only be good for short sequences, better don't
    if (promiseP $v) {
	$v= Force $v;
	if (pairP $v) {
	    cons (F(car $v), F(cdr $v))
	} else {
	    $v
	}
    } else {
	$v
    }
}

sub stream2array ($) {
    my ($l)=@_;
    weaken $_[0];
    my $res= [];
    my $i=0;
    $l= Force $l;
    while (defined $l) {
	my $v= car $l;
	$$res[$i]= $v;
	$l= Force cdr $l;
	$i++;
    }
    $res
}


sub stream_mixed_flatten ($;$$) {
    my ($v,$tail,$maybe_delay)=@_;
    mixed_flatten ($v,$tail, $maybe_delay||\&DelayLight)
}


# calc> :d stream_for_each sub { print @_,"\n"}, stream_map sub {my $v=shift; $v*$v},  array2stream [10,11,13]
# 100
# 121
# 169

# write_sexpr( stream_take( stream_iota (1000000000), 2))
# ->  ("0" "1")

# calc> :d list2array F stream_zip2 stream_map (sub{$_[0]+10},stream_iota (5)), stream_iota (3)
# $VAR1 = [
#           [
#             10,
#             0
#           ],
#           [
#             11,
#             1
#           ],
#           [
#             12,
#             2
#           ]
#         ];


1
