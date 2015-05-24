#
# Copyright 2013 by Christian Jaeger, ch at christianjaeger ch
# Published under the same terms as perl itself
#

=head1 NAME

Chj::FP::List - singly linked (purely functional) lists

=head1 SYNOPSIS

 use Chj::FP::List ':all';
 list2string(cons("H",cons("e",cons("l",cons("l",cons("o",null))))))
 #-> "Hello"

=head1 DESCRIPTION

Create and dissect sequences using pure functions.

Note: uses "Pair" and "Null" as namespaces for shorter
dumps. Hopefully nobody else does?

=cut


package Chj::FP::List;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(cons is_pair null is_null is_pair_of is_list_of
	   car cdr first rest _car _cdr
	   car_and_cdr first_and_rest
	   list);
@EXPORT_OK=qw(string2list list_length list_reverse
	      list2string list2array rlist2array list2values write_sexpr
	      array2list mixed_flatten
	      list_map list_mapn list_fold_right list2perlstring
	      drop_while rtake_while take_while
	      list_append
	      list_zip2
	      list_every list_any
	      is_charlist ldie
	      array_fold_right
	      cddr
	      cdddr
	      cddddr
	      cadr
	      caddr
	      cadddr
	      caddddr
	    );
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict; use warnings; use warnings FATAL => 'uninitialized';

use Chj::FP::Lazy;
use Chj::xIO 'xprint';
use Chj::TEST;


sub cons ($ $) {
    bless [@_], "Pair";
}

sub is_pair ($) {
    my ($v)=@_;
    #ref($v) eq "ARRAY" and @$v == 2
    ref($v) eq "Pair"
}

sub is_pair_of ($$) {
    my ($p0,$p1)=@_;
    sub {
	@_==1 or die "expecting 1 argument";
	my ($v)=@_;
	(is_pair($v)
	 and &$p0($$v[0])
	 and &$p1($$v[1]))
    }
}

# nil
my $null= bless [],"Null";

sub null () {
    $null
}

sub is_null ($) {
    defined $_[0] and $_[0] eq $null
}


# leading underscore means: unsafe (but perhaps a tad faster)
sub _car ($) {
    $_[0][0]
}

sub _cdr ($) {
    $_[0][1]
}

use Chj::TerseDumper;
use Carp;
sub not_a_pair ($) {
    my ($v)= @_;
    croak "not a pair: ".TerseDumper($v);
}

sub car ($) {
    my ($v)=@_;
    if (ref ($v) eq "Pair") {
	$$v[0]
    } elsif (is_promise $v) {
	@_=force $v; goto \&car;
    } else {
	not_a_pair $v;
    }
}

sub first ($); *first=*car;

sub cdr ($) {
    my ($v)=@_;
    if (ref ($v) eq "Pair") {
	$$v[1]
    } elsif (is_promise $v) {
	@_=force $v; goto \&cdr;
    } else {
	not_a_pair $v;
    }
}

sub rest ($); *rest= *cdr;

sub cddr ($) { cdr cdr $_[0] }
sub cdddr ($) { cdr cdr cdr $_[0] }
sub cddddr ($) { cdr cdr cdr cdr $_[0] }

sub cadr ($) { car cdr $_[0] }
sub caddr ($) { car cdr cdr $_[0] }
sub cadddr ($) { car cdr cdr cdr $_[0] }
sub caddddr ($) { car cdr cdr cdr cdr $_[0] }


sub Pair::car_and_cdr {
    @{$_[0]}
}
## should I go back into OO mode after all....?

*Pair::head_and_tail= *Pair::car_and_cdr;
*Pair::first_and_rest= *Pair::car_and_cdr;

sub car_and_cdr ($) {
    my ($v)=@_;
    if (ref ($v) eq "Pair") {
	@{$_[0]}
    } elsif (is_promise $v) {
	@_=force $v; goto \&car_and_cdr;
    } else {
	not_a_pair $v;
    }
}

sub first_and_rest($); *first_and_rest= *car_and_cdr;


sub list {
    my $res=null;
    for (my $i= $#_; $i>=0; $i--) {
	$res= cons ($_[$i],$res);
    }
    $res
}

use Chj::FP::Predicates qw(either is_natural);

sub delayed (&) {
    my ($thunk)=@_;
    sub {
	# evaluate thunk, expecting a function and pass our arguments
	# to that function
	my $cont= &$thunk();
	goto $cont
    }
}

sub is_list_of ($);
sub is_list_of ($) {
    my ($p)= @_;
    either \&is_null, is_pair_of ($p, delayed { is_list_of $p })
}

