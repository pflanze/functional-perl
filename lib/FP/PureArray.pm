#
# Copyright (c) 2015-2019 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FP::PureArray

=head1 SYNOPSIS

    use FP::PureArray;
    use FP::Div 'inc';

    is purearray(1,4,5)->map(*inc)->sum, 13;

=head1 DESCRIPTION

Perl arrays blessed into the `FP::PureArray` package, inheriting from
`FP::Abstract::Pure`, and coming with the functions from `FP::Array` as methods.

If you hand someone an FP::PureArray you guarantee that you won't
mutate it. This might be enforced in the future by making them
immutable (todo).

=head1 PURITY

`PureArray`s are created to be immutable by default, which enforces
the functional purity of the API. This can be disabled by setting
`$FP::PureArray::immutable` to false when creating them. Only ever use
this during development, if at all. If you need to have efficient
updates, use another data structure (L<FP::List> suits many cases, or
the to-be written L<FP::Vec>, although at that point updates directly
on PureArray may be implemented efficiently, too). Or if you're sure
making a PureArray mutable again is safe, you can call the
`unsafe_mutable` method. Should lexical analysis get implemented in
Perl at some point, a method `mutable` could be offered that safely
(by way of checking via the reference count that there are no other
users) turns a PureArray back into a mutable array. Currently the
class `FP::MutableArray` is used but it is (TODO) planned to use
`FP::Array` for that (and remodel the existing module of the same name
to suit this).

PureArray implements `FP::Abstract::Pure` (`is_pure` from
`FP::Predicates` returns true even if instances were made mutable via
setting `$FP::PureArray::immutable`). Values returned from
`unsafe_mutable` are in a different class which does *not* implement
`FP::Abstract::Pure`.

=head1 TODO

Create alternative implementation that is efficient for updates on big
arrays (perhaps to be called FP::Vec, but to be interoperable).

=head1 SEE ALSO

Implements: L<FP::Abstract::Sequence>.

=cut


package FP::PureArray;

#@ISA="Exporter"; require Exporter; see hack below

@EXPORT=qw(is_purearray purearray array_to_purearray unsafe_array_to_purearray);
# or optional export only?
@EXPORT_OK=qw();
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict; use warnings; use warnings FATAL => 'uninitialized';

use Chj::TEST;

use FP::Array ":all";
use FP::Array_sort "array_sort";
use FP::Combinators qw (flip flip2of3 rot3right rot3left);
use FP::Div 'inc';
use FP::Predicates 'is_pure';
use FP::Optional qw(perhaps_to_maybe);


our $immutable= 1; # whether new instances are to be immutable

sub purebless ($$) {
    my ($a, $class)=@_;
    bless $a, $class;
    if ($immutable) {
        Internals::SvREADONLY $_, 1
            for @$a;
        Internals::SvREADONLY @$a, 1;
    }
    $a
}


sub blessing ($) {
    my ($m)= @_;
    sub {
        my $class=ref $_[0];
        if (my ($v)= &$m (@_)) {
            purebless $v, $class
        } else {
            ()
        }
    }
}

sub blessing_snd ($) {
    my ($m)= @_;
    sub {
        my $class=ref $_[0];
        wantarray ? do {
            my ($v,$a)= &$m (@_);
            ($v, purebless $a, $class)
        }
          : purebless &$m (@_), $class;
    }
}

use Chj::NamespaceCleanAbove;

sub is_purearray ($) {
    length ref ($_[0]) and UNIVERSAL::isa($_[0], "FP::PureArray")
}

sub purearray {
    purebless [@_], "FP::PureArray"
}

sub array_to_purearray ($) {
    purebless [@{$_[0]}], "FP::PureArray"
}

sub unsafe_array_to_purearray ($) {
    purebless $_[0], "FP::PureArray"
}


# EXPORT HACK
# to make it possible to use this package both for OO and exports
require Exporter;
*import= *Exporter::import; # needs to stay around as a method, can't
                            # be cleaned. Did I say this is a hack?

