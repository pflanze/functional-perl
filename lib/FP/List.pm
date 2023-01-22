#
# Copyright (c) 2013-2023 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FP::List - singly linked (purely functional) lists

=head1 SYNOPSIS

    use FP::Div qw(inc square); use FP::Ops qw(div); use FP::Equal 'is_equal';
    use FP::Combinators qw(flip);
    use FP::Predicates qw(is_pure);

    use FP::List ':all';

    my $l = cons("H", cons("e", cons("l", cons("l", cons("o", null)))));
    is_equal $l, list("H", "e", "l", "l", "o");
    is_equal list_to_string($l), "Hello";
    ok is_pure $l;

    is_equal list(1,2,3)->map(sub{ $_[0] * $_[0] }),
             list(1,4,9);
    is_equal list(1,2,3)->map(\&square)->array,
             [1,4,9];

    is list(qw(a b c))->first, "a";
    is_equal list(qw(a b c))->rest,
             list("b", "c");

    is list(1,2,3,4)->sum, 1+2+3+4;
    is list(1,2,3,4)->product, 1*2*3*4;
    is list(2,4,6)->reduce(flip \&div), 2/4/6;
    is list(2,4,6)->reduce_right(flip \&div), 2/4/6;
    # etc.

    # The `cons` function checks whether its second argument is an object
    # with a `cons` method, if so, it invokes it, otherwise it creates an
    # FP::List::Pair object holding both values (there's also a `pair`
    # function that doesn't check for a method and always directly
    # creates the pair)
    is cons("a","b")->rest, "b";
    is cons("a","b")->cdr, "b";
    is list(5,6,7)->caddr, 7;


=head1 DESCRIPTION

Purely functional (immutable) singly linked lists are interesting in
functional programs because they can be extended and walked directly
via recursion. They do not offer efficient random access (O(len)),
also there is a constant space overhead and access indirection
compared to arrays. They are most appropriate for maintaining smaller
but frequently updated chains, for example maintaining a link chain to
parent scopes while recursing into a tree datastructure (which, if
it's a pure data structure, doesn't have parent links built into it).

FP::List does not enforce its pairs to only contain pairs or null in
their rest (cdr) position. Which means that they may end in something
else than a null (and operations encountering these will die with
"improper list"). The `show` function (or the `:s`
mode in `FP::Repl::Repl`) displays those as `improper_list`, e.g.:

 # a normal, 'proper', list:
 is_equal cons(5, cons(6, cons(7, null))), list(5, 6, 7);

 # an 'improper' list:
 is_equal cons(5, cons(6, 7)), improper_list(5, 6, 7);

Note that destruction of linked lists in Perl requires space on the C
stack proportional to their length. You should either avoid dropping a
long linked list at once (dropping it one cell at a time intermixed
with doing any other operation avoids the issue), or will want to
increase the C stack size limit, lest your program will segfault.


=head1 PURITY

`FP::List` cells are created to be immutable by default, which
enforces the functional purity of the API. This can be disabled by
setting `$FP::List::immutable` to false when creating lists; slots in
pairs can then be mutated. Only ever use this during development (),
if at all; if you need to update sequences in the middle efficiently ,
use another data structure (like L<FP::Vec>).

In either case, `FP::List` implements `FP::Abstract::Pure` (`is_pure`
from `FP::Predicates` returns true).


=head1 NAMING

Most functional programming languages are using either the `:` or `::`
operator to prepend an item to a list. The name `cons` comes from
lisps, where it's the basic (lisp = list processing!) "construction"
function.

Cons cells (pairs) in lisps can also be used to build other data
structures than lists: they don't enforce the rest slot to be a pair
or null. Lisps traditionally use `car` and `cdr` as accessors for the
two fields, to respect this feature, and also because 'a' and 'd'
combine easily into composed names like `caddr`. This library offers
`car` and `cdr` as aliases to `first` and `rest`.

Some languages call the accessors `head` and `tail`, but `tail` would
conflict with `Sub::Call::Tail`, hence those are not used here.


=head1 SEE ALSO

Implements: L<FP::Abstract::Pure>, L<FP::Abstract::Sequence>,
L<FP::Abstract::Equal>, L<FP::Abstract::Show>

L<FP::Stream>, L<FP::Array>, L<FP::PureArray>

=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut

package FP::List;
use strict;
use warnings;
use warnings FATAL => 'uninitialized';
use Exporter "import";

our @EXPORT = qw(
    cons cons_ is_pair null is_null is_pair_of is_pair_or_null
    list_of nonempty_list_of is_null_or_pair_of null_or_pair_of is_list
    car cdr first rest
    car_and_cdr first_and_rest perhaps_first_and_rest
    list);
our @EXPORT_OK = qw(
    pair improper_list improper_map improper_filtermap improper_last
    first_set first_update
    is_pair_noforce is_null_noforce
    unsafe_cons unsafe_car unsafe_cdr
    string_to_list list_length list_reverse list_reverse_with_tail
    list_to_string list_to_array rlist_to_array
    list_to_values rlist_to_values
    write_sexpr
    array_to_list array_to_list_reverse mixed_flatten
    list_strings_join list_strings_join_reverse
    list_filter list_map list_filtermap list_mapn list_map_with_islast
    list_map_with_index_ list_map_with_index
    list_fold list_fold_right list_to_perlstring
    unfold unfold_right
    list_pair_fold_right
    list_butlast list_drop_while list_rtake_while list_take_while
    list_rtake_while_and_rest list_take_while_and_rest
    list_append
    list_zip2
    list_alist
    list_last
    list_every list_all list_any list_none
    list_perhaps_find_tail list_perhaps_find
    list_find_tail list_find
    list_insertion_variants
    list_merge
    cartesian_product_2
    cartesian_product
    is_charlist ldie
    cddr
    cdddr
    cddddr
    cadr
    caddr
    cadddr
    caddddr
    c_r
    list_ref
    list_perhaps_one
    list_sort
    list_drop
    list_take
    list_slice
    list_group
    circularlist
    weaklycircularlist
);
our %EXPORT_TAGS = (all => [@EXPORT, @EXPORT_OK]);

use 5.008;    # for Internals::SvREADONLY

use FP::Lazy;
use FP::Lazy qw(force_noeval);
use Chj::xperlfunc qw(xprint xprintln);
use FP::Combinators qw(flip flip2of3 rot3right rot3left);
use FP::Optional qw(perhaps_to_maybe);
use Chj::TEST;
use FP::Predicates qw(is_natural0 either is_natural complement is_even is_zero);
use FP::Div qw(inc dec);
use FP::Show;
use Scalar::Util qw(weaken blessed);
use FP::Weak qw(Weakened);
use FP::Interfaces;
use Carp;
use FP::Carp;
use FP::Docstring;

our $immutable = 1;    # whether pairs are to be made immutable

#use FP::Array 'array_fold_right'; can't, recursive dependency XX (see copy below)
#(Chj::xIOUtil triggers it)

package FP::List::List {
    use FP::Lazy;
    use FP::Carp;

    use Chj::NamespaceCleanAbove;

    *null = \&FP::List::null;

    sub pair_namespace {"FP::List::Pair"}

    sub cons {
        my $s = shift;
        @_ == 1 or fp_croak_arity 1;
        my @p = ($_[0], $s);

        # Now it gets ~ugly: for lazy code, $s can (now, since
        # AUTOLOAD on them doesn't necessarily force them anymore) now
        # be a promise with field 2 set.
        # my $immediate_class = ref($s);
        # bless \@p,
        #     UNIVERSAL::isa($immediate_class, "FP::Lazy::AnyPromise")
        #     ? $$s[2]
        #     : $immediate_class;
        # /ugly.

        # OR, simply (since the above would void any chance of simply
        # using `lazyT` in stream libraries since one couldn't know
        # the type of cons cells statically)!:

        bless \@p, $s->pair_namespace;

        if ($immutable) {
            Internals::SvREADONLY $p[0], 1;
            Internals::SvREADONLY $p[1], 1;
        }
        Internals::SvREADONLY @p, 1;
        \@p
    }

    # return this sequence as a list, i.e. identity
    sub list {
        @_ == 1 or fp_croak_arity 1;
        $_[0]
    }

    sub stream {
        @_ == 1 or fp_croak_arity 1;
        my ($l) = @_;
        lazy {$l}
    }

    sub strictlist {
        @_ == 1 or fp_croak_arity 1;
        my $s = shift;
        FP::StrictList::strictlist($s->values)
    }

    # sub purearray: see below, \&FP::List::List::purearray

    sub mutablearray {
        @_ == 1 or fp_croak_arity 1;
        my $s = shift;
        FP::_::MutableArray->new_from_array([$s->values])
    }

    sub preferred_fold {
        my $s = shift;
        $s->fold(@_)
    }

    _END_
}

package FP::List::Null {
    use FP::Carp;
    our @ISA = qw(FP::List::List);

    sub is_null {1}

    sub length {
        0
    }

    my $mkexn = sub {
        my ($method) = @_;
        sub { die "can't take the $method of the empty list" }
    };
    *first          = &$mkexn("first");
    *second         = &$mkexn("second");
    *rest           = &$mkexn("rest");
    *first_and_rest = &$mkexn("first_and_rest");
    *butlast        = &$mkexn("butlast");
    sub maybe_first            {undef}
    sub maybe_rest             {undef}
    sub perhaps_first          { () }
    sub perhaps_rest           { () }
    sub perhaps_first_and_rest { () }

    sub FP_Equal_equal {
        my ($a, $b) = @_;
        FP::List::is_null($b)

            # XX well, this is, *currently*, guaranteed by FP::Equal,
            # thus always 1
    }

    # for FP::Show:
    sub FP_Show_show {
        my ($s, $show) = @_;
        "list()"
    }

}

