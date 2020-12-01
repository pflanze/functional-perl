#
# Copyright (c) 2013-2020 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FP::Array - pure functions to work with native Perl arrays

=head1 SYNOPSIS

    use FP::List; use FP::Equal 'is_equal'; use FP::Div 'inc';
    use FP::Array ':all';

    is_equal array_map(*inc, [3, 4, 6]),
             [4, 5, 7];
    is_equal list([], [3,4], [9])->map(*array_length),
             list(0, 2, 1);


=head1 DESCRIPTION

To disambiguate from similarly named functions for `FP::List`, they
are prefixed with `array_`.

These are also used as methods for `FP::PureArray` objects.

=head1 SEE ALSO

L<FP::Array_sort>, L<FP::PureArray>

=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut

package FP::Array;
use strict;
use warnings;
use warnings FATAL => 'uninitialized';
use Exporter "import";

our @EXPORT    = qw();
our @EXPORT_OK = qw(array
    array_equal
    array_first
    array_maybe_first
    array_rest
    array_maybe_rest
    array_first_and_rest
    array_maybe_first_and_rest
    array_second
    array_ref
    array_ref
    array_length
    array_is_null
    array_set
    array_update
    array_push
    array_pop
    array_shift
    array_unshift
    array_sub
    array_take
    array_take_while
    array_take_while_and_rest
    array_drop
    array_drop_while
    array_append
    array_reverse
    array_xone
    array_perhaps_one
    array_hashing_uniq
    array_zip2
    array_for_each
    array_map
    array_map_with_index
    array_map_with_islast
    array_to_hash_map
    array_filter
    array_zip
    array_fold
    array_fold_right
    array_intersperse
    array_strings_join
    array_to_string
    array_every
    array_any
    array_sum
    array_last
    array_to_hash_group_by
);
our %EXPORT_TAGS = (all => [@EXPORT, @EXPORT_OK]);

use Carp;
use FP::Carp;
use Chj::TEST;
use FP::Div qw(min);
use FP::Ops 'add';
use FP::Equal 'equal';

sub array { [@_] }

sub array_equal {
    my ($a, $b) = @_;
    @$a == @$b and do {
        my $len = @$a;
        for (my $i = 0; $i < $len; $i++) {
            equal($$a[$i], $$b[$i]) or return 0;
        }
        1
    }
}

sub array_maybe_first {
    @_ == 1 or fp_croak_arity 1;
    $_[0][0]
}

sub array_perhaps_first {
    @_ == 1 or fp_croak_arity 1;
    my ($a) = @_;
    @$a ? $$a[0] : ()
}

sub array_first {
    @_ == 1 or fp_croak_arity 1;
    my ($a) = @_;
    @$a or die "can't take the first of an empty array";
    $$a[0]
}