# ---- Methods ---------------------------------------------------

use FP::Interfaces;

# de-import array from FP::Array to avoid redefinition warning
BEGIN {undef *array }

# for FP::Show
sub FP_Show_show {
    my ($s,$show)=@_;
    "purearray(".join(", ", @{array_map($show,$s)}).")"
}

sub array {
    @_==1 or die "wrong number of arguments";
    my $s=shift;
    # 'debless', and copy necessary as the user is entitled to mod it
    # now. (XX: might optimize if only reference left by checking the
    # refcount)
    [@$s]
}

sub list {
    @_==1 or die "wrong number of arguments";
    my $s=shift;
    require FP::List; # (overhead of repeated require?)
    FP::List::array_to_list ($s)
}

sub stream {
    @_==1 or die "wrong number of arguments";
    my $s=shift;
    require FP::Stream; # (dito)
    FP::Stream::array_to_stream ($s)
}


# emptyness constructor that works for subclassing (using singletons
# for performance (perhaps), and, well, perhaps more so to punish
# people who hijack purearrays; might teach them!, so they will do the
# right thing even if PureArray doesn't make arrays readonly (yet))
my %empties;
sub empty {
    my $proto=shift;
    my $cl= ref($proto) || $proto;
    $empties{$cl} ||= purebless [], $cl
}

sub is_null {
    @_==1 or die "wrong number of arguments";
    not @{$_[0]}
}
# Do *not* provide `is_pair`, though, since this is not a pair based
# data structure? Or is the `is_null` already evil because of this and
# should be named `is_empty`?

sub values {
    @{$_[0]}
}


*cons= flip \&FP::List::pair;
*first= \&array_first;
*maybe_first= \&array_maybe_first;
*perhaps_first= \&array_perhaps_first;
*rest= blessing \&array_rest;
*maybe_rest= blessing \&array_maybe_rest;
*perhaps_rest= blessing \&array_perhaps_rest;
sub first_and_rest {
    @_==1 or die "wrong number of arguments";
    my ($a)= @_;
    (array_first $a,
     purebless array_rest($a), ref $a)
}
# XXX ah could have used blessing_snd ^ v
sub maybe_first_and_rest {
    @_==1 or die "wrong number of arguments";
    my ($a)= @_;
    @$a ? 
        (array_first $a,
         purebless array_rest($a), ref $a)
        : undef
}
sub perhaps_first_and_rest {
    @_==1 or die "wrong number of arguments";
    my ($a)= @_;
    @$a ? 
        (array_first $a,
         purebless array_rest($a), ref $a)
        : ()
}
*second= \&array_second;
*last= \&array_last;
*ref= \&array_ref;
*FP_Sequence_ref=*ref;
*length= \&array_length;
sub FP_Sequence_length {
    my ($self,$prefixlen)=@_;
    $prefixlen + $self->length
}
*set= blessing \&array_set;
*update= blessing \&array_update;
*push= blessing \&array_push;
*pop= blessing_snd \&array_pop;
*shift= blessing_snd \&array_shift;
*unshift= blessing \&array_unshift;
*sub= blessing \&array_sub;
*take= blessing \&array_take;
*drop= blessing \&array_drop;
*drop_while= blessing \&array_drop_while;
*take_while= blessing \&array_take_while;
*append= blessing \&array_append;
*reverse= blessing \&array_reverse;
*xone= \&array_xone;
*perhaps_one= \&array_perhaps_one;
*hashing_uniq= blessing \&array_hashing_uniq;
*zip2= blessing \&array_zip2;
*for_each= flip \&array_for_each;
*map= blessing flip \&array_map;
*map_with_i= blessing flip \&array_map_with_i;
*map_with_islast= blessing flip \&array_map_with_islast;
*filter= blessing flip \&array_filter;
*zip= blessing \&array_zip;
*fold= rot3left \&array_fold;
*fold_right= rot3left \&array_fold_right;
*preferred_fold= *fold; # ?
*join= blessing \&array_join;
*strings_join= \&array_strings_join;
*every= flip \&array_every;
*any= flip \&array_any;
*sum= \&array_sum;
*hash_group_by= \&array_to_hash_group_by;

