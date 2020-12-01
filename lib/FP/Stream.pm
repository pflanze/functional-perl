#
# Copyright (c) 2013-2020 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FP::Stream - lazily generated, singly linked (purely functional) lists

=head1 SYNOPSIS

    use FP::Equal 'is_equal';
    use FP::Stream ':all';

    is stream_length(stream_iota 101, 5), 5;
    #is stream_length(stream_iota 0, 5000000), 5000000;

    use FP::Lazy; # force
    is force( stream_fold_right sub { my ($n,$rest) = @_;
                                      $n + force $rest },
                                0,
                                stream_iota 0, 5),
       10;

Alternatively (and probably preferably), use methods:

    is stream_iota(101, 5)->length, 5;
    # note that length needs to walk the whole stream

    is stream_iota->map(sub{ $_[0]*$_[0]})->take(5)->sum,
       0+1+4+9+16;

    is stream_iota(0, 5)->fold(sub { my ($n,$rest) = @_;
                                     $n + $rest },
                               0),
       10;

NOTE that the method calls are forcing evaluation of the object (the
first cell of the input stream), since that's the only way to know the
type to be dispatched on. This is unlike the non-generic functions,
some of which (like cons) don't force evaluation of their arguments.

=head1 DESCRIPTION

`FP::Stream`s (from now on called "streams") are the same as
`FP::List`s (from now on called "lists") except that their cells are
generated on demand. If your code has got a list in a particular point
in time, all the items in the list are calculated already, and the
list takes as much space in memory to represent all of the values. A
stream on the other hand, at the beginning consists of only a single
unevaluated promise, which is an object from `FP::Lazy` which
represents a to-be done calculation to produce, surprise, a
`FP::List::Null` (end of list) value to indicate the end or a
`FP::List::Pair` which holds the first value and the remainder of the
sequence--itself again a stream, or more precisely a promise to either
a null or pair value.

So, like a list, a stream is a recursive data structure, with the only
difference that the rest field in pairs is a promise. It also
automatically "inherits" all of the list methods, since calling a
method on a promise is forcing the promise and then is delegated to
the generated value; although delegation goes to the method with
"stream_" prefixed, if it exists--this is to allow for overrides if a
method on a stream needs to behave differently. For example `map` is
overridden with `stream_map` which produces the resulting linked list
lazily:

    use FP::Div 'inc'; use FP::List 'list';

    is ref( list(30, 60)->map(*inc) ),
       'FP::List::Pair';
    is ref( list(30, 60)->stream_map(*inc) ),
       'FP::Lazy::Promise';
    is ref( stream(30, 60)->map(*inc) ),
       'FP::Lazy::Promise';
    is ref( stream(30, 60)->stream_map(*inc) ),
       'FP::Lazy::Promise';

    is ref(force( stream(30, 60)->map(*inc) )),
       'FP::List::Pair';

All of the examples evaluate to the same values--the result isn't
different, it's just calculated lazily (on demand) in some cases. The
`equal` calls in the following are all true even though the second
argument is always an eager list (whereas the first argument is a
stream in 3 out of 4 cases) because `equal` automatically forces the
evaluation of promises it encounters.

    use FP::Equal 'equal';

    ok equal(list(30, 60)->map(*inc), list(31, 61));
    ok equal(list(30, 60)->stream_map(*inc), list(31, 61));
    ok equal(stream(30, 60)->map(*inc), list(31, 61));
    ok equal(stream(30, 60)->stream_map(*inc), list(31, 61));

=head1 SEE ALSO

The general functional perl documentation.

L<FP::List>, L<FP::Lazy>

=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut

package FP::Stream;
use strict;
use warnings;
use warnings FATAL => 'uninitialized';
use Exporter "import";

our @EXPORT = qw(
    is_null
    Keep
    Weakened
    stream_iota
    stream_range
    stream_step_range
    stream_length
    stream_append
    stream_map
    stream_map_with_tail
    stream_filter
    stream_filter_with_tail
    stream_fold
    stream_foldr1
    stream_fold_right
    stream_state_fold_right
    stream__array_fold_right
    stream__string_fold_right
    stream__subarray_fold_right stream__subarray_fold_right_reverse
    stream_sum
    array_to_stream stream
    subarray_to_stream subarray_to_stream_reverse
    string_to_stream
    stream_to_string
    stream_strings_join
    stream_for_each
    stream_drop
    stream_take
    stream_take_while
    stream_slice
    stream_drop_while
    stream_ref
    stream_zip2
    stream_zip
    stream_zip_with
    stream_to_array
    stream_to_purearray
    stream_to_list
    stream_sort
    stream_group
    stream_mixed_flatten
    stream_mixed_fold_right
    stream_mixed_state_fold_right
    stream_any
    stream_show
);
our @EXPORT_OK = qw(
    F weaken
    cons car cdr first rest
    stream_cartesian_product
    stream_cartesian_product_2
);
our %EXPORT_TAGS = (all => [@EXPORT, @EXPORT_OK]);

use FP::Lazy;
use FP::List ":all";
use FP::Combinators qw(flip flip2of3 rot3right rot3left);
use Chj::TEST;
use FP::Weak;
use FP::Predicates 'is_natural0';
use FP::Show;
use FP::fix;
use Carp;
use FP::Carp;

