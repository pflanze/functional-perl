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

=cut


package FP::PureArray;
#@ISA="Exporter"; require Exporter; see hack below
@EXPORT=qw(purearray array2purearray); # or optional export only?
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
	bless &$m (@_), "FP::PureArray"
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


*fst= \&array_fst;
*first= \&array_fst;
*snd= \&array_snd;
*second= \&array_second;
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

_END_