*sort= blessing \&array_sort;

# XX provide them as functions, too? (prefixed with `purearray_`) (to
# avoid requiring the user to use `the_method` [and perhaps missing
# the explicit type check?])


# --- Tests ------------------------------------------------------

TEST {
    is_pure (purearray (4,5))
}
  1;

TEST {
    my $try= sub { # already have TEST_EXCEPTION, but this allows it
                   # inline
        my ($th)=@_;
        my $res;
        eval { $res= $th->(); 1 } ? $res
            : do {
                my $e= "$@";
                $e=~ s/ at .*//s;
                $e
        }
    };
    my $a= purearray (1,4,5);
    my $a2= $a->set (2,7)->set (0,-1);
    my $a3= $a2->update (2,*inc);
    my $a4= $a3->push (9,99)->unshift (77);
    my ($p,$a5)= $a4->pop;
    my ($s,undef)= $a4->shift;
    my $a6= $a4->shift;
    [$a->ref (2), $a2->array, $a3->array, $a4->length,
     $p, $a5->[-1], $s, $a6->array,
     &$try(sub { $a5->ref(-1) })]
}
  [ 5, [-1,4,7], [-1,4,8], 6,
    99, 9, 77, [-1,4,8,9,99],
    'index out of bounds: -1' ];

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

TEST { array_to_purearray ([1,2,20])->map_with_islast (sub { $_[0] })->array }
  [ '','',1 ];

TEST{ purearray(3,4)->fold (sub{[@_]}, 's') }
  [4, [3,'s']];

TEST { (purearray 3,4)->zip([qw(a b c)]) }
  bless [[3,"a"], [4,"b"]], 'FP::PureArray';

TEST { (purearray 2,3)->join("a") }
  bless [2, "a", 3], 'FP::PureArray';

TEST{ purearray(1,2,3)->strings_join("-") }
  "1-2-3";

TEST{ (purearray 1, 2, 3)->every (sub { ($_[0] % 2) == 0 }) }
  0;
TEST{ (purearray 7)->any (sub { $_[0] % 2 }) }
  1;

TEST {(purearray ["a",1], ["b",2], ["a",4])
        ->hash_group_by (*array_first) }
  {'a'=>[['a',1],['a',4]],'b'=>[['b',2]]};

TEST { purearray (3)->xone } 3;
TEST_EXCEPTION { purearray (3,4)->xone } 'expecting 1 element, got 2';

TEST { purearray (1,3)->append (purearray (4,5)->reverse)->array }
  [1,3,5,4];

TEST_STDOUT {
    require Chj::xperlfunc;
    purearray(1,3)->for_each (\&Chj::xperlfunc::xprintln)
} "1\n3\n";


TEST { require FP::Ops;
       purearray (5,3,8,4)->sort (\&FP::Ops::number_cmp)->array }
  [3,4,5,8];


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

TEST { purearray (1,2,3)->set(2,"a") } purearray(1, 2, 'a');
TEST { purearray (1,2,7,3,6)->filter(sub { $_[0] > 5 }) } purearray (7,6);


TEST { purearray(3,4)->append(purearray (5,6),purearray (7)) }
  purearray 3,4,5,6,7;
TEST { purearray(3,4)->append(FP::List::list (5,6),purearray (7)) }
  purearray 3,4,5,6,7;


*perhaps_find_tail= blessing flip \&array_perhaps_find_tail;
*perhaps_find= flip \&array_perhaps_find;
*find= perhaps_to_maybe (\&array_perhaps_find);



FP::Interfaces::implemented qw(FP::Abstract::Sequence);
# XX: ah, and 'FP::Array' as well, this is an array, ok? But then
# actually move all the method setup below to FP::Array, too. But the
# current FP::Array is not a class, this will have to change first.

_END_