TEST { is_list_of (\&is_natural) -> (list 1,2,3) } 1;
TEST { is_list_of (\&is_natural) -> (list -1,2,3) } 0;
TEST { is_list_of (\&is_natural) -> (list 1,2," 3") } 0;
TEST { is_list_of (\&is_natural) -> (1) } 0;


sub string2list ($;$) {
    my ($str,$maybe_tail)=@_;
    my $tail= $maybe_tail // null;
    my $i= length($str)-1;
    while ($i >= 0) {
	$tail= cons(substr ($str,$i,1), $tail);
	$i--;
    }
    $tail
}

sub array_fold_right ($$$) {
    @_==3 or die;
    my ($fn,$tail,$a)=@_;
    my $i= @$a - 1;
    while ($i >= 0) {
	$tail= &$fn($$a[$i], $tail);
	$i--;
    }
    $tail
}

sub array2list ($;$) {
    my ($a,$maybe_tail)=@_;
    array_fold_right (\&cons, $maybe_tail||null, $a)
}


sub list_length ($) {
    my ($l)=@_;
    my $len=0;
    while (!is_null $l) {
	$len++;
	$l= cdr $l;
    }
    $len
}

sub list_reverse ($) {
    my ($l)=@_;
    my $res=null;
    while (!is_null $l) {
	$res= cons car $l, $res;
	$l= cdr $l;
    }
    $res
}

sub list2string ($) {
    my ($l)=@_;
    my $len= list_length $l;
    my $res= " "x$len;
    my $i=0;
    while (!is_null $l) {
	my $c= car $l;
	substr($res,$i,1)= $c;
	$l= cdr $l;
	$i++;
    }
    $res
}

sub list2array ($) {
    my ($l)=@_;
    my $res= [];
    my $i=0;
    while (!is_null $l) {
	$$res[$i]= car $l;
	$l= cdr $l;
	$i++;
    }
    $res
}

sub rlist2array ($) {
    my ($l)=@_;
    my $res= [];
    my $len= list_length $l;
    my $i=$len;
    while (!is_null $l) {
	$i--;
	$$res[$i]= car $l;
	$l= cdr $l;
    }
    $res
}

sub list2values ($) {
    my ($l)=@_;
    @{list2array ($l)}
}

# write as a S-expr (trying to follow R5RS Scheme)
sub _write_sexpr ($ $ $);
sub _write_sexpr ($ $ $) {
    my ($l,$fh, $already_in_a_list)=@_;
  _WRITE_SEXPR: {
	$l= force ($l,1);
	if (is_pair $l) {
	    xprint $fh, $already_in_a_list ? ' ' : '(';
	    _write_sexpr car $l, $fh, 0;
	    my $d= force (cdr $l, 1);
	    if (is_null $d) {
		xprint $fh, ')';
	    } elsif (is_pair $d) {
		# tail-calling _write_sexpr $d, $fh, 1
		$l=$d; $already_in_a_list=1; redo _WRITE_SEXPR;
	    } else {
		xprint $fh, " . ";
		_write_sexpr $d, $fh, 0;
		xprint $fh, ')';
	    }
	} elsif (is_null $l) {
	    xprint $fh, "()";
	} else {
	    # normal perl things; should have a show method already
	    # for this? whatever.
	    if (ref $l) {
		die "don't know how to write_sexpr this: '$l'";
	    } else {
		# assume string; there's nothing else left.
		$l=~ s/"/\\"/sg;
		xprint $fh, '"',$l,'"';
	    }
	}
    }
}
sub write_sexpr ($ ; );
sub write_sexpr ($ ; ) {
    my ($l,$fh)=@_;
    _write_sexpr ($l, $fh || *STDOUT{IO}, 0)
}


sub list_zip2 ($$);
sub list_zip2 ($$) {
    my ($l,$m)=@_;
    ($l and $m) and
      cons([car $l, car $m], list_zip2 (cdr $l, cdr $m))
}

TEST { list2array list_zip2 list(qw(a b c)), list(2,3) }
  [[a=>2], [b=>3]];


sub list_map ($ $);
sub list_map ($ $) {
    my ($fn,$l)=@_;
    $l and cons(&$fn(car $l), list_map ($fn,cdr $l))
}

TEST { list2array list_map sub{$_[0]*$_[0]}, list 1,2,-3 }
  [1,4,9];


# n-ary map
sub list_mapn {
    my $fn=shift;
    for (@_) {
	return null if is_null $_
    }
    cons(&$fn(map {car $_} @_), list_mapn ($fn, map {cdr $_} @_))
}

TEST{ list2array list_mapn sub { [@_] }, array2list( [1,2,3]), string2list ("") }
  [];
