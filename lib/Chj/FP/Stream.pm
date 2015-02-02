#
# Copyright 2013 by Christian Jaeger, ch at christianjaeger ch
# Published under the same terms as perl itself
#

=head1 NAME

Chj::FP::Stream - functions for lazily generated, singly linked (purely functional) lists

=head1 SYNOPSIS

 use Chj::FP::Stream ':all';

 stream_length stream_iota (101, 5)
 # => 5;
 stream_length stream_iota (undef, 5000000)
 # => 5000000;

 use Chj::FP::Lazy;
 Force stream_fold_right sub { my ($n,$rest)=@_; $n + Force $rest }, 0, stream_iota undef, 5
 # => 10;


=head1 DESCRIPTION

Create and dissect sequences using pure functions. Lazily.

=cut


package Chj::FP::Stream;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(
	      Keep
	      Weakened
	      stream_iota
	      stream_length
	      stream_append
	      stream_map
	      stream_map_with_tail
	      stream_filter
	      stream_fold_right
	      stream__array_fold_right
	      stream__string_fold_right
	      stream__subarray_fold_right stream__subarray_fold_right_reverse
	      array2stream
	      subarray2stream subarray2stream_reverse
	      string2stream
	      stream2string
	      stream_for_each
	      stream_drop
	      stream_take
	      stream_take_while
	      stream_drop_while
	      stream_ref
	      stream_zip2
	      stream_zip
	      stream_zip_with
	      stream2array
	      stream_mixed_flatten
	      stream_any
	 );
@EXPORT_OK=qw(F);
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict; use warnings FATAL => 'uninitialized';

use Chj::FP::Lazy;
#use Chj::FP::Pair; ?
use Chj::FP::List ":all";
use Scalar::Util 'weaken';
use Chj::TEST;


# protect a variable from being pruned by callees that prune their
# arguments
sub Keep ($) {
    my ($v)=@_;
    $v
}

# weaken a variable, but also provide a non-weakened reference to its
# value as result
sub Weakened ($) {
    my ($ref)= @_;
    weaken $_[0];
    $ref
}