sub stream_iota {
    @_ <= 2 or fp_croak_arity 2;
    my ($maybe_start, $maybe_n) = @_;
    my $start = $maybe_start // 0;
    if (defined $maybe_n) {
        my $end = $start + $maybe_n;
        my $rec;
        $rec = sub {
            my ($i) = @_;
            my $rec = $rec;
            lazy {
                if ($i < $end) {
                    cons($i, &$rec($i + 1))
                } else {
                    null
                }
            }
        };
        @_ = ($start);
        goto &{ Weakened $rec};
    } else {
        my $rec;
        $rec = sub {
            my ($i) = @_;
            my $rec = $rec;
            lazy {
                cons($i, &$rec($i + 1))
            }
        };
        @_ = ($start);
        goto &{ Weakened $rec};
    }
}

# Like perl's `..`
sub stream_range {
    @_ <= 2 or fp_croak_arity 2;
    my ($maybe_start, $maybe_end) = @_;
    my $start = $maybe_start // 0;
    stream_iota($start, defined $maybe_end ? $maybe_end + 1 - $start : undef);
}

TEST { stream_range(2, 4)->array }
[2, 3, 4];
TEST { stream_range(2, 2)->array }
[2];
TEST { stream_range(2, 1)->array }
[];

sub stream_step_range {
    (@_ >= 1 and @_ <= 3) or fp_croak_arity "1-3";
    my ($step, $maybe_start, $maybe_end) = @_;
    my $start   = $maybe_start // 0;
    my $inverse = $step < 0;
    if (defined $maybe_end) {
        my $end = $maybe_end;
        my $rec;
        $rec = sub {
            my ($i) = @_;
            my $rec = $rec;
            lazy {
                if ($inverse ? $i >= $end : $i <= $end) {
                    cons($i, &$rec($i + $step))
                } else {
                    null
                }
            }
        };
        @_ = ($start);
        goto &{ Weakened $rec};
    } else {
        my $rec;
        $rec = sub {
            my ($i) = @_;
            my $rec = $rec;
            lazy {
                cons($i, &$rec($i + $step))
            }
        };
        @_ = ($start);
        goto &{ Weakened $rec};
    }
}

TEST { stream_step_range(-1)->take(4)->array }
[0, -1, -2, -3];
TEST { stream_step_range(2, 3, 6)->array }
[3, 5];
TEST { stream_step_range(2, 3, 7)->array }
[3, 5, 7];
TEST { stream_step_range(-1, 3, 1)->array }
[3, 2, 1];

sub stream_length;
*stream_length = FP::List::make_length(1);

*FP::List::List::stream_length = *stream_length;

TEST {
    my $s = stream_iota->take(10);
    my $l = $s->length;
    [$l, $s]
}
[10, undef];

# left fold, sometimes called `foldl` (or with changes, `reduce`,
# which is defined in FP::Abstract::Sequence)

# All functional languages seem to agree that right fold should pass
# the state argument as the second argument (to the right) to the
# build function (i.e. f(element,state)). But they don't when it comes
# to left fold: Scheme (SRFI-1) still calls f(element,state), whereas
# Haskell and Ocaml call f(state,element), perhaps according to the
# logic that both the walking order (which element of the list should
# be combined with the original state first?) and the argument order
# should be flipped, perhaps to try make them visually accordant. But
# then Ocaml also flips the start and input argument order in
# `fold_left`, so this one is different anyway. And Clojure calls it
# `reduce`, and has a special case when only two arguments are
# provided. Kinda hopeless?

# The author of this library decided to stay with the Scheme
# tradition: it seems to make sense to keep the argument order the
# same (as determined by the type of the arguments) for both kinds of
# fold. If nothing more this allows `*cons` to be passed as $fn
# directly to construct a list.

sub stream_fold {
    @_ == 3 or fp_croak_arity 3;
    my ($fn, $start, $l) = @_;
    weaken $_[2];
    my $v;
LP: {
        $l = force $l;
        if (is_pair $l) {
            ($v, $l) = first_and_rest $l;
            $start = &$fn($v, $start);
            redo LP;
        }
    }
    $start
}

*FP::List::List::stream_fold = rot3left \&stream_fold;

TEST {
    stream_fold sub { $_[0] + $_[1] }, 5, stream_iota(10, 2)
}
5 + 10 + 11;

# and actually argument order dependent tests:

TEST {
    stream_fold sub { [@_] }, 0, stream(1, 2)
}
[2, [1, 0]];

TEST { stream_fold(\&cons, null, stream(1, 2))->array }
[2, 1];

sub stream_sum {
    @_ == 1 or fp_croak_arity 1;
    my ($s) = @_;
    weaken $_[0];
    stream_fold(sub { $_[0] + $_[1] }, 0, $s)
}

# XXX sum is in FP::Abstract::Sequence now, although not weakening.. soo ?
*FP::List::List::stream_sum = *stream_sum;

TEST {
    stream_iota->map(sub { $_[0] * $_[0] })->take(5)->sum
}
30;

# leak test:  XXX make this into a LEAK_TEST or so form(s), and env var, ok?
#TEST{ stream_iota->rest->take(100000)->sum }
#  5000050000;

sub stream_append2 {
    @_ == 2 or fp_croak_arity 2;
    my ($l1, $l2) = @_;
    weaken $_[0];
    weaken $_[1];
    lazy {
        $l1 = force $l1;
        is_null($l1) ? $l2 : cons(car($l1), stream_append(cdr($l1), $l2))
    }
}