package FP::List::Pair {
    use FP::Carp;
    our @ISA = qw(FP::List::List);

    sub is_null {''}

    sub car {

        # $_[0][0]
        # nope, since lazyT, the argument can be a promise:
        (ref($_[0]) eq __PACKAGE__ ? $_[0] : FP::List::force $_[0])->[0]
    }
    *first = \&car;

    *maybe_first   = \&first;
    *perhaps_first = \&first;

    *first_set    = \&FP::List::first_set;
    *first_update = \&FP::List::first_update;

    sub cdr {

        # $_[0][1]
        # nope, since lazyT, the argument can be a promise:
        (ref($_[0]) eq __PACKAGE__ ? $_[0] : FP::List::force $_[0])->[1]
    }
    *rest         = \&cdr;
    *maybe_rest   = \&rest;
    *perhaps_rest = \&rest;

    sub car_and_cdr {
        @{ ref($_[0]) eq __PACKAGE__ ? $_[0] : FP::List::force $_[0] }
    }
    *first_and_rest         = \&car_and_cdr;
    *perhaps_first_and_rest = \&car_and_cdr;

    sub cddr   { $_[0]->cdr->cdr }
    sub cdddr  { $_[0]->cdr->cdr->cdr }
    sub cddddr { $_[0]->cdr->cdr->cdr->cdr }

    sub cadr { $_[0]->cdr->car }
    *second = \&cadr;
    sub caddr   { $_[0]->cdr->cdr->car }
    sub cadddr  { $_[0]->cdr->cdr->cdr->car }
    sub caddddr { $_[0]->cdr->cdr->cdr->cdr->car }

    # Re `c_r`:
    # Use AUTOLOAD to autogenerate instead? But be careful about the
    # overhead of the then necessary DESTROY method.

    sub FP_Equal_equal {
        my ($a, $b) = @_;
        no warnings 'recursion';
        (
                    FP::List::is_pair($b)
                and FP::Equal::equal($a->car, $b->car)
                and do {
                @_ = ($a->cdr, $b->cdr);
                goto \&FP::Equal::equal
            }
        )
    }

    sub FP_Show_show {
        my ($s, $show) = @_;

        # If there were no improper or lazy lists, this would do:
        #  "list(".$s->map($show)->strings_join(", ").")"

        my @v;
        my $v;
    LP: {
            ($v, $s) = $s->first_and_rest;
            push @v, &$show($v);
            $s = FP::List::force_noeval($s);
            if (FP::List::is_pair_noforce($s)) {
                redo LP;
            } elsif (FP::List::is_null_noforce($s)) {
                "list(" . join(", ", @v) . ")"
            } else {
                push @v, &$show($s);
                "improper_list(" . join(", ", @v) . ")"
            }
        }
    }

}

use FP::Equal;
TEST {
    equal(list(2, 3, 4), list(2, 3))
}
undef;
TEST {
    equal(list(2, 3, 4), list(2, 3, 4))
}
1;

sub cons {
    @_ == 2 or fp_croak_arity 2;
    if (defined blessed($_[1]) and my $f = $_[1]->can("cons")) {
        @_ = ($_[1], $_[0]);
        goto &$f;
    } else {
        goto \&unsafe_cons
    }
}

sub cons_ {
    @_ == 1 or fp_croak_arity 1;
    my ($item) = @_;
    sub {
        @_ == 1 or fp_croak_arity 1;
        if (defined blessed($_[0]) and my $f = $_[0]->can("cons")) {
            push @_, $item;
            goto &$f;
        } else {
            unsafe_cons($item, $_[0])
        }
    }
}

TEST { cons_(1)->(list(2)) } GIVES { list(1, 2) };
TEST { cons_(1)->(2) } GIVES       { cons 1, 2 };

sub pair {
    @_ == 2 or fp_croak_arity 2;
    goto \&unsafe_cons
}

# no type checking, but perhaps faster (especially if inlining ever
# becomes possible). Note that unsafe_car and unsafe_cdr are safe if
# subclasses are keeping the first fields the same and the argument
# was confirmed to be a pair with `is_pair`. unsafe_cons is safe if
# the rest argument should never dictate the type of the result.

sub unsafe_cons {
    @_ == 2 or fp_croak_arity 2;
    my @p = @_;
    bless \@p, "FP::List::Pair";
    if ($immutable) {
        Internals::SvREADONLY $p[0], 1;
        Internals::SvREADONLY $p[1], 1;
    }
    Internals::SvREADONLY @p, 1;
    \@p
}

# WARNING: be careful, this isn't safe even if `is_pair` returns true, as
# that only assures that ->car etc. can be called.
sub unsafe_car {
    @_ == 1 or fp_croak_arity 1;
    $_[0][0]
}

# WARNING: same as for unsafe_car
sub unsafe_cdr {
    @_ == 1 or fp_croak_arity 1;
    $_[0][1]
}

sub is_pair {
    @_ == 1 or fp_croak_arity 1;
    my ($v) = @_;
    my $r = blessed($v) // return;
    (
               $r eq "FP::List::Pair"
            or $v->isa("FP::List::Pair")
            or $v->isa("FP::Lazy::Promise") && is_pair(force $v)
    )

        # ^  XX evil: inlined `is_promise`
}

sub is_pair_noforce {
    @_ == 1 or fp_croak_arity 1;
    my ($v) = @_;
    my $r = blessed($v) // return;
    ($r eq "FP::List::Pair" or $v->isa("FP::List::Pair"))
}

sub is_pair_of {
    my ($p0, $p1) = @_;
    sub {
        @_ == 1 or fp_croak_arity 1;
        my ($v) = @_;
        (is_pair($v) and &$p0($$v[0]) and &$p1($$v[1]))
    }
}

# nil value

my $null = do {
    my @null;
    bless \@null, "FP::List::Null";
    Internals::SvREADONLY @null, 1;
    \@null
};
Internals::SvREADONLY $null, 1;

sub null () {

    # @_ == 0 or fp_croak_arity 0;
    # nope, it is also called as a method
    $null
}

TEST { null->cons(1)->cons(2)->array }
[2, 1];

sub is_null {
    @_ == 1 or fp_croak_arity 1;
    my ($v) = @_;
    my $r = blessed($v) // return;
    (
               $r eq "FP::List::Null"
            or $v->isa("FP::List::Null")
            or $v->isa("FP::Lazy::Promise") && is_null(force $v)
    )
}

sub is_null_noforce {
    @_ == 1 or fp_croak_arity 1;
    my ($v) = @_;
    my $r = blessed($v) // return;
    ($r eq "FP::List::Null" or $v->isa("FP::List::Null"))
}

sub is_pair_or_null {
    @_ == 1 or fp_croak_arity 1;
    my ($v) = @_;
    my $r = blessed($v) // return;
    (
               $r eq "FP::List::List"
            or $v->isa("FP::List::List")
            or $v->isa("FP::Lazy::Promise") && is_pair_or_null(force $v)
    )
}

TEST { is_pair_or_null cons 1, 2 } 1;
TEST { is_pair_or_null null } 1;
TEST { is_pair_or_null 1 } undef;
TEST { is_pair_or_null bless [], "NirvAna" } '';

# test subclassing? whatever

sub is_null_or_pair_of {
    @_ == 3 or fp_croak_arity 3;
    my ($v, $p0, $p1) = @_;
    FORCE $v;
    (is_null $v or (is_pair $v and &$p0($v->car) and &$p1($v->cdr)))
}

sub null_or_pair_of {
    @_ == 2 or fp_croak_arity 2;
    my ($p0, $p1) = @_;

    sub {
        @_ == 1 or fp_croak_arity 1;
        my ($v) = @_;
        is_null_or_pair_of($v, $p0, $p1)
    }
}

TEST {
    require FP::Array;
    FP::Array::array_map(
        null_or_pair_of(\&is_null, \&is_pair),
        [
            null,
            cons(1,    2),
            cons(null, 1),
            cons(null, null),
            cons(null,       cons(1, 1)),
            cons(cons(1, 1), cons(1, 1))
        ]
    )
}
[1, undef, undef, '', 1, ''];

sub is_list {
    @_ == 1 or fp_croak_arity 1;
    my ($v) = @_;
    FORCE $v;
    (
        is_null($v) ? 1 : (
            is_pair($v) ? do {
                @_ = $v->cdr;
                goto \&is_list;
                }
            : ''
        )
    )
}
*FP::List::List::is_proper_sequence = \&is_list;

TEST { is_list cons 1, cons 2, null } 1;
TEST { is_list cons 1, cons 2, 3 } '';
TEST {
    require FP::Lazy;
    is_list cons 1, FP::Lazy::lazy { cons 2, null }
}
1;
TEST {
    is_list cons 1, FP::Lazy::lazy { cons 2, 3 }
}
'';

sub die_not_a_pair {
    @_ == 1 or fp_croak_arity 1;
    my ($v) = @_;
    croak "not a pair: " . show($v);
}

sub car {
    @_ == 1 or fp_croak_arity 1;
    my ($v) = @_;
    my $r = blessed($v) // die_not_a_pair($v);
    if ($r eq "FP::List::Pair") {
        $v->[0]
    } elsif (is_promise $v) {
        @_ = force $v;
        goto \&car;
    } else {
        $v->car
    }
}

sub first;
*first = \&car;

# XX add maybe_first and perhaps_first wrappers here? Shouldn't this
# be more structured/automatic, finally.