TEST{ list2array list_mapn sub { [@_] }, array2list( [1,2,3]), string2list ("ab")}
  [[1,'a'],
   [2,'b']];


sub list_fold_right ($ $ $);
sub list_fold_right ($ $ $) {
    my ($fn,$start,$l)=@_;
    if (is_pair $l) {
	no warnings 'recursion';
	my $rest= list_fold_right ($fn,$start,cdr $l);
	&$fn (car $l, $rest)
    } elsif (is_null $l) {
	$start
    } else {
	die "improper list"
    }
}

TEST{ list_fold_right sub {
	  my ($v, $res)=@_;
	  [$v, @$res]
      }, [], list(4,5,9) }
  [4,5,9];


sub list_append ($ $) {
    my ($l1,$l2)=@_;
    list_fold_right (\&cons, $l2, $l1)
}


sub list2perlstring ($) {
    my ($l)=@_;
    list2string
      cons ("'",
	    list_fold_right sub {
		my ($c,$rest)= @_;
		my $out= cons ($c, $rest);
		if ($c eq "'") {
		    cons ("\\", $out)
		} else {
		    $out
		}
	    }, cons("'",null), $l)
}


sub drop_while ($ $) {
    my ($pred,$l)=@_;
    while ($l and &$pred(car $l)) {
	$l=cdr $l;
    }
    $l
}

TEST { list2string drop_while (sub{$_[0] ne 'X'}, string2list "Hello World") }
  "";

TEST { list2string drop_while (sub{$_[0] ne 'o'}, string2list "Hello World") }
  "o World";


sub rtake_while ($ $) {
    my ($pred,$l)=@_;
    my $res=null;
    my $c;
    while ($l and &$pred($c= car $l)) {
	$res= cons $c,$res;
	$l=cdr $l;
    }
    ($res,$l)
}

sub take_while ($ $) {
    my ($pred,$l)=@_;
    my ($rres,$rest)= rtake_while ($pred,$l);
    (list_reverse $rres,
     $rest)
}

TEST { list2string take_while (sub{$_[0] ne 'o'}, string2list "Hello World") }
  "Hell";

TEST { list2string take_while (sub{$_[0] eq 'o'}, string2list "Hello World") }
  "";


sub list_every ($ $) {
    my ($pred,$l)=@_;
  LP: {
	if (is_pair $l) {
	    (&$pred (car $l)) and do {
		$l= cdr $l;
		redo LP;
	    }
	} elsif (is_null $l) {
	    1
	} else {
	    # improper list
	    # (XX check value instead? But that would be improper_every.)
	    #0
	    die "improper list"
	}
    }
}

TEST { [ map { list_every sub{$_[0]>0}, $_ }
	 list (1,2,3),
	 list (1,0,3) ] }
  [1, ''];


sub list_any ($ $) {
    my ($pred,$l)=@_;
  LP: {
	if (is_pair $l) {
	    (&$pred (car $l)) or do {
		$l= cdr $l;
		redo LP;
	    }
	} elsif (is_null $l) {
	    0
	} else {
	    die "improper list"
	}
    }
}

TEST{ list_any sub { $_[0] % 2 }, array2list [2,4,8] }
  0;
TEST{ list_any sub { $_[0] % 2 }, array2list [] }
  0;
TEST{ list_any sub { $_[0] % 2 }, array2list [2,5,8]}
  1;
TEST{ list_any sub { $_[0] % 2 }, array2list [7] }
  1;



# Turn a mix of (nested) arrays and lists into a flat list.

# If the third argument is given, it needs to be a reference to either
# lazy or lazyLight. In that case it will force promises, but only
# lazily (i.e. provide a promise that will do the forcing and consing).

sub mixed_flatten ($;$$);
sub mixed_flatten ($;$$) {
    my ($v,$maybe_tail,$maybe_delay)=@_;
    my $tail= $maybe_tail//null;
  LP: {
	if ($maybe_delay and is_promise $v) {
	    my $delay= $maybe_delay;
	    &$delay
	      (sub {
		   @_=(force($v), $tail, $delay); goto \&mixed_flatten;
	       });
	} else {
	    if (is_null $v) {
		$tail
	    } elsif (is_pair $v) {
		no warnings 'recursion';
		$tail= mixed_flatten (cdr $v, $tail, $maybe_delay);
		$v= car $v;
		redo LP;
	    } elsif (ref $v eq "ARRAY") {
		@_= (sub {
			 @_==2 or die;
			 my ($v,$tail)=@_;
			 no warnings 'recursion';
			 # ^XX don't understand why it warns here
			 @_=($v,$tail,$maybe_delay); goto \&mixed_flatten;
		     },
		     $tail,
		     $v);
		require Chj::FP::Stream; # XX ugly? de-circularize?
		goto ($maybe_delay
		      ? \&Chj::FP::Stream::stream__array_fold_right
		      #^ XX just expecting it to be loaded
		      : \&array_fold_right);
	    } else {
		#warn "improper list: $v"; well that's part of the spec, man
		cons ($v, $tail)
	    }
	}
    }
}