sub array_maybe_rest {
    @_ == 1 or fp_croak_arity 1;
    my ($a) = @_;
    @$a ? [@$a[1 .. $#$a]] : undef
}

sub array_perhaps_rest {
    @_ == 1 or fp_croak_arity 1;
    my ($a) = @_;
    @$a ? [@$a[1 .. $#$a]] : ()
}

sub array_rest {
    @_ == 1 or fp_croak_arity 1;
    my ($a) = @_;
    @$a or die "can't take the rest of an empty array";
    [@$a[1 .. $#$a]]
}

sub array_maybe_first_and_rest {
    @_ == 1 or fp_croak_arity 1;
    my ($a) = @_;
    @$a ? (array_first $a, array_rest $a) : undef
}

sub array_first_and_rest {
    @_ == 1 or fp_croak_arity 1;
    my ($a) = @_;
    (array_first $a, array_rest $a)
}

sub array_second {
    @_ == 1 or fp_croak_arity 1;
    $_[0][1]
}

sub array_maybe_ref {
    @_ == 2 or fp_croak_arity 2;
    my ($a, $i) = @_;
    $$a[$i]
}

sub array_ref {
    @_ == 2 or fp_croak_arity 2;
    my ($a, $i) = @_;

    # XX also check that $i is integer?
    ($i >= 0 and $i < @$a) or croak "index out of bounds: $i";
    $$a[$i]
}

TEST_EXCEPTION { array_ref [], 0 } "index out of bounds: 0";
TEST { array_ref [5], 0 } 5;
TEST_EXCEPTION { array_ref [5], 1 } "index out of bounds: 1";
TEST_EXCEPTION { array_ref [5], -1 } "index out of bounds: -1";

sub array_length {
    @_ == 1 or fp_croak_arity 1;
    scalar @{ $_[0] }
}

sub array_is_null {
    @_ == 1 or fp_croak_arity 1;
    @{ $_[0] } == 0
}

# functional updates

sub array_set {
    @_ == 3 or fp_croak_arity 3;
    my ($a, $i, $v) = @_;
    my $a2 = [@$a];
    $$a2[$i] = $v;
    $a2
}

sub array_update {
    @_ == 3 or fp_croak_arity 3;
    my ($a, $i, $fn) = @_;
    my $a2 = [@$a];
    $$a2[$i] = &$fn($$a2[$i]);
    $a2
}

sub array_push {
    my $a  = shift;
    my $a2 = [@$a];
    push @$a2, @_;
    $a2
}

sub array_pop {
    @_ == 1 or fp_croak_arity 1;
    my ($a) = @_;
    my $a2  = [@$a];
    my $v   = pop @$a2;
    ($v, $a2)
}

sub array_shift {
    @_ == 1 or fp_croak_arity 1;
    my ($a) = @_;
    my $a2  = [@$a];
    my $v   = shift @$a2;
    ($v, $a2)
}

sub array_unshift {
    my $a  = shift;
    my $a2 = [@$a];
    unshift @$a2, @_;
    $a2
}

sub array_sub {
    my ($a, $from, $to) = @_;    # incl $from, excl $to
    (0 <= $from and $from <= @$a) or die "from out of range: $from";
    (0 <= $to   and $to <= @$a)   or die "to out of range: $to";
    bless [@$a[$from .. $to - 1]], ref $a
}

sub array_take {
    @_ == 2 or fp_croak_arity 2;
    my ($a, $n) = @_;
    array_sub $a, 0, $n
}

sub array_drop {
    @_ == 2 or fp_croak_arity 2;
    my ($a, $n) = @_;
    array_sub $a, $n, array_length $a
}

sub array_take_while {
    @_ == 2 or fp_croak_arity 2;
    my ($pred, $s) = @_;
    my $i   = 0;
    my $len = @$s;
    while (!($i >= $len) and &$pred($$s[$i])) {
        $i++
    }
    [@$s[0 .. $i - 1]]
}

sub array_take_while_and_rest {
    @_ == 2 or fp_croak_arity 2;
    my ($pred, $s) = @_;
    my $i   = 0;
    my $len = @$s;
    while (!($i >= $len) and &$pred($$s[$i])) {
        $i++
    }
    ([@$s[0 .. $i - 1]], [@$s[$i .. $len - 1]])
}

sub array_drop_while {
    @_ == 2 or fp_croak_arity 2;
    my ($pred, $s) = @_;
    my $i   = 0;
    my $len = @$s;
    while (!($i >= $len) and &$pred($$s[$i])) {
        $i++
    }
    [@$s[$i .. $#$s]]
}

# various

sub array_append {
    [
        map {
            # @$_ nope, that's totally unsafe, will open up array-based
            # objects, like for example cons cells...

            # evil inlined `is_array`
            if (defined $_[0] and ref($_[0]) eq "ARRAY") {
                @$_
            } else {
                $_->values
            }
        } @_
    ]
}

sub array_reverse {
    @_ == 1 or fp_croak_arity 1;
    my ($v) = @_;
    [reverse @$v]
}

sub array_xone {
    @_ == 1 or fp_croak_arity 1;
    my ($a) = @_;
    @$a == 1 or croak "expecting 1 element, got " . @$a;
    $$a[0]
}

sub array_perhaps_one {
    @_ == 1 or fp_croak_arity 1;
    my ($a) = @_;
    if (@$a == 1) {
        $$a[0]
    } else {
        ()
    }
}

sub array_hashing_uniq {
    @_ >= 1 and @_ <= 2 or fp_croak_arity "1-2";
    my ($ary, $maybe_warn) = @_;
    my %seen;
    [
        grep {
            my $s = $seen{$_};
            if ($s and $maybe_warn) { &$maybe_warn($_) }
            $seen{$_} = 1;
            not $s
        } @$ary
    ]
}

sub array_zip2 {
    @_ == 2 or fp_croak_arity 2;
    my ($l, $m) = @_;
    my @res;
    my $len = min(scalar @$l, scalar @$m);
    for (my $i = 0; $i < $len; $i++) {
        $res[$i] = [$$l[$i], $$m[$i]];
    }
    \@res
}

sub array_for_each {
    @_ == 2 or fp_croak_arity 2;
    my ($fn, $v) = @_;
    for my $a (@$v) { &$fn($a) }
}

sub array_map {
    @_ > 1 or fp_croak_arity "> 1";
    my $fn  = shift;
    my $len = min(map { scalar @$_ } @_);
    my @res;
    for (my $i = 0; $i < $len; $i++) {
        $res[$i] = &$fn(map { $$_[$i] } @_);
    }
    \@res
}

TEST {
    array_map sub { $_[0] + 1 }, [1, 2, 20]
}
[2, 3, 21];
TEST {
    array_map sub { $_[0] + $_[1] }, [1, 2, 20], [-1, 4]
}
[0, 6];

# (should one use multi-arg stream_map with stream_iota instead?..)
sub array_map_with_index {
    @_ > 1 or fp_croak_arity "> 1";
    my $fn  = shift;
    my $len = min(map { scalar @$_ } @_);
    my @res;
    for (my $i = 0; $i < $len; $i++) {
        $res[$i] = &$fn($i, map { $$_[$i] } @_);
    }
    \@res
}

TEST {
    array_map_with_index sub { [@_] }, [qw(a b)], [20 .. 40]
}
[[0, "a", 20], [1, "b", 21]];

sub array_map_with_islast {
    @_ > 1 or fp_croak_arity "> 1";
    my $fn   = shift;
    my $len  = min(map { scalar @$_ } @_);
    my $last = $len - 1;
    my @res;
    for (my $i = 0; $i < $len; $i++) {
        $res[$i] = &$fn($i == $last, map { $$_[$i] } @_);
    }
    \@res
}

TEST {
    array_map_with_islast sub { $_[0] }, [1, 2, 20]
}
['', '', 1];
TEST {
    array_map_with_islast sub { [@_] }, [1, 2, 20], ["b", "c"]
}
[['', 1, "b"], [1, 2, "c"]];

sub array_to_hash_map {
    @_ > 1 or fp_croak_arity "> 1";
    my $fn  = shift;
    my $len = min(map { scalar @$_ } @_);
    my %res;
    for (my $i = 0; $i < $len; $i++) {
        my @v = &$fn(map { $$_[$i] } @_);
        @v == 2 or croak "wrong number of return values: " . show(\@v);
        $res{ $v[0] } = $v[1];
    }
    \%res
}

TEST {
    array_to_hash_map(
        sub { my ($x, $a) = @_; $a => $x * $x },
        [2,   3,   4, 5],
        ["a", "b", "c"]
    )
}
+{ 'a' => 4, 'b' => 9, 'c' => 16 };

sub array_filter {
    @_ == 2 or fp_croak_arity 2;
    my ($fn, $v) = @_;
    [grep { &$fn($_) } @$v]
}

sub even {
    not($_[0] % 2)
}

TEST { array_filter \&even, [qw(1 7 4 9 -5 0)] }
[4, 0];

sub array_zip {
    array_map \&array, @_
}

TEST { array_zip [3, 4], [qw(a b c)] }
[[3, "a"], [4, "b"]];

# see discussion for `stream_fold` in `FP::Stream` for the reasoning
# behind the argument order of $fn
sub array_fold {
    @_ == 3 or fp_croak_arity 3;
    my ($fn, $start, $ary) = @_;
    for (@$ary) {
        $start = &$fn($_, $start);
    }
    $start
}

TEST {
    array_fold sub { [@_] }, 's', [3, 4]
}
[4, [3, 's']];

TEST {
    require FP::List;
    array_fold(\&FP::List::cons, &FP::List::null, array(1, 2))->array
}
[2, 1];

sub array_fold_right {
    @_ == 3 or fp_croak_arity 3;
    my ($fn, $tail, $a) = @_;
    my $i = @$a - 1;
    while ($i >= 0) {
        $tail = &$fn($$a[$i], $tail);
        $i--;
    }
    $tail
}

TEST {
    require FP::List;
    FP::List::list_to_array(
        array_fold_right(\&FP::List::cons, &FP::List::null, [1, 2, 3]))
}
[1, 2, 3];

sub array_intersperse {
    @_ == 2 or fp_croak_arity 2;
    my ($ary, $val) = @_;
    my @res;
    for (@$ary) {
        push @res, $_, $val
    }
    pop @res;
    \@res
}

TEST { array_intersperse [1, 2, 3], "a" }
[1, 'a', 2, 'a', 3];
TEST { array_intersperse [], "a" } [];

sub array_strings_join {
    @_ == 2 or fp_croak_arity 2;
    my ($ary, $val) = @_;
    join $val, @$ary
}

TEST { array_strings_join [1, 2, 3], "-" }
"1-2-3";

sub array_to_string {
    @_ == 1 or fp_croak_arity 1;
    my ($ary) = @_;
    join "", @$ary
}

TEST { array_to_string [1, 2, 3] }
"123";

sub array_every {
    @_ == 2 or fp_croak_arity 2;
    my ($fn, $ary) = @_;
    for (@$ary) {
        return 0 unless &$fn($_);
    }
    1
}

TEST {
    array_every sub { ($_[0] % 2) == 0 }, [1, 2, 3]
}
0;
TEST {
    array_every sub { ($_[0] % 2) == 0 }, [2, 4, -6]
}
1;
TEST {
    array_every sub { ($_[0] % 2) == 0 }, []
}
1;

sub array_any {
    @_ == 2 or fp_croak_arity 2;
    my ($fn, $ary) = @_;
    for (@$ary) {
        return 1 if &$fn($_);
    }
    0
}

TEST {
    array_any sub { $_[0] % 2 }, [2, 4, 8]
}
0;
TEST {
    array_any sub { $_[0] % 2 }, []
}
0;
TEST {
    array_any sub { $_[0] % 2 }, [2, 5, 8]
}
1;
TEST {
    array_any sub { $_[0] % 2 }, [7]
}
1;

sub array_sum {
    @_ == 1 or fp_croak_arity 1;
    array_fold \&add, 0, $_[0]
}

sub array_last {
    @_ == 1 or fp_croak_arity 1;
    my ($a) = @_;
    $$a[-1]
}

sub array_to_hash_group_by {
    @_ == 2 or fp_croak_arity 2;
    my ($ary, $on) = @_;
    my %res;
    for (@$ary) {
        push @{ $res{ &$on($_) } }, $_
    }
    \%res
}

# adapted from FP::List
sub array_perhaps_find_tail {
    @_ == 2 or fp_croak_arity 2;
    my ($fn, $s,) = @_;
    my $len = @$s;
    my $i   = 0;
LP: {
        if ($i >= $len) { () }
        else {
            #my ($v,$l1) = $s->first_and_rest;
            #  ^ with efficient slice we could do it !
            my $v = $$s[$i];
            if (&$fn($v)) {

                # $s
                # hmmm
                $s->drop($i)
            } else {

                # $s = $s1;
                $i++;
                redo LP
            }
        }
    }
}

sub array_perhaps_find {
    @_ == 2 or fp_croak_arity 2;
    my ($fn, $l) = @_;
    if (my ($l) = array_perhaps_find_tail($fn, $l)) {
        $l->first
    } else {
        ()
    }
}

1
