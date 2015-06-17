#
# Copyright 2015 by Christian Jaeger, ch at christianjaeger ch
# Published under the same terms as perl itself
#

=head1 NAME

FP::PureArray

=head1 SYNOPSIS

 purearray (1,4,5)->map (*inc)->sum  # returns 13

=head1 DESCRIPTION

Perl arrays blessed into the `FP::PureArray` package, inheriting from
`FP::Pure`, and coming with the functions from `FP::Array` as methods.

If you hand someone an FP::PureArray you guarantee that you won't
mutate it. This might be enforced in the future by making them
immutable (todo).

=head1 TODO

Write alternative implementation that is efficient for updates on big
arrays.

=cut


package FP::PureArray;
#@ISA="Exporter"; require Exporter; see hack below
@EXPORT=qw(purearray array2purearray unsafe_array2purearray); # or optional export only?
@EXPORT_OK=qw();
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict; use warnings FATAL => 'uninitialized';

use Chj::TEST;

use FP::Array ":all";
use FP::Combinators qw (flip flip2_3 rot3right rot3left);
use FP::Div 'inc';
use FP::Predicates 'is_pure';

sub blessing ($) {
    my ($m)= @_;
    sub {
	my $class=ref $_[0];
	bless &$m (@_), $class
    }
}

sub blessing_snd ($) {
    my ($m)= @_;
    sub {
	my $class=ref $_[0];
	wantarray ? do {
	    my ($v,$a)= &$m (@_);
	    ($v, bless $a, $class)
	}
	  : bless &$m (@_), $class;
    }
}

use Chj::NamespaceCleanAbove;

sub purearray {
    bless [@_], "FP::PureArray"
}

sub array2purearray ($) {
    # XX assume it, and turn on readonly flag instead of copying?
    bless [@{$_[0]}], "FP::PureArray"
}

sub unsafe_array2purearray ($) {
    # XX turn on readonly flag?
    bless $_[0], "FP::PureArray"
}


# EXPORT HACK
# to make it possible to use this package both for OO and exports
require Exporter;
*import= *Exporter::import; # needs to stay around as a method, can't
                            # be cleaned. Did I say this is a hack?

# ---- Methods ---------------------------------------------------

use base 'FP::Pure';
# XX: ah, and 'FP::Array' as well, this is an array, ok? But then
# actually move all the method setup below to FP::Array, too. But the
# current FP::Array is not a class, this will have to change first.

# de-import array from FP::Array to avoid redefinition warning
BEGIN {undef *array }

sub array {
    my $s=shift;
    # 'debless', and copy necessary as the user is entitled to mod it
    # now. (XX: might optimize if only reference left by checking the
    # refcount)
    [@$s]
}

# emptyness constructor that works for subclassing (using singletons
# for performance (perhaps), and, well, perhaps more so to punish
# people who hijack purearrays; might teach them!, so they will do the
# right thing even if PureArray doesn't make arrays readonly (yet))
my %empties;
sub empty {
    my $cl=shift;
    $empties{$cl} ||= bless [], $cl
}


*fst= \&array_fst;
*first= \&array_fst;
*snd= \&array_snd;
*second= \&array_second;
*ref= \&array_ref;
*length= \&array_length;
*set= blessing \&array_set;
*update= blessing \&array_update;
*push= blessing \&array_push;
*pop= blessing_snd \&array_pop;
*shift= blessing_snd \&array_shift;
*unshift= blessing \&array_unshift;
*sub= blessing \&array_sub;
*append= blessing \&array_append;
*reverse= blessing \&array_reverse;
*xone= \&array_xone;
*hashing_uniq= blessing \&array_hashing_uniq;
*zip2= blessing \&array_zip2;
*for_each= flip \&array_for_each;
*map= blessing flip \&array_map;
*map_with_i= blessing flip \&array_map_with_i;
*map_with_islast= blessing flip \&array_map_with_islast;
*filter= blessing \&array_filter;
*zip= blessing \&array_zip;
*fold= rot3left \&array_fold;
*join= blessing \&array_join;
*every= flip \&array_every;
*any= flip \&array_any;
*sum= \&array_sum;
*rest= blessing \&array_rest;
*hash_group_by= \&array2hash_group_by;

# XX provide them as functions, too? (prefixed with `purearray_`) (to
# avoid requiring the user to use `the_method` [and perhaps missing
# the explicit type check?])


# --- Tests ------------------------------------------------------

TEST {
    is_pure (purearray (4,5))
}
  1;

TEST {
    my $a= purearray (1,4,5);
    my $a2= $a->set (2,7)->set (0,-1);
    my $a3= $a2->update (2,*inc);
    my $a4= $a3->push (9,99)->unshift (77);
    my ($p,$a5)= $a4->pop;
    my ($s,undef)= $a4->shift;
    my $a6= $a4->shift;
    [$a->ref (2), $a2->array, $a3->array, $a4->length,
     $p, $a5->ref(-1), $s, $a6->array]
}
  [ 5, [-1,4,7], [-1,4,8], 6,
    99, 9, 77, [-1,4,8,9,99] ];

TEST {
    my $a= purearray (1,4,5,7);
    my @a= ($a->sub (0,2),
	    $a->sub (1,3));
    push @a, $a->sub (2,4);
    # throw out of range errors or what?
    push @a, $a->sub (3,5);
    # XX and what about negative positions?
    push @a, $a->sub (-1,1);
    # XX and about this case? Should this be an error, or revert the
    # range, or?
    push @a, $a->sub (3,1);

    array_map sub{$_[0]->array}, \@a
}
  [[1,4], [4,5], [5,7], [7,undef], [7,1], []];

TEST {
    purearray (1,4,5)->map (*inc)->sum
}
  13;

TEST {
    purearray (3,4,5)->rest->map_with_i (sub{[@_]})
}
  bless [[0,4], [1,5]], 'FP::PureArray';

TEST { array2purearray ([1,2,20])->map_with_islast (sub { $_[0] })->array }
  [ '','',1 ];

TEST{ purearray(3,4)->fold (sub{[@_]}, 's') }
  [4, [3,'s']];

TEST { (purearray 3,4)->zip([qw(a b c)]) }
  bless [[3,"a"], [4,"b"]], 'FP::PureArray';

TEST { (purearray 2,3)->join("a") }
  bless [2, "a", 3], 'FP::PureArray';

TEST{ (purearray 1, 2, 3)->every (sub { ($_[0] % 2) == 0 }) }
  0;
TEST{ (purearray 7)->any (sub { $_[0] % 2 }) }
  1;

TEST {(purearray ["a",1], ["b",2], ["a",4])
	->hash_group_by (*array_fst) }
  {'a'=>[['a',1],['a',4]],'b'=>[['b',2]]};

TEST { purearray (3)->xone } 3;
TEST_EXCEPTION { purearray (3,4)->xone } 'expecting 1 element, got 2';

TEST { purearray (1,3)->append (purearray (4,5)->reverse)->array }
  [1,3,5,4];

TEST_STDOUT {
    require Chj::xIO;
    purearray(1,3)->for_each (*Chj::xIO::xprintln)
} "1\n3\n";


# subclassing

{
    package FP::PureArray::_Test;
    our @ISA= 'FP::PureArray'
}

TEST {
    my $empty= FP::PureArray::_Test->empty;
    $empty->set (1,5)
}
  bless [undef, 5], 'FP::PureArray::_Test';


_END_