sub stream_iota {
    my ($maybe_start, $maybe_n)= @_;
    my $start= $maybe_start || 0;
    if (defined $maybe_n) {
	my $end = $start + $maybe_n;
	my $rec; $rec= sub {
	    my ($i)=@_;
	    Delay {
		if ($i<$end) {
		    cons ($i, &$rec($i+1))
		} else {
		    null
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
    while (!nullP $l) {
	$len++;
	$l= Force cdr $l;
    }
    $len
}

sub stream_append ($$) {
    my ($l1,$l2)=@_;
    weaken $_[0];
    weaken $_[1];
    Delay {
	$l1= Force $l1;
	nullP($l1) ? $l2 : cons (car $l1, stream_append (cdr $l1, $l2))
    }
}

TEST{ stream2string (stream_append string2stream("Hello"), string2stream(" World")) }
  'Hello World';

sub stream_map ($ $);
sub stream_map ($ $) {
    my ($fn,$l)=@_;
    weaken $_[1];
    Delay {
	$l= Force $l;
	nullP $l ? null : cons(&$fn(car $l), stream_map ($fn,cdr $l))
    }
}

sub stream_map_with_tail ($ $ $);
sub stream_map_with_tail ($ $ $) {
    my ($fn,$l,$tail)=@_;
    weaken $_[1];
    Delay {
	$l= Force $l;
	nullP $l ? $tail : cons(&$fn(car $l),
				stream_map_with_tail ($fn, cdr $l, $tail))
    }
}

# 2-ary (possibly slightly faster) version of stream_zip
sub stream_zip2 ($$);
sub stream_zip2 ($$) {
    my ($l,$m)=@_;
    do {weaken $_ if promiseP $_ } for @_; #needed?
    Delay {
	$l= Force $l;
	$m= Force $m;
	(nullP $l or nullP $m) ? null
	  : cons([car $l, car $m], stream_zip2 (cdr $l, cdr $m))
    }
}

# n-ary version of stream_zip2
sub stream_zip {
    my @ps= @_;
    do {weaken $_ if promiseP $_ } for @_; #needed?
    Delay {
	my @vs= map {
	    my $v= Force $_;
	    nullP $v ? return null : $v
	} @ps;
	my $a= [map { car $_ } @vs];
	my $b= stream_zip (map { cdr $_ } @vs);
	cons($a, $b)
    }
}

sub stream_zip_with {
    my ($f, $l1, $l2)= @_;
    undef $_[1]; undef $_[2];
    Delay
    {
	my $l1= Force $l1;
	my $l2= Force $l2;
	(nullP $l1 or nullP $l2) ? null
	  : cons &$f(car $l1, car $l2), stream_zip_with ($f, cdr $l1, cdr $l2)
    }
}


sub stream_filter ($ $);
sub stream_filter ($ $) {
    my ($fn,$l)=@_;
    weaken $_[1];
    Delay {
	$l= Force $l;
	nullP $l ? null : do {
	    my $a= car $l;
	    my $r= stream_filter ($fn,cdr $l);
	    &$fn($a) ? cons($a, $r) : $r
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

sub make_stream__fold_right {
    my ($length, $ref, $start, $d, $whileP)=@_;
    sub ($$$) {
	@_==3 or die;
	my ($fn,$tail,$a)=@_;
	my $len= &$length ($a);
	my $rec; $rec= sub {
	    my ($i)=@_;
	    Delay {
		if (&$whileP($i,$len)) {
		    &$fn(&$ref($a, $i), &$rec($i + $d))
		} else {
		    $tail
		}
	    }
	};
	my $rec_= $rec;
	weaken $rec;
	&$rec_($start)
    }
}

our $lt= sub { $_[0] < $_[1] };
our $gt= sub { $_[0] > $_[1] };
our $array_length= sub { scalar @{$_[0]} };
our $array_ref= sub { $_[0][$_[1]] };
our $string_length= sub { length $_[0] };
our $string_ref= sub { substr $_[0], $_[1], 1 };

sub stream__array_fold_right ($$$);
*stream__array_fold_right= make_stream__fold_right
  ($array_length,
   $array_ref,
   0,
   1,
   $lt);

sub stream__string_fold_right ($$$);
*stream__string_fold_right= make_stream__fold_right
  ($string_length,
   $string_ref,
   0,
   1,
   $lt);

sub stream__subarray_fold_right ($$$$$) {
    my ($fn,$tail,$a,$start,$maybe_end)=@_;
    make_stream__fold_right ($array_length,
			     $array_ref,
			     $start,
			     1,
			     defined $maybe_end ?
			     sub { $_[0] < $_[1] and $_[0] < $maybe_end }
			     : $lt)
      ->($fn,$tail,$a);
}

sub stream__subarray_fold_right_reverse ($$$$$) {
    my ($fn,$tail,$a,$start,$maybe_end)=@_;
    make_stream__fold_right ($array_length,
			     $array_ref,
			     $start,
			     -1,
			     defined $maybe_end ?
			     sub { $_[0] >= 0 and $_[0] > $maybe_end }
			     : sub { $_[0] >= 0 })
      ->($fn,$tail,$a);
}


sub array2stream ($;$) {
    my ($a,$maybe_tail)=@_;
    stream__array_fold_right (\&cons, $maybe_tail//null, $a)
}

sub subarray2stream ($$;$$) {
    my ($a, $start, $maybe_end, $maybe_tail)=@_;
    stream__subarray_fold_right
      (\&cons, $maybe_tail//null, $a, $start, $maybe_end)
}

sub subarray2stream_reverse ($$;$$) {
    my ($a, $start, $maybe_end, $maybe_tail)=@_;
    stream__subarray_fold_right_reverse
      (\&cons, $maybe_tail//null, $a, $start, $maybe_end)
}


sub string2stream ($;$) {
    my ($str,$maybe_tail)=@_;
    stream__string_fold_right (\&cons, $maybe_tail//null, $str)
}

sub stream2string ($) {
    my ($l)=@_;
    my $str="";
    while (($l= Force $l), !nullP $l) {
	$str.= car $l;
	$l= cdr $l;
    }
    $str
}

sub stream_for_each ($ $ ) {
    my ($proc, $s)=@_;
    weaken $_[1];
  LP: {
	$s= Force $s;
	if (!nullP $s) {
	    &$proc(car $s);
	    $s= cdr $s;
	    redo LP;
	}
    }
}

sub stream_drop ($ $);
sub stream_drop ($ $) {
    my ($s, $n)=@_;
    weaken $_[0];
    while ($n > 0) {
	$s= Force $s;
	die "stream too short" if nullP $s;
	$s= cdr $s;
	$n--
    }
    $s
}

sub stream_take ($ $);
sub stream_take ($ $) {
    my ($s, $n)=@_;
    weaken $_[0];
    Delay {
	if ($n > 0) {
	    $s= Force $s;
	    nullP $s ?
	      $s
		: cons(car $s, stream_take( cdr $s, $n - 1));
	} else {
	    null
	}
    }
}

sub stream_take_while ($ $);
sub stream_take_while ($ $) {
    my ($fn,$s)=@_;
    weaken $_[1];
    Delay {
	$s= Force $s;
	if (nullP $s) {
	    null
	} else {
	    my $a= car $s;
	    if (&$fn($a)) {
		cons $a, stream_take_while($fn, cdr $s)
	    } else {
		null
	    }
	}
    }
}

sub stream_drop_while ($ $) {
    my ($pred,$s)=@_;
    weaken $_[1];
    Delay {
      LP: {
	    $s= Force $s;
	    if (!nullP $s and &$pred(car $s)) {
		$s= cdr $s;
		redo LP;
	    } else {
		$s
	    }
	}
    }
}

sub stream_ref ($ $) {
    my ($s, $i)=@_;
    weaken $_[0];
  LP: {
	$s= Force $s;
	if ($i <= 0) {
	    car $s
	} else {
	    $s= cdr $s;
	    $i--;
	    redo LP;
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
	F Force $v;
    } else {
	if (pairP $v) {
	    cons (F(car $v), F(cdr $v))
	} elsif (ref ($v) eq "ARRAY") {
	    [ map { F $_ } @$v ]
	} else {
	    $v
	}
    }
}

sub stream2array ($) {
    my ($l)=@_;
    weaken $_[0];
    my $res= [];
    my $i=0;
    $l= Force $l;
    while (!nullP $l) {
	my $v= car $l;
	$$res[$i]= $v;
	$l= Force cdr $l;
	$i++;
    }
    $res
}


sub stream_mixed_flatten ($;$$) {
    my ($v,$maybe_tail,$maybe_delay)=@_;
    mixed_flatten ($v,$maybe_tail//null, $maybe_delay||\&DelayLight)
}

sub stream_any ($ $);
sub stream_any ($ $) {
    my ($pred,$l)=@_;
    weaken $_[1];
    $l= Force $l;
    if (pairP $l) {
	(&$pred (car $l)) or do{
	    my $r= cdr $l;
	    stream_any($pred,$r)
	}
    } elsif (nullP $l) {
	0
    } else {
	die "improper list"
    }
}

TEST{ stream_any sub { $_[0] % 2 }, array2stream [2,4,8] }
  0;
TEST{ stream_any sub { $_[0] % 2 }, array2stream [] }
  0;
TEST{ stream_any sub { $_[0] % 2 }, array2stream [2,5,8]}
  1;
TEST{ stream_any sub { $_[0] % 2 }, array2stream [7] }
  1;


TEST {
    my @v;
    stream_for_each sub { push @v, @_ },
      stream_map sub {my $v=shift; $v*$v},
	array2stream [10,11,13];
    \@v
}
  [ 100, 121, 169 ];

TEST {
    my @v;
    stream_for_each sub { push @v, @_ },
      stream_map_with_tail( sub {my $v=shift; $v*$v},
			    array2stream ([10,11,13]),
			    array2stream ([1,2]));
    \@v
}
  [ 100, 121, 169, 1, 2 ];

TEST {
    stream2array
      stream_filter sub { $_[0] % 2 },
	stream_iota 0, 5;
}
  [ 1, 3 ];

# write_sexpr( stream_take( stream_iota (0, 1000000000), 2))
# ->  ("0" "1")

TEST{ stream2array stream_zip cons (2, null), cons (1, null) }
  [[2,1]];
TEST{ stream2array stream_zip cons (2, null), null }
  [];


TEST{ list2array F stream_zip2 stream_map (sub{$_[0]+10}, stream_iota (0, 5)),
	stream_iota (0, 3) }
  [
   [
    10,
    0
   ],
   [
    11,
    1
   ],
   [
    12,
    2
   ]
  ];

TEST{ stream2array stream_take_while sub { my ($x)=@_; $x < 2 }, stream_iota }
  [
   0,
   1
  ];

TEST{stream2array  stream_take stream_drop_while( sub{ $_[0] < 10}, stream_iota ()), 3}
  [
   10,
   11,
   12
  ];

TEST{stream2array
       stream_drop_while( sub{ $_[0] < 10}, stream_iota (0, 5))}
  [];


TEST { join("", @{stream2array (string2stream("You're great."))}) }
  'You\'re great.';

TEST { stream2string
	 stream__subarray_fold_right
	   (\&cons,
	    string2stream("World"),
	    [split //, "Hello"],
	    3,
	    undef) }
  'loWorld';

TEST { stream2string stream__subarray_fold_right \&cons, string2stream("World"), [split //, "Hello"], 3, 4 }
  'lWorld';

TEST { stream2string stream__subarray_fold_right_reverse  \&cons, cons("W",null), [split //, "Hello"], 1, undef }
  'eHW';

TEST { stream2string stream__subarray_fold_right_reverse  \&cons, cons("W",null), [split //, "Hello"], 2,0 }
  'leW'; # hmm really? exclusive lower boundary?

TEST { stream2string subarray2stream [split //, "Hello"], 1, 3 }
  'el';

TEST { stream2string subarray2stream [split //, "Hello"], 1, 99 }
  'ello';

TEST { stream2string subarray2stream [split //, "Hello"], 2 }
  'llo';

TEST { stream2string subarray2stream_reverse  [split //, "Hello"], 1 }
  'eH';

TEST { stream2string subarray2stream_reverse  [split //, "Hello"], 1, 0 }
  'e'; # dito. BTW it's consistent at least, $start not being 'after the element'(?) either.

1