sub first_set {
    @_ == 2 or fp_croak_arity 2;
    my ($p, $v) = @_;
    cons($v, $p->rest)
}

TEST { cons(3, 4)->first_set("a") } bless ["a", 4], 'FP::List::Pair';

sub first_update {
    @_ == 2 or fp_croak_arity 2;
    my ($p, $fn) = @_;
    my ($v, $r)  = $p->first_and_rest;
    cons(&$fn($v), $r)
}

TEST {
    cons(3, 4)->first_update(sub { $_[0] * 2 })
}
bless [6, 4], 'FP::List::Pair';

sub cdr {
    @_ == 1 or fp_croak_arity 1;
    my ($v) = @_;
    my $r = blessed($v) // die_not_a_pair($v);
    if ($r->isa("FP::List::Pair")) {
        $v->[1]
    } elsif (is_promise $v) {
        @_ = force $v;
        goto \&cdr;
    } else {
        $v->cdr
    }
}

TEST { is_pair cons(2, 3) } 1;
TEST { is_pair "FP::List::Pair" } undef;
TEST { car cons(2, 3) } 2;
TEST_EXCEPTION { car "FP::List::Pair" } "not a pair: 'FP::List::Pair'";
TEST_EXCEPTION { cdr "FP::List::Pair" } "not a pair: 'FP::List::Pair'";

sub rest;
*rest = \&cdr;

sub cddr {
    @_ == 1 or fp_croak_arity 1;
    cdr cdr $_[0]
}

sub cdddr {
    @_ == 1 or fp_croak_arity 1;
    cdr cdr cdr $_[0]
}

sub cddddr {
    @_ == 1 or fp_croak_arity 1;
    cdr cdr cdr cdr $_[0]
}

sub cadr {
    @_ == 1 or fp_croak_arity 1;
    car cdr $_[0]
}

sub caddr {
    @_ == 1 or fp_croak_arity 1;
    car cdr cdr $_[0]
}

sub cadddr {
    @_ == 1 or fp_croak_arity 1;
    car cdr cdr cdr $_[0]
}

sub caddddr {
    @_ == 1 or fp_croak_arity 1;
    car cdr cdr cdr cdr $_[0]
}

sub c_r {
    @_ == 2 or fp_croak_arity 2;
    my ($s, $chain) = @_;
    my $c;
    while (length($c = chop $chain)) {
        $s
            = $c eq "a" ? car($s)
            : $c eq "d" ? cdr($s)
            :   die "only 'a' and 'd' acceptable in chain, have: '$chain'";
    }
    $s
}

*FP::List::List::c_r = \&c_r;

TEST { list(1, list(4, 7, 9), 5)->c_r("addad") }
9;

sub car_and_cdr {
    @_ == 1 or fp_croak_arity 1;
    my ($v) = @_;
    my $r = blessed($v) // die_not_a_pair($v);
    if ($r eq "FP::List::Pair") {
        @$v
    } elsif (is_promise $v) {
        @_ = force $v;
        goto \&car_and_cdr;
    } else {
        $v->car_and_cdr
    }
}

sub first_and_rest;
*first_and_rest = \&car_and_cdr;

sub perhaps_first_and_rest {
    @_ == 1 or fp_croak_arity 1;
    my ($v) = @_;
    my $r = blessed($v) // die_not_a_pair($v);
    if ($r eq "FP::List::Pair") {
        @$v
    } elsif (is_promise $v) {
        @_ = force $v;
        goto \&perhaps_first_and_rest;
    } elsif ($r eq "FP::List::Null") {
        ()
    } else {
        $v->perhaps_first_and_rest
    }
}

TEST { [cons(1, 2)->perhaps_first_and_rest] } [1, 2];
TEST { [null->perhaps_first_and_rest] } [];
TEST { [perhaps_first_and_rest cons(1, 2)] } [1, 2];
TEST { [perhaps_first_and_rest null] } [];
TEST_EXCEPTION { [perhaps_first_and_rest "FP::List::Null"] }
"not a pair: 'FP::List::Null'";    # and XX actually not a null either.

sub list_perhaps_one {
    @_ == 1 or fp_croak_arity 1;
    my ($s) = @_;
    FORCE $s;                      # make work for stre
    if (is_pair($s)) {
        my ($a, $r) = first_and_rest $s;
        if   (is_null $r) { ($a) }
        else              { () }
    } else {
        ()
    }
}

*FP::List::List::perhaps_one = \&list_perhaps_one;

TEST { [list(8)->perhaps_one] } [8];
TEST { [list(8, 9)->perhaps_one] } [];
TEST { [list()->perhaps_one] } [];

sub list_xone {
    @_ == 1 or fp_croak_arity 1;
    my ($s) = @_;
    FORCE $s;    # make work for streams
    if (is_pair($s)) {
        my ($a, $r) = first_and_rest $s;
        if (is_null $r) {
            $a
        } else {
            die "expected 1 value, got more"
        }
    } else {
        die "expected 1 value, got none"
    }
}

*FP::List::List::xone = \&list_xone;

TEST { [list(8)->xone] } [8];
TEST_EXCEPTION { [list(8, 9)->xone] } "expected 1 value, got more";
TEST_EXCEPTION { [list()->xone] } "expected 1 value, got none";

sub make_ref {
    my ($is_stream) = @_;
    my $liststream = $is_stream ? "stream" : "list";

    sub {
        @_ == 2 or fp_croak_arity 2;
        my ($s, $i) = @_;
        weaken $_[0] if $is_stream;
        is_natural0 $i or fp_croak "invalid index: " . show($i);
        my $orig_i = $i;
    LP: {
            $s = force $s;
            if (is_pair $s) {
                if ($i <= 0) {
                    $s->car
                } else {
                    $s = $s->cdr;
                    $i--;
                    redo LP;
                }
            } elsif (is_null $s) {
                die "requested element $orig_i of $liststream of length "
                    . ($orig_i - $i)
            } elsif (defined blessed($s) and my $m = $s->can("FP_Sequence_ref"))
            {
                @_ = ($s, $i);
                goto $m
            } else {
                die "improper $liststream"
            }
        }
    }
}

sub list_ref;
*list_ref            = make_ref(0);
*FP::List::List::ref = \&list_ref;

sub list {
    my $res = null;
    for (my $i = $#_; $i >= 0; $i--) {
        $res = cons($_[$i], $res);
    }
    $res
}

# Like 'list' but terminates the chain with the last argument instead
# of a 'null'. This shouldn't be used in normal circumstances. It's
# mainly here to make the output of FP_Show_show valid code.
sub improper_list {
    my $res = pop;
    for (my $i = $#_; $i >= 0; $i--) {
        $res = cons($_[$i], $res);
    }
    $res
}

# These violate the principle of a purely functional data
# structure. Are they ok since they are constructors (the outside
# world will never see mutation)? (Note that streams can be cyclic
# already without mutating the cons cells, by way of using a recursive
# binding (mutating the variable that holds it, "my $s; $s = cons 1,
# lazy { $s };").)