sub stream_append {
    if (@_ == 0) {
        null
    } elsif (@_ == 1) {
        $_[0]
    } elsif (@_ == 2) {
        goto \&stream_append2
    } else {
        my $ss = list(reverse @_);
        weaken $_ for @_;

        # ^ WHEN is this even needed, I think it is when calling a
        # stream consumer afterwards, right?
        $ss->rest->fold(
            sub {
                my ($s, $rest) = @_;
                lazy {
                    stream_append2($s, $rest)
                }
            },
            $ss->first
        )
    }
}

*FP::List::List::stream_append = *stream_append;

TEST {
    stream_to_string(stream_append string_to_stream("Hello"),
        string_to_stream(" World"))
}
'Hello World';

# F is defined further down, thus call with parens
TEST  { F(stream_append list(qw(a b)), list(qw(c d)), list(qw(e f))) }
GIVES { list('a', 'b', 'c', 'd', 'e', 'f') };
TEST  { F(stream_append list(qw(a b)), list(qw(c d))) }
GIVES { list('a', 'b', 'c', 'd') };
TEST  { F(stream_append list(qw(a b))) }
GIVES { list('a', 'b') };
TEST  { F(stream_append) }
list();

TEST {
    my @a;
    my $s = stream_append(
        lazy { push @a, "a"; list(qw(a b)) },
        lazy { push @a, "b"; list(qw(c d)) },
        lazy { push @a, "c"; list(qw(e f)) }
    );
    my @r;
    F(Keep($s)->take(1));
    push @r, ["take 1", @a];
    F(Keep($s)->take(2));
    push @r, ["take 2", @a];
    F(Keep($s)->take(3));
    push @r, ["take 3", @a];
    F(Keep($s)->take(4));
    push @r, ["take 4", @a];
    F(Keep($s)->take(5));
    push @r, ["take 5", @a];
    F(Keep($s)->take(6));
    push @r, ["take 6", @a];
    \@r
}
[
    ["take 1", "a"],
    ["take 2", "a"],
    ["take 3", "a", "b"],
    ["take 4", "a", "b"],
    ["take 5", "a", "b", "c"],
    ["take 6", "a", "b", "c"]
];

sub stream_map {
    @_ == 2 or fp_croak_arity 2;
    my ($fn, $l) = @_;
    weaken $_[1];
    lazy {
        $l = force $l;
        is_null($l) ? null : cons(&$fn(car $l), stream_map($fn, cdr $l))
    }
}

*FP::List::List::stream_map = flip \&stream_map;

sub stream_map_with_tail {
    @_ == 3 or fp_croak_arity 3;
    my ($fn, $l, $tail) = @_;
    weaken $_[1];
    lazy {
        $l = force $l;
        is_null($l)
            ? $tail
            : cons(&$fn(car $l), stream_map_with_tail($fn, cdr($l), $tail))
    }
}

*FP::List::List::stream_map_with_tail = flip2of3 \&stream_map_with_tail;

# 2-ary (possibly slightly faster) version of stream_zip
sub stream_zip2 {
    @_ == 2 or fp_croak_arity 2;
    my ($l, $m) = @_;
    do { weaken $_ if is_promise $_ }
        for @_;    #needed?
    lazy {
        $l = force $l;
        $m = force $m;
        (is_null $l or is_null $m)
            ? null
            : cons([car($l), car($m)], stream_zip2(cdr($l), cdr($m)))
    }
}

*FP::List::List::stream_zip2 = *stream_zip2;

# n-ary version of stream_zip2
sub stream_zip {
    my @ps = @_;
    do { weaken $_ if is_promise $_ }
        for @_;    #needed?
    lazy {
        my @vs = map {
            my $v = force $_;
            is_null($v) ? return null : $v
        } @ps;
        my $a = [map { car $_ } @vs];
        my $b = stream_zip(map { cdr $_ } @vs);
        cons($a, $b)
    }
}

*FP::List::List::stream_zip = *stream_zip;    # XX fall back on zip2
                                              # for 2 arguments?

sub stream_zip_with {
    my ($f, $l1, $l2) = @_;
    weaken $_[1];
    weaken $_[2];
    lazy {
        my $l1 = force $l1;
        my $l2 = force $l2;
        (is_null $l1 or is_null $l2) ? null : cons &$f(car($l1), car($l2)),
            stream_zip_with($f, cdr($l1), cdr($l2))
    }
}

*FP::List::List::stream_zip_with = flip2of3 \&stream_zip_with;

sub stream_filter;
*stream_filter                 = FP::List::make_filter(1);
*FP::List::List::stream_filter = flip \&stream_filter;

sub stream_filter_with_tail;
*stream_filter_with_tail                 = FP::List::make_filter_with_tail(1);
*FP::List::List::stream_filter_with_tail = flip2of3 \&stream_filter_with_tail;

# http://hackage.haskell.org/package/base-4.7.0.2/docs/Prelude.html#v:foldr1

# foldr1 is a variant of foldr that has no starting value argument,
# and thus must be applied to non-empty lists.

sub stream_foldr1 {
    @_ == 2 or fp_croak_arity 2;
    my ($fn, $l) = @_;
    weaken $_[1];
    lazy {
        $l = force $l;
        if (is_pair $l) {
            &$fn(car($l), stream_foldr1($fn, cdr($l)))
        } elsif (is_null $l) {
            die "foldr1: reached end of list"
        } else {
            die "improper list: $l"
        }
    }
}