use Chj::FP::Char 'is_char';

sub is_charlist ($) {
    my ($l)=@_;
    list_every \&is_char, $l
}

use Carp;

sub ldie {
    # perl string arguments are messages, char lists are turned to
    # perl-quoted strings, then everyting is appended
    my @strs= map {
	if (is_charlist $_) {
	    list2perlstring $_
	} elsif (is_null $_) {
	    "()"
	} else {
	    # XX have a better write_sexpr that can fall back to something
	    # better?, and anyway, need string
	    $_
	}
    } @_;
    croak join("",@strs)
}


use Chj::FP::Values 'fst';
use Chj::FP::Char 'char_is_alphanumeric';

TEST{ list_length string2list "ao" }
  2;
TEST{ list2string string2list "Hello" }
  'Hello';
TEST{ list2string list_reverse string2list "Hello" }
  'olleH';
TEST{ list2string list_reverse (fst rtake_while \&char_is_alphanumeric, string2list "Hello World") }
  'Hello';

TEST_STDOUT{ write_sexpr cons("123",cons("4",null)) }
  '("123" "4")';
TEST_STDOUT{ write_sexpr (string2list "Hello \"World\"")}
  '("H" "e" "l" "l" "o" " " "\"" "W" "o" "r" "l" "d" "\"")';
TEST_STDOUT{ write_sexpr (cons 1, 2) }
  '("1" . "2")';
#TEST_STDOUT{ write_sexpr cons(1, cons(cons(2, undef), undef))}
#  '';
# -> XX should print #f or something for undef ! Not give exception.
TEST_STDOUT { write_sexpr cons(1, cons(cons(2, null), null))}
  '("1" ("2"))';

TEST{ list_every \&char_is_alphanumeric, string2list "Hello" }
  1;
TEST{ list_every \&char_is_alphanumeric, string2list "Hello " }
  '';
TEST{ list2perlstring string2list  "Hello" }
  "'Hello'";
TEST{ list2perlstring string2list  "Hello's" }
  q{'Hello\'s'};

TEST{ [list2values string2list "abc"] }
  [
   'a',
   'b',
   'c'
  ];

TEST{ list2string array2list [1,2,3] }
  '123';
TEST{ list2array mixed_flatten [1,2,3] }
  [
   1,
   2,
   3
  ];
TEST{ list2array mixed_flatten [1,2,[3,4]] }
  [
   1,
   2,
   3,
   4
  ];
TEST{ list2array mixed_flatten [1,cons(2, [ string2list "ab" ,4])] }
  [
   1,
   2,
   'a',
   'b',
   4
  ];
TEST{ list2string mixed_flatten [string2list "abc", string2list "def", "ghi"] }
  'abcdefghi';  # only works thanks to perl chars and strings being the same datatype

TEST_STDOUT{ write_sexpr( mixed_flatten
			  lazyLight { cons(lazy { 1+1 }, null)},
			  undef,
			  \&lazyLight) }
  '("2")';
TEST_STDOUT{ write_sexpr( mixed_flatten
			  lazyLight { cons(lazy { [1+1,lazy {2+1}] }, null) },
			  undef,
			  \&lazyLight) }
  '("2" "3")';

TEST_STDOUT{
    sub countdown {
	my ($i)=@_;
	if ($i) {
	    lazyLight {cons ($i, countdown($i-1))}
	} else {
	    null
	}
    }
    write_sexpr ( mixed_flatten
		  lazyLight { cons(lazy { [1+1,countdown 10] }, null)},
		  undef,
		  \&lazyLight)
}
  '("2" "10" "9" "8" "7" "6" "5" "4" "3" "2" "1")';

TEST{ list2array  Chj::FP::List::array_fold_right \&cons, null, [1,2,3] }
  [
   1,
   2,
   3
  ];

TEST_STDOUT{ write_sexpr
	       (mixed_flatten
		[lazyLight { [3,[9,10]]}],
		undef,
		\&lazyLight ) }
    '("3" "9" "10")';
TEST_STDOUT { write_sexpr
		(mixed_flatten
		 [1,2, lazyLight { [3,9]}],
		 undef,
		 \&lazyLight) }
    '("1" "2" "3" "9")';

TEST{ list2array  list_append (array2list (["a","b"]), array2list([1,2])) }
  [
   'a',
   'b',
   1,
   2
  ];


1