# WARNING: results of this function won't be deallocated
# automatically. You have to break the reference cycle explicitely!
sub circularlist {
    my $l    = list(@_);
    my $last = $l->drop($#_);
    if ($immutable) {
        Internals::SvREADONLY $$last[1], 0;
        $$last[1] = $l;
        Internals::SvREADONLY $$last[1], 1;
    } else {
        $$last[1] = $l;
    }
    $l
}

# And the result of this function will open up (interrupt the cycle)
# as soon as you let go of the front element.

sub weaklycircularlist {
    my $l    = list(@_);
    my $last = $l->drop($#_);
    if ($immutable) {
        Internals::SvREADONLY $$last[1], 0;
        $$last[1] = $l;
        weaken($$last[1]);
        Internals::SvREADONLY $$last[1], 1;
    } else {
        $$last[1] = $l;
        weaken($$last[1]);
    }
    $l
}

use Chj::Destructor;

TEST {
    my $z = 0;
    my $v = do {
        my $l = circularlist "a", "b", Destructor { $z++ }, "d";
        $l->ref(5)
    };
    [$z, $v]
}
[0, "b"];    # leaking the test list!

TEST {
    my $z = 0;
    my $v = do {
        my $l = weaklycircularlist "a", "b", Destructor { $z++ }, "d";
        $l->ref(5)
    };
    [$z, $v]
}
[1, "b"];    # no leak.

TEST_EXCEPTION {
    my $z = 0;
    my $v = do {
        my $l = weaklycircularlist "a", "b", Destructor { $z++ }, "d";
        $l = $l->rest;
        $l->ref(4)
    };
    [$z, $v]
}
'improper list';    # nice message at least, thanks to undef != null

sub delayed (&) {
    @_ == 1 or fp_croak_arity 1;
    my ($thunk) = @_;
    sub {
        # evaluate thunk, expecting a function and pass our arguments
        # to that function
        my $cont = &$thunk();
        goto &$cont
    }
}

sub list_of {
    @_ == 1 or fp_croak_arity 1;
    my ($p) = @_;
    either \&is_null, is_pair_of($p, delayed { list_of($p) })
}

TEST { list_of(\&is_natural)->(list 1,  2, 3) } 1;
TEST { list_of(\&is_natural)->(list -1, 2, 3) } 0;
TEST { list_of(\&is_natural)->(list 1,  2, " 3") } 0;
TEST { list_of(\&is_natural)->(1) } 0;
TEST { list_of(\&is_natural)->(list()) } 1;

sub nonempty_list_of {
    @_ == 1 or fp_croak_arity 1;
    my ($p) = @_;
    is_pair_of($p, delayed { list_of($p) })
}

TEST { nonempty_list_of(\&is_natural)->(list 1,  2, 3) } 1;
TEST { nonempty_list_of(\&is_natural)->(list -1, 2, 3) } 0;
TEST { nonempty_list_of(\&is_natural)->(list 1,  2, " 3") } 0;
TEST { nonempty_list_of(\&is_natural)->(1) } undef;      # XX vs. above
TEST { nonempty_list_of(\&is_natural)->(list()) } '';    # vs. 0 ?

sub make_length {
    my ($is_stream) = @_;
    my $liststream = $is_stream ? "stream" : "list";

    sub {
        @_ == 1 or fp_croak_arity 1;
        my ($l) = @_;
        weaken $_[0] if $is_stream;
        my $len = 0;
        $l = force $l;
        while (!is_null $l) {
            if (is_pair $l) {
                $len++;
                $l = force $l->cdr;
            } elsif (defined blessed($l)
                and my $m = $l->can("FP_Sequence_length"))
            {
                @_ = ($l, $len);
                goto $m
            } else {
                die "improper $liststream"
            }
        }
        $len
    }
}

sub list_length;
*list_length = make_length(0);

*FP::List::Pair::length = \&list_length;

# method on Pair not List, since we defined a length method for Null
# explicitely

TEST { list(4, 5, 6)->caddr } 6;
TEST { list()->length } 0;
TEST { list(4, 5)->length } 2;

sub list_to_string {
    @_ == 1 or fp_croak_arity 1;
    my ($l) = @_;
    my $len = list_length $l;

    # preallocation for the case where $l consists only of single
    # characters (otherwise will extend dynamically):
    my $res = " " x $len;
    my $i   = 0;
    while (!is_null $l) {
        my $c = car $l;
        substr($res, $i, 1) = $c;
        $l = cdr $l;
        $i += length $c;
    }
    $res
}

*FP::List::List::string = \&list_to_string;

TEST { null->string } "";
TEST { cons("a", null)->string } "a";
TEST { list("Ha", "ll", "o")->string } "Hallo";
TEST { list("", "", "o")->string } 'o';
TEST { list("a", "", "o")->string } 'ao';

sub list_to_array {
    @_ == 1 or fp_croak_arity 1;
    my ($l) = @_;
    my $res = [];
    my $i   = 0;
    while (!is_null $l) {
        $$res[$i] = car $l;
        $l = cdr $l;
        $i++;
    }
    $res
}

*FP::List::List::array = \&list_to_array;

sub list_to_purearray {
    @_ == 1 or fp_croak_arity 1;
    my ($l) = @_;
    my $a = list_to_array $l;
    require FP::PureArray;
    FP::PureArray::array_to_purearray($a)
}

*FP::List::List::purearray = \&list_to_purearray;

TEST {
    list(1, 3, 4)->purearray->map (sub { $_[0]**2 })
}
bless [1, 9, 16], "FP::_::PureArray";

sub list_sort {
    @_ == 1 or @_ == 2 or fp_croak_arity "1 or 2";
    my ($l, $maybe_cmp) = @_;
    list_to_purearray($l)->sort ($maybe_cmp)
}

*FP::List::List::sort = \&list_sort;

sub list_sortCompare {
    @_ == 1 or fp_croak_arity 1;
    my ($l) = @_;
    list_to_purearray($l)->sortCompare
}

*FP::List::List::sortCompare = \&list_sortCompare;

TEST {
    require FP::Ops;
    list(5, 3, 8, 4)->sort (\&FP::Ops::real_cmp)->array
}
[3, 4, 5, 8];

TEST { ref(list(5, 3, 8, 4)->sort (\&FP::Ops::real_cmp)) }
'FP::_::PureArray';    # XX ok? Need to `->list` if a list is needed

TEST { list(5, 3, 8, 4)->sort (\&FP::Ops::real_cmp)->list->car }
3;    # but then PureArray has `first`, too, if that's all you need.

TEST { list(5, 3, 8, 4)->sort (\&FP::Ops::real_cmp)->first }
3;

#(just for completeness)
TEST { list(5, 3, 8, 4)->sort (\&FP::Ops::real_cmp)->stream->car }
3;

sub rlist_to_array {
    @_ == 1 or fp_croak_arity 1;
    my ($l) = @_;
    my $res = [];
    my $len = list_length $l;
    my $i   = $len;
    while (!is_null $l) {
        $i--;
        $$res[$i] = car $l;
        $l = cdr $l;
    }
    $res
}

*FP::List::List::reverse_array = \&rlist_to_array;

sub list_to_values {
    @_ == 1 or fp_croak_arity 1;
    my ($l) = @_;
    @{ list_to_array($l) }
}

*FP::List::List::values = \&list_to_values;

# XX naming inconsistency versus docs/design.md ? Same with
# rlist_to_array.
sub rlist_to_values {
    @_ == 1 or fp_croak_arity 1;
    my ($l) = @_;
    @{ rlist_to_array($l) }
}

*FP::List::List::reverse_values = \&rlist_to_values;

TEST { [list(3, 4, 5)->reverse_values] }
[5, 4, 3];

sub make_for_each {
    @_ == 2 or fp_croak_arity 2;
    my ($is_stream, $with_islast) = @_;
    my $liststream = $is_stream ? "stream" : "list";

    sub {
        @_ == 2 or fp_croak_arity 2;
        my ($proc, $s) = @_;
        weaken $_[1] if $is_stream;
    LP: {
            $s = force $s;
            if (is_pair $s) {
                my $s2 = cdr $s;
                &$proc(scalar car($s), $with_islast ? scalar is_null($s2) : ());
                $s = $s2;
                redo LP;
            } elsif (is_null $s) {

                # drop out
            } elsif (defined blessed($s) and my $m = $s->can("for_each")) {
                @_ = ($s, $proc);
                goto $m
            } else {
                die "improper $liststream"
            }
        }
    }
}

sub list_for_each;
*list_for_each            = make_for_each(1, 0);
*FP::List::List::for_each = flip \&list_for_each;

sub list_for_each_with_islast;
*list_for_each_with_islast            = make_for_each(1, 1);
*FP::List::List::for_each_with_islast = flip \&list_for_each_with_islast;

TEST_STDOUT {
    list(1, 3)->for_each(\&xprintln)
}
"1\n3\n";

# tons of slightly adapted COPIES from FP::Stream. XX finally find a
# solution for this

sub list_drop {
    @_ == 2 or fp_croak_arity 2;
    my ($s, $n) = @_;
    while ($n > 0) {
        $s = force $s;
        die "list too short" if is_null $s;
        $s = cdr $s;
        $n--
    }
    $s
}

*FP::List::List::drop = \&list_drop;

sub list_take {
    @_ == 2 or fp_croak_arity 2;
    my ($s, $n) = @_;
    if ($n > 0) {
        $s = force $s;
        is_null($s) ? $s : cons(car($s), list_take(cdr($s), $n - 1));
    } else {
        null
    }
}

*FP::List::List::take = \&list_take;

sub list_slice {
    @_ == 2 or fp_croak_arity 2;
    my ($start, $end) = @_;
    $end = force $end;
    my $rec;
    $rec = sub {
        my ($s) = @_;
        my $rec = $rec;
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
    };
    @_ = ($start);
    goto &{ Weakened $rec};
}

*FP::List::List::slice = \&list_slice;

# maybe call it `cut_at` instead?

# /COPIES

sub string_to_list {
    @_ >= 1 and @_ <= 2 or fp_croak_arity "1-2";
    my ($str, $maybe_tail) = @_;
    my $tail = $maybe_tail // null;
    my $i    = length($str) - 1;
    while ($i >= 0) {
        $tail = cons(substr($str, $i, 1), $tail);
        $i--;
    }
    $tail
}

TEST { [list_to_values string_to_list "abc"] }
['a', 'b', 'c'];
TEST { list_length string_to_list "ao" }
2;
TEST { list_to_string string_to_list "Hello" }
'Hello';

# XX HACK, COPY from FP::Array to work around circular dependency
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

sub array_fold {
    @_ == 3 or fp_croak_arity 3;
    my ($fn, $start, $ary) = @_;
    for (@$ary) {
        $start = &$fn($_, $start);
    }
    $start
}

# /HACK

sub array_to_list {
    @_ >= 1 and @_ <= 2 or fp_croak_arity "1-2";
    my ($a, $maybe_tail) = @_;
    array_fold_right(\&cons, $maybe_tail // null, $a)
}

TEST { list_to_string array_to_list [1, 2, 3] }
'123';

# XX naming correct?
sub array_to_list_reverse {
    @_ >= 1 and @_ <= 2 or fp_croak_arity "1-2";
    my ($a, $maybe_tail) = @_;
    array_fold(\&cons, $maybe_tail // null, $a)
}

TEST { list_to_string array_to_list_reverse [1, 2, 3] }
'321';

sub list_reverse_with_tail {
    @_ == 2 or fp_croak_arity 2;
    my ($l, $tail) = @_;
    while (!is_null $l) {
        $tail = cons car($l), $tail;
        $l    = cdr $l;
    }
    $tail
}

sub list_reverse {
    @_ == 1 or fp_croak_arity 1;
    my ($l) = @_;
    list_reverse_with_tail($l, $l->null)
}

*FP::List::List::reverse_with_tail = \&list_reverse_with_tail;
*FP::List::List::reverse           = \&list_reverse;

TEST { list_to_string list_reverse string_to_list "Hello" }
'olleH';

sub list_strings_join {
    @_ == 2 or fp_croak_arity 2;
    my ($l, $val) = @_;

    # now depend on FP::Array anyway. Lazily. XX hack~
    require FP::Array;
    FP::Array::array_strings_join(list_to_array($l), $val);
}

*FP::List::List::strings_join = \&list_strings_join;

TEST { list(1, 2, 3)->strings_join("-") }
"1-2-3";

sub list_strings_join_reverse {
    @_ == 2 or fp_croak_arity 2;
    my ($l, $val) = @_;

    # now depend on FP::Array anyway. Lazily. XX hack~
    require FP::Array;
    FP::Array::array_strings_join(rlist_to_array($l), $val);
}

*FP::List::List::strings_join_reverse = \&list_strings_join_reverse;

TEST { list(1, 2, 3)->strings_join_reverse("-") }
"3-2-1";

# write as a S-expr (trying to follow R5RS Scheme)
sub _write_sexpr {
    @_ == 3 or fp_croak_arity 3;
    my ($l, $fh, $already_in_a_list) = @_;
_WRITE_SEXPR: {
        $l = force($l, 1);
        if (is_pair $l) {
            xprint $fh, $already_in_a_list ? ' ' : '(';
            _write_sexpr(car($l), $fh, 0);
            my $d = force(cdr($l), 1);
            if (is_null $d) {
                xprint $fh, ')';
            } elsif (is_pair $d) {

                # tail-calling _write_sexpr $d, $fh, 1
                $l                 = $d;
                $already_in_a_list = 1;
                redo _WRITE_SEXPR;
            } else {
                xprint $fh, " . ";
                _write_sexpr($d, $fh, 0);
                xprint $fh, ')';
            }
        } elsif (is_null $l) {
            xprint $fh, "()";
        } else {

            # normal perl things; should have a show method already
            # for this? whatever.
            if (ref $l) {
                die "don't know how to write_sexpr this: " . show($l);
            } else {

                # assume string; there's nothing else left.
                $l =~ s/"/\\"/sg;
                xprint $fh, '"', $l, '"';
            }
        }
    }
}

sub write_sexpr {
    @_ == 1 or fp_croak_arity 1;
    my ($l, $fh) = @_;
    _write_sexpr($l, $fh || *STDOUT{IO}, 0)
}

TEST_STDOUT { write_sexpr cons("123", cons("4", null)) }
'("123" "4")';
TEST_STDOUT { write_sexpr(string_to_list "Hello \"World\"") }
'("H" "e" "l" "l" "o" " " "\"" "W" "o" "r" "l" "d" "\"")';
TEST_STDOUT { write_sexpr(cons 1, 2) }
'("1" . "2")';

#TEST_STDOUT{ write_sexpr cons(1, cons(cons(2, undef), undef))}
#  '';
# -> XX should print #f or something for undef ! Not give exception.
TEST_STDOUT { write_sexpr cons(1, cons(cons(2, null), null)) }
'("1" ("2"))';

*FP::List::List::write_sexpr = \&write_sexpr;

# adapted copy of stream_map_with_tail, as usual...
sub list_map_with_tail {
    @_ == 3 or fp_croak_arity 3;
    my ($fn, $l, $tail) = @_;
    FORCE $l;    # be careful as usual, right?
    is_null($l)
        ? $tail
        : cons(&$fn(car $l), list_map_with_tail($fn, cdr($l), $tail))
}

*FP::List::List::map_with_tail = flip2of3 \&list_map_with_tail;

sub improper_last {
    @_ == 1 or fp_croak_arity "1";
    my ($l) = @_;
    while (is_pair($l)) {
        $l = cdr($l);
    }
    $l
}

*FP::List::List::improper_last = \&improper_last;

sub improper_map {
    @_ == 2 or @_ == 3 or fp_croak_arity "2-3";
    my ($fn, $l, $maybe_tail) = @_;
    FORCE $l;    # be careful as usual, right?
    if (is_null($l)) {
        $maybe_tail // $l
    } elsif (is_pair($l)) {
        cons($fn->(car $l), improper_map($fn, cdr($l), $maybe_tail))
    } else {
        $fn->($l)
    }
}

sub FP::List::List::improper_map {
    @_ == 2 or @_ == 3 or fp_croak_arity "2-3";
    my ($l, $fn, $maybe_tail) = @_;
    @_ = ($fn, $l, $maybe_tail);
    goto \&improper_map
}

TEST_STDOUT {
    write_sexpr cons(1, cons(2, 3))->improper_map(sub { $_[0] * 2 })
}
'("2" "4" . "6")';

sub improper_filtermap {
    __ 'improper_filtermap($fn, $l, $maybe_tail):
        If $fn returns (), the position is discarded in the resulting
        sequence. $fn cannot return multiple values, though.';
    @_ == 2 or @_ == 3 or fp_croak_arity "2-3";
    my ($fn, $l, $maybe_tail) = @_;
    FORCE $l;    # be careful as usual, right?
    if (is_null($l)) {
        $maybe_tail // $l
    } elsif (is_pair($l)) {
        my @v = $fn->(car $l);
        my $r = improper_filtermap($fn, cdr($l), $maybe_tail);
        if (@v == 1) {
            cons($v[0], $r)
        } elsif (!@v) {
            $r
        } else {
            die "not supporting multiple value returns from \$fn";
        }
    } else {
        my @v = $fn->($l);
        if (@v == 1) {
            $v[0]
        } elsif (!@v) {

            # Converting a possibly single input item into an empty
            # list. (Only if improper_filtermap were itself perhaps_*,
            # we could handle this case otherwise. Perl list context
            # is magic?)
            $maybe_tail // null
        } else {
            die "not supporting multiple value returns from \$fn";
        }
    }
}

sub FP::List::List::improper_filtermap {
    @_ == 2 or @_ == 3 or fp_croak_arity "2-3";
    my ($l, $fn, $maybe_tail) = @_;
    @_ = ($fn, $l, $maybe_tail);
    goto \&improper_filtermap
}

TEST_STDOUT {
    write_sexpr cons(1, cons(2, cons(3, 4)))
        ->improper_filtermap(sub { $_[0] * 2 })
}
'("2" "4" "6" . "8")';

TEST_STDOUT {
    write_sexpr cons(1, cons(2, cons(3, 4)))->improper_filtermap(
        sub {
            my $v = $_[0] * 2;
            $v == 6 ? () : $v
        }
    )
}
'("2" "4" . "8")';

TEST_STDOUT {
    write_sexpr cons(1, cons(2, cons(3, 4)))->improper_filtermap(
        sub {
            my $v = $_[0] * 2;
            $v == 8 ? () : $v
        }
    )
}
'("2" "4" "6")';

# mostly COPY-PASTE from improper_filtermap
sub list_filtermap {
    __ 'list_filtermap($fn, $l, $maybe_tail):
        If $fn returns (), the position is discarded in the resulting
        sequence. $fn cannot return multiple values, though.';
    @_ == 2 or @_ == 3 or fp_croak_arity "2-3";
    my ($fn, $l, $maybe_tail) = @_;
    FORCE $l;    # be careful as usual, right?
    if (is_null($l)) {
        $maybe_tail // $l
    } elsif (is_pair($l)) {
        my @v = $fn->(car $l);
        my $r = improper_filtermap($fn, cdr($l), $maybe_tail);
        if (@v == 1) {
            cons($v[0], $r)
        } elsif (!@v) {
            $r
        } else {
            die "not supporting multiple value returns from \$fn";
        }
    } else {
        die "improper list"
    }
}

sub FP::List::List::filtermap {
    @_ == 2 or @_ == 3 or fp_croak_arity "2-3";
    my ($l, $fn, $maybe_tail) = @_;
    @_ = ($fn, $l, $maybe_tail);
    goto \&list_filtermap
}

sub list_zip2 {
    @_ == 2 or fp_croak_arity 2;
    my ($l, $m) = @_;
    (     is_null($l) ? $l
        : is_null($m) ? $m
        :               cons([car($l), car($m)], list_zip2(cdr($l), cdr($m))))
}

TEST { list_to_array list_zip2 list(qw(a b c)), list(2, 3) }
[[a => 2], [b => 3]];

TEST { list_to_array list_zip2 list(qw(a b)), list(2, 3, 4) }
[[a => 2], [b => 3]];

*FP::List::List::zip = \&list_zip2;    # XX make n-ary

sub list_to_alist {
    @_ == 1 or fp_croak_arity 1;
    my ($l) = @_;
    is_null($l) ? $l : do {
        my ($k, $l2) = $l->first_and_rest;
        my ($v, $l3) = $l2->first_and_rest;
        cons(cons($k, $v), list_to_alist($l3))
    }
}
*FP::List::List::alist = \&list_to_alist;

TEST_STDOUT { list(a => 10, b => 20)->alist->write_sexpr }
'(("a" . "10") ("b" . "20"))';

sub make_filter {
    my ($is_stream) = @_;
    my $filter;
    $filter = sub {
        @_ == 2 or fp_croak_arity 2;
        my ($fn, $l) = @_;
        weaken $_[1] if $is_stream;
        lazy_if {
            no warnings 'recursion';    # XXX this should be tail calling???
            $l = force $l;
            is_null($l) ? $l : do {
                my ($a, $r) = $l->first_and_rest;
                no warnings 'recursion';
                my $r2 = &$filter($fn, $r);
                &$fn($a) ? cons($a, $r2) : $r2
            }
        }
        $is_stream;
    };
    Weakened($filter)
}

sub list_filter;
*list_filter = make_filter(0);

*FP::List::List::filter = flip \&list_filter;

# almost-COPY of filter
sub make_filter_with_tail {
    my ($is_stream) = @_;
    my $filter_with_tail;
    $filter_with_tail = sub {
        @_ == 3 or fp_croak_arity 3;
        my ($fn, $l, $tail) = @_;
        weaken $_[1] if $is_stream;
        lazy_if {
            $l = force $l;
            is_null($l) ? $tail : do {
                my $a = car $l;
                my $r = &$filter_with_tail($fn, cdr($l), $tail);
                &$fn($a) ? cons($a, $r) : $r
            }
        }
        $is_stream;
    };
    Weakened($filter_with_tail)
}

sub list_filter_with_tail;
*list_filter_with_tail            = make_filter_with_tail(0);
*FP::List::List::filter_with_tail = flip2of3 \&list_filter_with_tail;

sub list_map {
    @_ == 2 or fp_croak_arity 2;
    my ($fn, $l) = @_;
    is_null($l) ? $l : cons(
        scalar &$fn(car $l),
        do {
            no warnings 'recursion';
            list_map($fn, cdr $l)
        }
    )
}

TEST {
    list_to_array list_map sub { $_[0] * $_[0] }, list 1, 2, -3
}
[1, 4, 9];

# n-ary map
sub list_mapn {
    my $fn = shift;
    for (@_) {
        return $_ if is_null $_
    }
    cons(&$fn(map { car $_} @_), list_mapn($fn, map { cdr $_} @_))
}

TEST {
    list_to_array list_mapn(sub { [@_] }, array_to_list([1, 2, 3]),
        string_to_list(""))
}
[];
TEST {
    list_to_array list_mapn(sub { [@_] }, array_to_list([1, 2, 3]),
        string_to_list("ab"))
}
[[1, 'a'], [2, 'b']];

sub FP::List::List::map {
    @_ >= 2 or fp_croak_arity ">= 2";
    my $l  = shift;
    my $fn = shift;
    @_ ? list_mapn($fn, $l, @_) : list_map($fn, $l)
}

sub list_map_with_index_ {
    my $i  = shift;
    my $fn = shift;
    for (@_) {
        return $_ if is_null $_
    }
    cons(&$fn($i, map { car $_} @_),
        list_map_with_index_($i + 1, $fn, map { cdr $_} @_))
}

sub list_map_with_index {
    @_ >= 2 or fp_croak_arity ">= 2";
    list_map_with_index_(0, @_)
}

sub FP::List::List::map_with_index {
    @_ >= 2 or fp_croak_arity ">= 2";
    my $l  = shift;
    my $fn = shift;
    list_map_with_index($fn, $l, @_)
}

TEST {
    list(1, 2, 20)->map_with_index(sub { [@_] })->array
}
[[0, 1], [1, 2], [2, 20]];

sub list_map_with_islast {
    @_ >= 2 or fp_croak_arity ">= 2";
    my $fn      = shift;
    my @rest    = map { is_null($_) ? return null : rest $_ } @_;
    my $is_last = '';

    # return *number* of ending streams, ok? XX this is unlike
    # array_map_with_islast
    for (@rest) { $is_last++ if is_null $_ }
    cons(&$fn($is_last, map { $_->first } @_), list_map_with_islast($fn, @rest))
}

sub FP::List::List::map_with_islast {
    my ($l0, $fn, @l) = @_;
    list_map_with_islast($fn, $l0, @l)
}

TEST {
    list(1, 2, 20)->map_with_islast(sub { $_[0] })->array
}
['', '', 1];

TEST {
    list(1, 2, 20)->map_with_islast(sub { [@_] }, list "b", "c")->array
}
[['', 1, "b"], [1, 2, "c"]];

# left fold, sometimes called `foldl` or `reduce`
# (XX adapted copy from Stream.pm)
sub list_fold {
    @_ == 3 or fp_croak_arity 3;
    my ($fn, $start, $l) = @_;
    my $v;
LP: {
        if (is_pair $l) {
            ($v, $l) = first_and_rest $l;
            $start = &$fn($v, $start);
            redo LP;
        }
    }
    $start
}

*FP::List::List::fold = rot3left \&list_fold;

TEST { list_fold(\&cons, null, list(1, 2))->array }
[2, 1];

TEST {
    list(1, 2, 3)->map(sub { $_[0] + 1 })->fold(sub { $_[0] + $_[1] }, 0)
}
9;

sub list_fold_right {
    @_ == 3 or fp_croak_arity 3;
    my ($fn, $start, $l) = @_;
    if (is_pair $l) {
        no warnings 'recursion';
        my $rest = list_fold_right($fn, $start, cdr $l);
        &$fn(car($l), $rest)
    } elsif (is_null $l) {
        $start
    } else {
        die "improper list"
    }
}

TEST {
    list_fold_right sub {
        my ($v, $res) = @_;
        [$v, @$res]
    }, [], list(4, 5, 9)
}
[4, 5, 9];

sub FP::List::List::fold_right {
    my $l = shift;
    @_ == 2 or fp_croak_arity 2;
    my ($fn, $start) = @_;
    list_fold_right($fn, $start, $l)
}

TEST {
    list(1, 2, 3)->map(sub { $_[0] + 1 })->fold_right(sub { $_[0] + $_[1] }, 0)
}
9;

# same as fold_right but passes the whole list remainder instead of
# only the car to the function
sub list_pair_fold_right {
    @_ == 3 or fp_croak_arity 3;
    my ($fn, $start, $l) = @_;
    if (is_pair $l) {
        no warnings 'recursion';
        my $rest = list_pair_fold_right($fn, $start, cdr $l);
        &$fn($l, $rest)
    } elsif (is_null $l) {
        $start
    } else {
        die "improper list"
    }
}

*FP::List::List::pair_fold_right = rot3left \&list_pair_fold_right;

TEST_STDOUT { list(5, 6, 9)->pair_fold_right(\&cons, null)->write_sexpr }
'(("5" "6" "9") ("6" "9") ("9"))';

# no list_ prefix? It doesn't consume lists. Although, still FP::List
# specific. But there's no way to shorten it by way of method
# calling. For FP::Stream, call it stream_unfold, similarly for other
# *'special'* kinds of lists?

# unfold p f g seed [tail-gen] -> list

# p: predicate function, wenn true for seed stops production;
# f: function to produce output value from seed;
# g: function to produce the next seed value;
# seed: the initial seed value;
# tail-gen: optional function to map the last seed value, the value
#           `null` is taken otherwise

# For more documentation, see
# http://srfi.schemers.org/srfi-1/srfi-1.html#FoldUnfoldMap

sub unfold {
    @_ == 4 or @_ == 5 or fp_croak_arity "4 or 5";
    my ($p, $f, $g, $seed, $maybe_tail_gen) = @_;
    &$p($seed)
        ? (defined $maybe_tail_gen ? &$maybe_tail_gen($seed) : null)
        : cons(&$f($seed), unfold($p, $f, $g, &$g($seed), $maybe_tail_gen));
}

TEST { unfold(\&is_zero, \&inc, \&dec, 5)->array } [6, 5, 4, 3, 2];
TEST { unfold(\&is_zero, \&inc, \&dec, 5, \&list)->array } [6, 5, 4, 3, 2, 0];

# unfold-right p f g seed [tail] -> list

sub unfold_right {
    @_ == 4 or @_ == 5 or fp_croak_arity "4 or 5";
    my ($p, $f, $g, $seed, $maybe_tail) = @_;
    my $tail = @_ == 5 ? $maybe_tail : null;
LP: {
        if (&$p($seed)) {
            $tail
        } else {
            ($seed, $tail) = (&$g($seed), cons(&$f($seed), $tail));
            redo LP;
        }
    }
}

TEST { unfold_right(\&is_zero, \&inc, \&dec, 5)->array } [2, 3, 4, 5, 6];
TEST { unfold_right(\&is_zero, \&inc, \&dec, 5, list 99)->array }
[2, 3, 4, 5, 6, 99];

sub list_append {
    my $l = @_ ? shift : null;
    while (@_) {
        my $l2 = shift;
        $l = list_fold_right(\&cons, $l2, $l)
    }
    $l
}

TEST {
    list_append list(1, 2, 3), list("a", "b"), list(4, 5)
}
list(1, 2, 3, 'a', 'b', 4, 5);

TEST {list_append} list();

TEST {
    list_to_array list_append(array_to_list(["a", "b"]), array_to_list([1, 2]))
}
['a', 'b', 1, 2];

*FP::List::List::append = \&list_append;

TEST { array_to_list(["a", "b"])->append(array_to_list([1, 2]))->array }
['a', 'b', 1, 2];

sub list_to_perlstring {
    @_ == 1 or fp_croak_arity 1;
    my ($l) = @_;
    list_to_string cons(
        "'",
        list_fold_right sub {
            my ($c, $rest) = @_;
            my $out = cons($c, $rest);
            if ($c eq "'") {
                cons("\\", $out)
            } else {
                $out
            }
        },
        cons("'", null),
        $l
    )
}

TEST { list_to_perlstring string_to_list "Hello" }
"'Hello'";
TEST { list_to_perlstring string_to_list "Hello's" }
q{'Hello\'s'};

*FP::List::List::perlstring = \&list_to_perlstring;

sub list_butlast {
    @_ == 1 or fp_croak_arity 1;
    my ($l) = @_;
    if (is_null($l)) {
        die "butlast: got empty list"

            # XX could make use of OO for the distinction instead
    } else {
        my ($a, $r) = $l->first_and_rest;
        is_null($r) ? $r : cons($a, list_butlast($r))
    }
}

*FP::List::List::butlast = \&list_butlast;

TEST { list(3, 4, 5)->butlast->array }
[3, 4];
TEST_EXCEPTION { list()->butlast->array }
'can\'t take the butlast of the empty list';

sub list_drop_while {
    @_ == 2 or fp_croak_arity 2;
    my ($pred, $l) = @_;
    while (!is_null $l and &$pred(car $l)) {
        $l = cdr $l;
    }
    $l
}

TEST {
    list_to_string list_drop_while(sub { $_[0] ne 'X' },
        string_to_list "Hello World")
}
"";
TEST {
    list_to_string list_drop_while(sub { $_[0] ne 'o' },
        string_to_list "Hello World")
}
"o World";

*FP::List::List::drop_while = flip \&list_drop_while;

TEST {
    string_to_list("Hello World")->drop_while(sub { $_[0] ne 'o' })->string
}
"o World";

sub list_rtake_while_and_rest {
    @_ == 2 or fp_croak_arity 2;
    my ($pred, $l) = @_;
    my $res = $l->null;
    my $c;
    while (!is_null $l and &$pred($c = $l->car)) {
        $res = cons $c, $res;
        $l   = $l->cdr;
    }
    ($res, $l)
}

*FP::List::List::rtake_while_and_rest = flip \&list_rtake_while_and_rest;

sub list_rtake_while {
    @_ == 2 or fp_croak_arity 2;
    my ($pred, $l)    = @_;
    my ($res,  $rest) = list_rtake_while_and_rest($pred, $l);
    $res
}

*FP::List::List::rtake_while = flip \&list_rtake_while;

TEST {
    list_to_string list_reverse(list_rtake_while \&char_is_alphanumeric,
        string_to_list "Hello World")
}
'Hello';

sub list_take_while_and_rest {
    @_ == 2 or fp_croak_arity 2;
    my ($pred, $l)    = @_;
    my ($rres, $rest) = list_rtake_while_and_rest($pred, $l);
    (list_reverse($rres), $rest)
}

*FP::List::List::take_while_and_rest = flip \&list_take_while_and_rest;

sub list_take_while {
    @_ == 2 or fp_croak_arity 2;
    my ($pred, $l)    = @_;
    my ($res,  $rest) = list_take_while_and_rest($pred, $l);
    $res
}

*FP::List::List::take_while = flip \&list_take_while;

TEST {
    list_to_string list_take_while(sub { $_[0] ne 'o' },
        string_to_list "Hello World")
}
"Hell";
TEST {
    list_to_string list_take_while(sub { $_[0] eq 'H' },
        string_to_list "Hello World")
}
"H";
TEST {
    list_to_string list_take_while(sub {1}, string_to_list "Hello World")
}
"Hello World";
TEST {
    list_to_string list_take_while(sub {0}, string_to_list "Hello World")
}
"";

sub list_last {
    @_ == 1 or fp_croak_arity 1;
    my ($v) = @_;
LIST_LAST: {
        my ($a, $r) = $v->first_and_rest;
        if (is_null $r) {
            $a
        } else {
            $v = $r;
            redo LIST_LAST;
        }
    }
}

*FP::List::List::last = \&list_last;

TEST { list(qw(a b c))->last } 'c';
TEST { list(qw(a))->last } 'a';
TEST_EXCEPTION { list(qw())->last }
"can't take the first_and_rest of the empty list";

# XX add stream_last to Stream.pm (only change as usual: deallocate head)

# XX: add list_last_pair (see SRFI 1)

sub list_every {
    @_ == 2 or fp_croak_arity 2;
    my ($pred, $l) = @_;
LP: {
        if (is_pair $l) {
            my $r = &$pred(car $l);
            if ($r) {
                $l = cdr $l;
                redo LP;
            } else {
                $r
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

*FP::List::List::every = flip \&list_every;

# XXX do we want this alias? Or do we just want to rename every to
# all?
sub list_all;
*list_all = \&list_every;

*FP::List::List::all = flip \&list_every;

TEST {
    [
        map {
            list_every sub { $_[0] > 0 }, $_
        } list(1, 2, 3),
        list(1, 0, 3),
        list(),
    ]
}
[1, '', 1];

use FP::Char 'char_is_alphanumeric';

TEST { string_to_list("Hello")->every(\&char_is_alphanumeric) }
1;
TEST { string_to_list("Hello ")->every(\&char_is_alphanumeric) }
'';

# none is defined in FP::Abstract::Sequence
TEST { string_to_list("Hello")->none(\&char_is_alphanumeric) }
0;
TEST { string_to_list(" -()&")->none(\&char_is_alphanumeric) }
1;
TEST {
    my $z = 0;
    my $r = string_to_list(" -()&a")
        ->none(sub { $z++; char_is_alphanumeric $_[0] });
    [$z, $r]
}
[6, 0];
TEST {
    my $z = 0;
    my $r = string_to_list(" a-()&a")
        ->none(sub { $z++; char_is_alphanumeric $_[0] });
    [$z, $r]
}
[2, 0];

sub list_any {
    @_ == 2 or fp_croak_arity 2;
    my ($pred, $l) = @_;
    my $v;
LP: {
        if (is_pair $l) {
            ($v = &$pred(car $l)) or do {
                $l = cdr $l;
                redo LP;
            }
        } elsif (is_null $l) {
            $v
        } else {
            die "improper list"
        }
    }
}

*FP::List::List::any = flip \&list_any;

TEST {
    list_any sub { $_[0] % 2 }, array_to_list [2, 4, 8]
}
0;
TEST {
    list_any sub { $_[0] % 2 }, array_to_list []
}
undef;
TEST {
    list_any sub { $_[0] % 2 }, array_to_list [2, 5, 8]
}
1;
TEST {
    list_any sub { $_[0] % 2 }, array_to_list [7]
}
1;

# The following two functions differ from their paragons from SRFI-1
# in that they do not return false or undef on failure, but (), and
# carry `perhaps` in their name of this reason.

sub list_perhaps_find_tail {
    @_ == 2 or fp_croak_arity 2;
    my ($fn, $l) = @_;
LP: {
        if (is_null $l) { () }
        else {
            my ($v, $l1) = $l->first_and_rest;
            if (&$fn($v)) {
                $l
            } else {
                $l = $l1;
                redo LP
            }
        }
    }
}

*FP::List::List::perhaps_find_tail = flip \&list_perhaps_find_tail;

TEST {
    list(3, 1, 37, -8, -5, 0, 0)->perhaps_find_tail(\&is_even)->array
}
[-8, -5, 0, 0];
TEST { [list(3, 1, 37, -5)->perhaps_find_tail(\&is_even)] }
[];

sub list_perhaps_find {
    @_ == 2 or fp_croak_arity 2;
    my ($fn, $l) = @_;
    if (my ($l) = list_perhaps_find_tail($fn, $l)) {
        $l->car
    } else {
        ()
    }
}

*FP::List::List::perhaps_find = flip \&list_perhaps_find;

TEST { list(3, 1, 4, 1, 5, 9)->perhaps_find(\&is_even) }
4;

# And then still also add the SRFI-1 counterparts, without `maybe` in
# the names as they should have according to our guidelines, XX hmm.

sub list_find_tail;
*list_find_tail            = perhaps_to_maybe(\&list_perhaps_find_tail);
*FP::List::List::find_tail = flip \&list_find_tail;

sub list_find;
*list_find            = perhaps_to_maybe(\&list_perhaps_find);
*FP::List::List::find = flip \&list_find;

TEST { list(3, 1, 4, 1, 5, 9)->find(\&is_even) }
4;
TEST { list(3, 1, 37, -8, -5, 0, 0)->find_tail(\&is_even)->array }
[-8, -5, 0, 0];
TEST { [list(3, 1, 37, -5)->find_tail(\&is_even)] }
[undef];

# Grouping

sub make_group {
    my ($is_stream) = @_;
    sub {
        @_ >= 2 and @_ <= 3 or fp_croak_arity "2-3";
        my ($equal, $s, $maybe_tail) = @_;
        weaken $_[1] if $is_stream;
        lazy_if {
            FORCE $s;
            if (is_null $s) {
                $maybe_tail // null
            } else {
                my ($a, $r) = $s->first_and_rest;
                my $rec;
                $rec = sub {
                    my ($prev, $s) = @_;
                    lazy_if {
                        my $s     = $s;
                        my $group = cons $prev, null;
                    LP: {
                            FORCE $s;
                            if (is_null $s) {
                                cons $group, ($maybe_tail // null)
                            } else {
                                my ($a, $r) = $s->first_and_rest;
                                if (&$equal($prev, $a)) {
                                    $s     = $r;
                                    $group = cons $a, $group;
                                    redo LP;
                                } else {
                                    cons $group, &$rec($a, $r)
                                }
                            }
                        }
                    }
                    $is_stream;
                };

                # TCO?
                ##XXX disable for v5.20.2 (Debian), wtf   Weakened
                ($rec)->($a, $r)
            }
        }
        $is_stream
    }
}

sub list_group;
*list_group = make_group(0);

sub FP::List::List::group {
    __
        'group($self, $equal, $maybe_tail): build groups of subsequent items that are $equal.';
    @_ >= 2 and @_ <= 3 or fp_croak_arity "2-3";
    my ($self, $equal, $maybe_tail) = @_;
    list_group($equal, $self, $maybe_tail)
}

TEST {
    list(3, 4, 4, 5, 6, 8, 5, 5)->group(\&FP::Ops::number_eq)
}
list(list(3), list(4, 4), list(5), list(6), list(8), list(5, 5));

# Split on items for which the predicate returns true:

sub make_split {
    my ($is_stream) = @_;
    sub {
        __
            'split($self, $pred, $retain_item, $maybe_tail): split on items for which $pred returns true. If $retain_item is true, the item that matched will be included in the previous group.';
        @_ >= 2 and @_ <= 4 or fp_croak_arity "2-4";

        require FP::PureArray;

        my ($s, $pred, $retain_item, $maybe_tail) = @_;
        weaken $_[1] if $is_stream;
        lazy_if {
            FORCE $s;
            if (is_null $s) {
                $maybe_tail // null
            } else {
                my $rec;
                $rec = sub {
                    my ($s) = @_;
                    lazy_if {
                        my $s = $s;
                        my @group;
                    LP: {
                            FORCE $s;
                            if (is_null $s) {
                                if (@group) {
                                    cons(
                                        FP::PureArray::array_to_purearray(
                                            \@group),
                                        ($maybe_tail // null)
                                    )
                                } else {
                                    ($maybe_tail // null)
                                }
                            } else {
                                my ($a, $r) = $s->first_and_rest;
                                if ($pred->($a)) {
                                    if ($retain_item) {
                                        push @group, $a;
                                    }
                                    cons(
                                        FP::PureArray::array_to_purearray(
                                            \@group),
                                        $rec->($r)
                                    )
                                } else {
                                    $s = $r;
                                    push @group, $a;
                                    redo LP;
                                }
                            }
                        }
                    }
                    $is_stream;
                };
                $rec->($s)
            }
        }
        $is_stream
    }
}

sub list_split;
*list_split = make_split(0);

*FP::List::List::split = \&list_split;

# For split tests see FP::List::t.

# Turn a mix of (nested) arrays and lists into a flat list.

# If the third argument is given, it needs to be a reference to either
# lazy or lazyLight. In that case it will force promises, but only
# lazily (i.e. provide a promise that will do the forcing and consing).

sub mixed_flatten {
    @_ >= 1 and @_ <= 3 or fp_croak_arity "1-3";
    my ($v, $maybe_tail, $maybe_delay) = @_;
    my $tail = $maybe_tail // null;
LP: {
        if ($maybe_delay and is_promise $v) {
            my $delay = $maybe_delay;
            &$delay(
                sub {
                    @_ = (force($v), $tail, $delay);
                    goto \&mixed_flatten;
                }
            );
        } else {
            if (is_null $v) {
                $tail
            } elsif (is_pair $v) {
                no warnings 'recursion';
                $tail = mixed_flatten(cdr($v), $tail, $maybe_delay);
                $v    = car $v;
                redo LP;
            } elsif (ref $v eq "ARRAY") {
                @_ = (
                    sub {
                        @_ == 2 or fp_croak_arity 2;
                        my ($v, $tail) = @_;
                        no warnings 'recursion';

                        # ^XX don't understand why it warns here
                        @_ = ($v, $tail, $maybe_delay);
                        goto \&mixed_flatten;
                    },
                    $tail,
                    $v
                );
                require FP::Stream;    # XX ugly? de-circularize?
                goto(
                    $maybe_delay
                    ? \&FP::Stream::stream__array_fold_right

                        #^ XX just expecting it to be loaded
                    : \&array_fold_right
                );
            } else {

                #warn "improper list: $v"; well that's part of the spec, man
                cons($v, $tail)
            }
        }
    }
}

*FP::List::List::mixed_flatten = \&mixed_flatten;

TEST { list_to_array mixed_flatten [1, 2, 3] }
[1, 2, 3];
TEST { list_to_array mixed_flatten [1, 2, [3, 4]] }
[1, 2, 3, 4];
TEST { list_to_array mixed_flatten [1, cons(2, [string_to_list "ab", 4])] }
[1, 2, 'a', 'b', 4];
TEST {
    list(1, cons(2, [string_to_list "ab", 4]))->mixed_flatten->array
}
[1, 2, 'a', 'b', 4];
TEST {
    list_to_string mixed_flatten [string_to_list "abc", string_to_list "def",
        "ghi"]
}
'abcdefghi';    # only works thanks to perl chars and strings being
                # the same datatype

TEST_STDOUT {
    write_sexpr(
        mixed_flatten lazyLight {
            cons(lazy { 1 + 1 }, null)
        },
        undef,
        \&lazyLight
    )
}
'("2")';
TEST_STDOUT {
    write_sexpr(
        mixed_flatten lazyLight {
            cons(
                lazy {
                    [1 + 1, lazy { 2 + 1 }]
                },
                null
            )
        },
        undef,
        \&lazyLight
    )
}
'("2" "3")';

TEST_STDOUT {

    sub countdown {
        my ($i) = @_;
        if ($i) {
            lazyLight { cons($i, countdown($i - 1)) }
        } else {
            null
        }
    }
    write_sexpr(
        mixed_flatten lazyLight {
            cons(lazy { [1 + 1, countdown 10] }, null)
        },
        undef,
        \&lazyLight
    )
}
'("2" "10" "9" "8" "7" "6" "5" "4" "3" "2" "1")';

TEST_STDOUT {
    write_sexpr(mixed_flatten [lazyLight { [3, [9, 10]] }], undef, \&lazyLight)
}
'("3" "9" "10")';
TEST_STDOUT {
    write_sexpr(mixed_flatten [1, 2, lazyLight { [3, 9] }], undef, \&lazyLight)
}
'("1" "2" "3" "9")';

sub list_insertion_variants {
    @_ == 2 or @_ == 3 or fp_croak_arity "2 or 3";
    my ($l, $v, $variants_tail) = @_;
    if (@_ == 2) {
        $variants_tail = null
    }
    if ($l->is_null) {
        cons(list($v), $variants_tail)
    } else {
        my ($a, $r) = $l->first_and_rest;
        $r->insertion_variants($v)->map_with_tail(
            sub {
                my ($r2) = @_;
                cons $a, $r2
            },
            $variants_tail
        )->cons(cons($v, $l))
    }
}

*FP::List::List::insertion_variants = \&list_insertion_variants;

TEST {
    list_insertion_variants list(qw(a b c)), 0
}
list(
    list(0,   'a', 'b', 'c'),
    list('a', 0,   'b', 'c'),
    list('a', 'b', 0,   'c'),
    list('a', 'b', 'c', 0)
);
TEST { list_insertion_variants list(qw(a)), 0, list "END" }
list(list(0, 'a'), list('a', 0), 'END');
TEST { list_insertion_variants list(), 0, list "END" } list(list(0), 'END');

sub list_merge {
    @_ == 3 or fp_croak_arity 3;
    my ($A, $B, $cmp) = @_;
    if (is_null $A) {
        $B
    } elsif (is_null $B) {
        $A
    } else {
        my ($a, $ar) = $A->first_and_rest;
        my ($b, $br) = $B->first_and_rest;
        my $dir = $cmp->($a, $b);
        if ($dir < 0) {
            cons($a, list_merge($ar, $B, $cmp))
        } elsif ($dir == 0) {
            cons($a, cons($b, list_merge($ar, $br, $cmp)))
        } else {
            cons($b, list_merge($A, $br, $cmp))
        }
    }
}
*FP::List::List::merge = \&list_merge;

TEST {
    require FP::Ops;
    list_merge list(-3, 1, 1, 3, 4), list(-6, -4, -3, 0, 1, 2, 5, 6, 7),
        \&FP::Ops::real_cmp
}
list(-6, -4, -3, -3, 0, 1, 1, 1, 2, 3, 4, 5, 6, 7);

# Adapted copy-paste from FP/Stream.pm

sub cartesian_product_2 {
    @_ == 2 or fp_croak_arity 2;
    my ($a, $orig_b) = @_;
    my $rec;
    $rec = sub {
        my ($a, $b) = @_;
        my $rec = $rec;
        {
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

*FP::List::List::cartesian_product_2 = \&cartesian_product_2;

TEST { cartesian_product_2 list("A", "B"), list(list(1), list(2)) }
list(list('A', 1), list('A', 2), list('B', 1), list('B', 2));

TEST {
    cartesian_product_2 list("E", "F"), cartesian_product_2 list("C", "D"),
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

sub cartesian_product {
    my @v = @_;
    if (!@v) {
        die "cartesian_product: need at least 1 argument"
    } elsif (@v == 1) {
        list_map \&list, $v[0]
    } else {
        my $first = shift @v;
        cartesian_product_2($first, cartesian_product(@v))
    }
}

*FP::List::List::cartesian_product = \&cartesian_product;

TEST { cartesian_product list("A", "B"), list(1, 2) }
list(list('A', 1), list('A', 2), list('B', 1), list('B', 2));

use FP::Char 'is_char';

sub is_charlist {
    @_ == 1 or fp_croak_arity 1;
    my ($l) = @_;
    list_every \&is_char, $l
}

*FP::List::List::is_charlist = \&is_charlist;

# XX update to use fp_croak ?
sub ldie {

    # perl string arguments are messages, char lists are turned to
    # perl-quoted strings, then everyting is appended
    my @strs = map {
        if (is_charlist $_) {
            list_to_perlstring $_
        } elsif (is_null $_) {
            "()"
        } else {

            # XX have a better write_sexpr that can fall back to something
            # better?, and anyway, need string
            $_
        }
    } @_;
    croak join("", @strs)
}

package FP::List::Null {
    FP::Interfaces::implemented qw(FP::Abstract::Pure
        FP::Abstract::Sequence
        FP::Abstract::Equal
        FP::Abstract::Show);
}

package FP::List::Pair {
    FP::Interfaces::implemented qw(FP::Abstract::Pure
        FP::Abstract::Sequence
        FP::Abstract::Equal
        FP::Abstract::Show);
}

1