*FP::List::List::stream_foldr1 = flip \&stream_foldr1;

sub stream_fold_right {
    @_ == 3 or fp_croak_arity 3;
    my ($fn, $start, $l) = @_;
    weaken $_[2];
    lazy {
        $l = force $l;
        if (is_pair $l) {
            &$fn(car($l), stream_fold_right($fn, $start, cdr $l))
        } elsif (is_null $l) {
            $start
        } else {
            die "improper list: $l"
        }
    }
}

*FP::List::List::stream_fold_right = rot3left \&stream_fold_right;

*FP::List::List::stream_preferred_fold = *FP::List::List::stream_fold_right;

sub make_stream__fold_right {
    my ($length, $ref, $start, $d, $whileP) = @_;

    sub {
        @_ == 3 or fp_croak_arity 3;
        my ($fn, $tail, $a) = @_;
        my $len = &$length($a);
        my $rec;
        $rec = sub {
            my ($i) = @_;
            my $rec = $rec;
            lazy {
                if (&$whileP($i, $len)) {
                    &$fn(&$ref($a, $i), &$rec($i + $d))
                } else {
                    $tail
                }
            }
        };
        &{ Weakened $rec}($start)
    }
}

our $lt            = sub { $_[0] < $_[1] };
our $gt            = sub { $_[0] > $_[1] };
our $array_length  = sub { scalar @{ $_[0] } };
our $array_ref     = sub { $_[0][$_[1]] };
our $string_length = sub { length $_[0] };
our $string_ref    = sub { substr $_[0], $_[1], 1 };

sub stream__array_fold_right;
*stream__array_fold_right
    = make_stream__fold_right($array_length, $array_ref, 0, 1, $lt);

# XX export these array functions as methods to ARRAY library

sub stream__string_fold_right;
*stream__string_fold_right
    = make_stream__fold_right($string_length, $string_ref, 0, 1, $lt);

sub stream__subarray_fold_right {
    @_ == 5 or fp_croak_arity 5;
    my ($fn, $tail, $a, $start, $maybe_end) = @_;
    make_stream__fold_right($array_length, $array_ref, $start, 1,
        defined $maybe_end ? sub { $_[0] < $_[1] and $_[0] < $maybe_end } : $lt)
        ->($fn, $tail, $a);
}

sub stream__subarray_fold_right_reverse {
    @_ == 5 or fp_croak_arity 5;
    my ($fn, $tail, $a, $start, $maybe_end) = @_;
    make_stream__fold_right($array_length, $array_ref, $start, -1,
        defined $maybe_end
        ? sub { $_[0] >= 0 and $_[0] > $maybe_end }
        : sub { $_[0] >= 0 })->($fn, $tail, $a);
}

sub array_to_stream {
    @_ >= 1 and @_ <= 2 or fp_croak_arity "1-2";
    my ($a, $maybe_tail) = @_;
    stream__array_fold_right(*cons, $maybe_tail // null, $a)
}

sub stream {
    array_to_stream [@_]
}

sub subarray_to_stream {
    @_ >= 2 and @_ <= 4 or fp_croak_arity "2-4";
    my ($a, $start, $maybe_end, $maybe_tail) = @_;
    stream__subarray_fold_right(*cons, $maybe_tail // null,
        $a, $start, $maybe_end)
}

sub subarray_to_stream_reverse {
    @_ >= 2 and @_ <= 4 or fp_croak_arity "2-4";
    my ($a, $start, $maybe_end, $maybe_tail) = @_;
    stream__subarray_fold_right_reverse(*cons, $maybe_tail // null,
        $a, $start, $maybe_end)
}

sub string_to_stream {
    @_ >= 1 and @_ <= 2 or fp_croak_arity "1-2";
    my ($str, $maybe_tail) = @_;
    stream__string_fold_right(*cons, $maybe_tail // null, $str)
}

sub stream_to_string {
    @_ == 1 or fp_croak_arity 1;
    my ($l) = @_;
    weaken $_[0];
    my $str = "";
    while (($l = force $l), !is_null $l) {
        $str .= car $l;
        $l = cdr $l;
    }
    $str
}

*FP::List::List::stream_string = *stream_to_string;

TEST { stream("Ha", "ll", "o")->string } "Hallo";

sub stream_strings_join {
    @_ == 2 or fp_croak_arity 2;
    my ($l, $val) = @_;
    weaken $_[0];

    # XX can't I just use list_strings_join? no, the other way round
    # would work.

    # depend on FP::Array. Lazily, for depencency cycle?
    require FP::Array;
    FP::Array::array_strings_join(stream_to_array($l), $val);
}

*FP::List::List::stream_strings_join = *stream_strings_join;

TEST { stream(1, 2, 3)->strings_join("-") }
"1-2-3";

sub stream_for_each;
*stream_for_each = FP::List::make_for_each(1);

*FP::List::List::stream_for_each = flip \&stream_for_each;

sub stream_drop {
    @_ == 2 or fp_croak_arity 2;
    my ($s, $n) = @_;
    weaken $_[0];
    while ($n > 0) {
        $s = force $s;
        die "stream too short" if is_null $s;
        $s = cdr $s;
        $n--
    }
    $s
}

*FP::List::List::stream_drop = *stream_drop;

sub stream_take {
    @_ == 2 or fp_croak_arity 2;
    my ($s, $n) = @_;
    weaken $_[0];
    lazy {
        if ($n > 0) {
            $s = force $s;
            is_null($s) ? $s : cons(car($s), stream_take(cdr($s), $n - 1));
        } else {
            null
        }
    }
}

*FP::List::List::stream_take = *stream_take;

sub stream_take_while {
    @_ == 2 or fp_croak_arity 2;
    my ($fn, $s) = @_;
    weaken $_[1];
    lazy {
        $s = force $s;
        if (is_null $s) {
            null
        } else {
            my $a = car $s;
            if (&$fn($a)) {
                cons $a, stream_take_while($fn, cdr $s)
            } else {
                null
            }
        }
    }
}

*FP::List::List::stream_take_while = flip \&stream_take_while;

sub stream_slice {
    @_ == 2 or fp_croak_arity 2;
    my ($start, $end) = @_;
    weaken $_[0];
    weaken $_[1];
    $end = force $end;
    my $rec;
    $rec = sub {
        my ($s) = @_;
        weaken $_[0];
        my $rec = $rec;
        lazy {
            $s = force $s;
            if (is_null $s) {
                $s    # null
            } else {
                if ($s eq $end) {
                    null
                } else {
                    cons car($s), &$rec(cdr $s)
                }
            }
        }
    };
    @_ = ($start);
    goto &{ Weakened $rec};
}

*FP::List::List::stream_slice = *stream_slice;

# maybe call it `cut_at` instead?

sub stream_drop_while {
    @_ == 2 or fp_croak_arity 2;
    my ($pred, $s) = @_;
    weaken $_[1];
    lazy {
    LP: {
            $s = force $s;
            if (!is_null $s and &$pred(car $s)) {
                $s = cdr $s;
                redo LP;
            } else {
                $s
            }
        }
    }
}

*FP::List::List::stream_drop_while = flip \&stream_drop_while;

sub stream_ref;
*stream_ref                 = FP::List::make_ref(1);
*FP::List::List::stream_ref = *stream_ref;

sub exn (&) {
    @_ == 1 or fp_croak_arity 1;
    my ($thunk) = @_;
    eval { &$thunk(); '' } // do { $@ =~ /(.*?) at/; $1 }
}

sub t_ref {
    my ($list, $cons, $liststream) = @_;
    TEST {
        my $l  = &$list(qw(a b));
        my $il = &$cons("x", "y");
        [
            Keep($l)->ref(0), Keep($l)->ref(1), exn { Keep($l)->ref(-1) },
            exn { Keep($l)->ref(0.1) }, exn { Keep($l)->ref(2) },
            Keep($il)->ref(0),
            exn { Keep($il)->ref(1) }
        ]
    }
    [
        "a", "b",
        "invalid index: -1",
        "invalid index: '0.1'",
        "requested element 2 of $liststream of length 2",
        "x", "improper $liststream"
    ];
}

t_ref *list, *cons, "list";
t_ref *stream, sub {
    my ($a, $r) = @_;
    lazy { cons $a, $r }
}, "stream";

TEST { list_ref cons(0, stream(1, 2, 3)), 2 } 2;
TEST { stream_ref cons(0, stream(1, 2, 3)), 2 } 2;

# force everything deeply
sub F {
    @_ == 1 or fp_croak_arity 1;
    my ($v) = @_;

    #weaken $_[0]; since I usually use it interactively, and should
    # only be good for short sequences, better don't
    if (is_promise $v) {
        F(force $v);
    } else {
        if (length(my $r = ref $v)) {
            if (is_pair $v) {
                cons(F(car $v), F(cdr $v))
            } elsif (is_null $v) {
                $v
            } elsif ($r eq "ARRAY") {
                [map { F($_) } @$v]
            } elsif (UNIVERSAL::isa($v, "ARRAY")) {
                bless [map { F($_) } @$v], ref $v
            } else {
                $v
            }
        } else {
            $v
        }
    }
}

sub stream_to_array {
    @_ == 1 or fp_croak_arity 1;
    my ($l) = @_;
    weaken $_[0];
    my $res = [];
    my $i   = 0;
    $l = force $l;
    while (!is_null $l) {
        my $v = car $l;
        $$res[$i] = $v;
        $l = force cdr $l;
        $i++;
    }
    $res
}

*FP::List::List::stream_array = *stream_to_array;

sub stream_to_purearray {
    my ($l) = @_;
    weaken $_[0];
    my $a = stream_to_array $l;
    require FP::PureArray;
    FP::PureArray::array_to_purearray($a)
}

*FP::List::List::stream_purearray = *stream_to_purearray;

TEST {
    stream(1, 3, 4)->purearray->map (sub { $_[0]**2 })
}
bless [1, 9, 16], "FP::_::PureArray";

sub stream_to_list {
    @_ == 1 or fp_croak_arity 1;
    my ($l) = @_;
    weaken $_[0];
    array_to_list stream_to_array $l
}

*FP::List::List::stream_list = *stream_to_list;

sub stream_sort {
    @_ == 1 or @_ == 2 or fp_croak_arity "1 or 2";
    my ($l, $maybe_cmp) = @_;
    stream_to_purearray($l)->sort ($maybe_cmp)
}

*FP::List::List::stream_sort = *stream_sort;

TEST {
    require FP::Ops;
    stream(5, 3, 8, 4)->sort (*FP::Ops::number_cmp)->array
}
[3, 4, 5, 8];

TEST { ref(stream(5, 3, 8, 4)->sort (*FP::Ops::number_cmp)) }
'FP::_::PureArray';    # XX ok? Need to `->stream` if a stream is needed

TEST { stream(5, 3, 10, 8, 4)->sort (*FP::Ops::number_cmp)->stream->car }
3;

# but then PureArray has `first`, too, if that's all you need.

TEST { stream(5, 3, 10, 8, 4)->sort->stream->car }
10;                    # the default is string sort

# add a lazy merge sort instead/in addition?

sub stream_group;
*stream_group = FP::List::make_group(1);

sub FP::List::List::stream_group {
    @_ >= 2 and @_ <= 3 or fp_croak_arity "2-3";
    my ($self, $equal, $maybe_tail) = @_;
    weaken $_[0];
    stream_group($equal, $self, $maybe_tail)
}

sub stream_mixed_flatten {
    @_ >= 1 and @_ <= 3 or fp_croak_arity "1-3";
    my ($v, $maybe_tail, $maybe_delay) = @_;

    #XXX needed, no? weaken $_[0] if ref $_[0];
    mixed_flatten($v, $maybe_tail // null, $maybe_delay || \&lazyLight)
}

*FP::List::List::stream_mixed_flatten = *stream_mixed_flatten;

sub stream_any {
    @_ == 2 or fp_croak_arity 2;
    my ($pred, $l) = @_;
    weaken $_[1];
    $l = force $l;
    if (is_pair $l) {
        (&$pred(car $l)) or do {
            my $r = cdr $l;
            stream_any($pred, $r)
        }
    } elsif (is_null $l) {
        0
    } else {
        die "improper list: $l"
    }
}

*FP::List::List::stream_any = flip \&stream_any;

# (meant as a debugging tool: turn stream to string)
sub stream_show {
    @_ == 1 or fp_croak_arity 1;
    my ($s) = @_;
    join("", map {"  '$_'\n"} @{ stream_to_array $s })
}

*FP::List::List::stream_show = *stream_show;

# A stateful fold: collect state while going to the end (starting from
# the left). Then it's basically a fold_right.

sub stream_state_fold_right {
    @_ == 3 or fp_croak_arity 3;
    my ($fn, $stateupfn, $s) = @_;
    sub {
        @_ == 1 or fp_croak_arity 1;
        my ($statedown) = @_;
        no warnings 'recursion';
        FORCE $s;
        if (is_null $s) {
            @_ = ($statedown);
            goto &$stateupfn
        } else {
            my ($v, $s) = $s->first_and_rest;
            @_ = ($v, $statedown, stream_state_fold_right($fn, $stateupfn, $s));
            goto &$fn;
        }
    }
}

*FP::List::List::stream_state_fold_right = rot3left \&stream_state_fold_right;

TEST {
    stream_state_fold_right(
        sub {
            my ($v, $statedown, $restfn) = @_;
            [$v, &$restfn($statedown . ".")]
        },
        sub {
            my ($statedown) = @_;
            $statedown . "end"
        },
        stream(3, 4)
    )->("start")
}
[3, [4, "start..end"]];

TEST {
    stream_state_fold_right(
        sub {
            my ($v, $statedown, $restfn) = @_;
            cons $v, &$restfn($statedown)
        },
        sub { $_[0] },    # \&identity
        stream(3, 4)
        )->(list 5, 6)->array
}
[3, 4, 5, 6];

TEST {
    stream_state_fold_right(
        sub {
            my ($v, $statedown, $restfn) = @_;
            cons $v, &$restfn(cons $v, $statedown)
        },
        sub { $_[0] },    # \&identity
        stream(3, 4)
        )->(list 5, 6)->array
}
[3, 4, 4, 3, 5, 6];

TEST {
    stream_state_fold_right(
        sub {
            my ($v, $statedown, $restfn) = @_;
            lazy {
                cons [$v, $statedown], &$restfn($statedown + 1)
            }
        },
        undef,    # \&identity, but never reached
        stream_iota
        )->(10)->take(3)->array
}
[[0, 10], [1, 11], [2, 12]];

# modified test from above
TEST {
    stream_iota->state_fold_right(
        sub {
            my ($v, $statedown, $restfn) = @_;
            lazy {
                cons [$v, $statedown], &$restfn($statedown + 1)
            }
        },
        undef,    # \&identity, but never reached
        )->(10)->take(3)->array
}
[[0, 10], [1, 11], [2, 12]];

# are these warranted?: (or should they be deprecated right upon
# introduction?)

sub stream_mixed_fold_right {
    @_ == 3 or fp_croak_arity 3;
    my ($fn, $state, $v) = @_;
    weaken $_[2] if ref $_[2];
    @_ = ($fn, $state, stream_mixed_flatten $v);
    goto \&stream_fold_right
}

*FP::List::List::stream_mixed_fold_right = rot3left \&stream_mixed_fold_right;

sub stream_mixed_state_fold_right {
    @_ == 3 or fp_croak_arity 3;
    my ($fn, $statefn, $v) = @_;
    weaken $_[2] if ref $_[2];
    @_ = ($fn, $statefn, stream_mixed_flatten $v);
    goto \&stream_state_fold_right
}

*FP::List::List::stream_mixed_state_fold_right
    = rot3left \&stream_mixed_state_fold_right;

# 'cross product'

sub stream_cartesian_product_2 {
    @_ == 2 or fp_croak_arity 2;
    my ($a, $orig_b) = @_;
    weaken $_[0];
    weaken $_[1];
    my $rec;
    $rec = sub {
        my ($a, $b) = @_;
        my $rec = $rec;
        lazy {
            if (is_null $a) {
                null
            } elsif (is_null $b) {
                &$rec(cdr($a), $orig_b);
            } else {
                cons(cons(car($a), car($b)), &$rec($a, cdr $b))
            }
        }
    };
    Weakened($rec)->($a, $orig_b)
}

*FP::List::List::stream_cartesian_product_2 = *stream_cartesian_product_2;

TEST { F stream_cartesian_product_2 list("A", "B"), list(list(1), list(2)) }
list(list('A', 1), list('A', 2), list('B', 1), list('B', 2));

TEST {
    F stream_cartesian_product_2 list("E", "F"),
        stream_cartesian_product_2 list("C", "D"),
        list(list("A"), list("B"))
}
list(
    list("E", "C", "A"),
    list("E", "C", "B"),
    list("E", "D", "A"),
    list("E", "D", "B"),
    list("F", "C", "A"),
    list("F", "C", "B"),
    list("F", "D", "A"),
    list("F", "D", "B")
);

sub stream_cartesian_product {
    my @v = @_;
    weaken $_ for @_;
    if (!@v) {
        die "stream_cartesian_product: need at least 1 argument"
    } elsif (@v == 1) {
        stream_map *list, $v[0]
    } else {
        my $first = shift @v;
        stream_cartesian_product_2($first, stream_cartesian_product(@v))
    }
}

*FP::List::List::stream_cartesian_product = *stream_cartesian_product;

TEST_STDOUT {
    write_sexpr stream_cartesian_product list("A", "B"), list("C", "D"),
        list("E", "F")
}
'(("A" "C" "E") ("A" "C" "F") ("A" "D" "E") ("A" "D" "F") ("B" "C" "E")'
    . ' ("B" "C" "F") ("B" "D" "E") ("B" "D" "F"))';
TEST_STDOUT {
    write_sexpr stream_cartesian_product list("A", "B"), list("C", "D"),
        list("E")
}
'(("A" "C" "E") ("A" "D" "E") ("B" "C" "E") ("B" "D" "E"))';
TEST_STDOUT {
    write_sexpr stream_cartesian_product list("A", "B"), list("C", "D")
}
'(("A" "C") ("A" "D") ("B" "C") ("B" "D"))';

TEST_STDOUT {
    write_sexpr stream_cartesian_product list("A", "B")
}
'(("A") ("B"))';

TEST { F stream(1, 2)->cartesian_product(list 3, 4) }
list(list(1, 3), list(1, 4), list(2, 3), list(2, 4));

# chunksOf from Haskell's Data.List.Split, but returns `purearray`s
# instead of lists.

sub make_chunks_of {
    my ($strictly, $lazy) = @_;
    sub {
        @_ == 2 or fp_croak_arity 2;
        my ($s, $chunklen) = @_;
        $chunklen >= 1 or croak "invalid chunklen: $chunklen";
        weaken $_[0] if $lazy;    # although tie down is only chunk sized
        require FP::PureArray;
        fix(
            sub {
                my ($rec, $s) = @_;
                weaken $_[0] if $lazy;   # although tie down is only chunk sized
                lazy_if {
                    return null if $s->is_null;
                    my @v;
                    for my $i (1 .. $chunklen) {
                        if ($s->is_null) {
                            die "premature end of input" if $strictly;
                        } else {
                            push @v, $s->first;
                            $s = $s->rest;
                        }
                    }
                    cons FP::PureArray::array_to_purearray(\@v), &$rec($s)
                }
                $lazy
            }
        )->($s)
    }
}

# Do we still want functions?
#*stream_chunks_of = flip make_chunks_of(0);
#*stream_strictly_chunks_of = flip make_chunks_of(0);

*FP::List::List::chunks_of                 = make_chunks_of(0, 0);
*FP::List::List::strictly_chunks_of        = make_chunks_of(1, 0);
*FP::List::List::stream_chunks_of          = make_chunks_of(0, 1);
*FP::List::List::stream_strictly_chunks_of = make_chunks_of(1, 1);

TEST { list(qw(a b c d e f))->chunks_of(2) }
GIVES {
    require FP::PureArray;
    import FP::PureArray;
    list(purearray('a', 'b'), purearray('c', 'd'), purearray('e', 'f'))
};
TEST { stream(qw(a b c d e f))->chunks_of(3)->F }
GIVES {
    list(purearray('a', 'b', 'c'), purearray('d', 'e', 'f'))
};
TEST { list(qw(a b c d e f))->chunks_of(4) }
GIVES {
    list(purearray('a', 'b', 'c', 'd'), purearray('e', 'f'))
};
TEST { list(qw(a b c d e f))->chunks_of(40) }
GIVES {
    list(purearray('a', 'b', 'c', 'd', 'e', 'f'))
};
TEST_EXCEPTION { list(qw(a b c d e f))->strictly_chunks_of(4)->F }
'premature end of input';

# ----- Tests ----------------------------------------------------------

TEST {
    stream_any sub { $_[0] % 2 }, array_to_stream [2, 4, 8]
}
0;
TEST {
    stream_any sub { $_[0] % 2 }, array_to_stream []
}
0;
TEST {
    stream_any sub { $_[0] % 2 }, array_to_stream [2, 5, 8]
}
1;
TEST {
    stream_any sub { $_[0] % 2 }, array_to_stream [7]
}
1;

TEST {
    my @v;
    stream_for_each sub { push @v, @_ },
        stream_map sub { my $v = shift; $v * $v }, array_to_stream [10, 11, 13];
    \@v
}
[100, 121, 169];

TEST {
    my @v;
    stream_for_each sub { push @v, @_ },
        stream_map_with_tail(
        sub { my $v = shift; $v * $v },
        array_to_stream([10, 11, 13]),
        array_to_stream([1,  2])
        );
    \@v
}
[100, 121, 169, 1, 2];

TEST {
    stream_to_array stream_filter sub { $_[0] % 2 }, stream_iota 0, 5;
}
[1, 3];

# write_sexpr( stream_take( stream_iota (0, 1000000000), 2))
# ->  ("0" "1")

TEST { stream_to_array stream_zip cons(2, null), cons(1, null) }
[[2, 1]];
TEST { stream_to_array stream_zip cons(2, null), null }
[];

TEST {
    list_to_array F stream_zip2(
        stream_map(sub { $_[0] + 10 }, stream_iota(0, 5)),
        stream_iota(0, 3))
}
[[10, 0], [11, 1], [12, 2]];

TEST {
    stream_to_array stream_take_while sub { my ($x) = @_; $x < 2 }, stream_iota
}
[0, 1];

TEST {
    stream_to_array stream_take stream_drop_while(sub { $_[0] < 10 },
        stream_iota()), 3
}
[10, 11, 12];

TEST {
    stream_to_array stream_drop_while(sub { $_[0] < 10 }, stream_iota(0, 5))
}
[];

TEST { join("", @{ stream_to_array(string_to_stream("You're great.")) }) }
'You\'re great.';

TEST {
    stream_to_string stream__subarray_fold_right(
        \&cons,
        string_to_stream("World"),
        [split //, "Hello"],
        3, undef
    )
}
'loWorld';

TEST {
    stream_to_string stream__subarray_fold_right(
        \&cons,
        string_to_stream("World"),
        [split //, "Hello"],
        3, 4
    )
}
'lWorld';

TEST {
    stream_to_string stream__subarray_fold_right_reverse \&cons,
        cons("W", null), [split //, "Hello"], 1,
        undef
}
'eHW';

TEST {
    stream_to_string stream__subarray_fold_right_reverse \&cons,
        cons("W", null), [split //, "Hello"], 2, 0
}
'leW';    # hmm really? exclusive lower boundary?

TEST { stream_to_string subarray_to_stream [split //, "Hello"], 1, 3 }
'el';

TEST { stream_to_string subarray_to_stream [split //, "Hello"], 1, 99 }
'ello';

TEST { stream_to_string subarray_to_stream [split //, "Hello"], 2 }
'llo';

TEST { stream_to_string subarray_to_stream_reverse [split //, "Hello"], 1 }
'eH';

TEST { stream_to_string subarray_to_stream_reverse [split //, "Hello"], 1, 0 }
'e'
    ; # dito. BTW it's consistent at least, $start not being 'after the element'(?) either.

TEST { my $s = stream_iota; stream_to_array stream_slice $s, $s }

# XX: warns about "Reference is already weak"
[];
TEST { my $s = stream_iota; stream_to_array stream_slice $s, cdr $s }
[0];
TEST { my $s = stream_iota; stream_to_array stream_slice cdr($s), cdddr $s }
[1, 2];

# OO interface:

TEST { string_to_stream("Hello")->string }
"Hello";

TEST {
    my $s  = string_to_stream "Hello";
    my $ss = $s->force;
    $ss->string
}
"Hello";

TEST {
    array_to_stream([1, 2, 3])->map(sub { $_[0] + 1 })
        ->fold(sub { $_[0] + $_[1] }, 0)
}
9;

# variable life times:

TEST {
    my $s  = string_to_stream "Hello";
    my $ss = $s->force;

    # dispatching to list_to_string
    $ss->string;
    is_pair $ss
}
1;

TEST {
    my $s = string_to_stream "Hello";
    stream_to_string $s;
    defined $s
}
'';

TEST {
    my $s = string_to_stream "Hello";
    $s->stream_string;
    defined $s
}
'';

TEST {
    my $s = string_to_stream "Hello";

    # still dispatching to stream_string thanks to hack in
    # Lazy.pm
    $s->string;
    defined $s
}
'';

# Lazyness check, and be-careful reminder: (example from SYNOPSIS in
# Lazy.pm)

{
    my $tot;
    my $l;
    TEST {
        $tot = 0;
        $l   = stream_map sub {
            my ($x) = @_;
            $tot += $x;
            $x * $x
        }, list(5, 7, 8);
        $tot
    }
    0;
    TEST { [$l->first, $tot] }
    [25, 5];
    TEST { [$l->length, $tot] }
    [3, 20];
}

1
