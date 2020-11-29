#
# Copyright (c) 2015-2020 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FP::StrictList - an FP::List that enforces list semantics

=head1 SYNOPSIS

    use FP::StrictList;
    use FP::Div 'inc'; use FP::List;

    my $l = strictlist (4,5)->map(*inc);
    ok is_strictlist $l; # O(1)

    use FP::Equal qw(equal is_equal); use FP::List 'null';
    is_equal strictnull->cons(1), cons (1, strictnull);
    ok not equal strictnull->cons(1), cons (1, null);
      # false: `cons` from `FP::List` and `FP::StrictList` are the same
      # function but it takes the type of their second argument into
      # consideration.


=head1 DESCRIPTION

FP::List does not enforce its pairs to only contain pairs or null in
their rest (cdr) position. Which means that they may end in something
else than a null (and operations encountering these will die with
"improper list"). FP::StrictList does, which means that
`is_strictlist` only needs to check the head pair to know whether it's
a proper list.

Also, FP::StrictList maintains the list length within each pair, thus
its `length` operation has O(1) complexity instead of O(n) like the
`length` from FP::List.

Both of these features dictate that a StrictList can't be lazy, since
(in a dynamically typed language) it's impossible to know the type
that a promise will give without evaluating it, or know the length of
the unevaluated tail.

Keep in mind that destruction of strict lists requires space on the C
stack proportional to their length. You will want to increase the C
stack size when handling big strict lists, lest your program will
segfault.

Currently FP::StrictList mostly only offers method based
functionality. It inherits all the methods from FP::List, but only
re-exports those basic functions that are basic and don't have "list_"
prefixes, and only on demand. The only special functions (and the only
ones exported by default) are `strictnull`, `is_strictlist` and
`strictlist`. Since StrictList enforcess list structure, methods are
guaranteed to always work on the rest field of a pair. Hence, the
suggestion is to simply use method calls and `the_method` from
`FP::Ops` to pass methods as first class functions.

=head1 SEE ALSO

Implements: L<FP::Abstract::Sequence>.

L<FP::List>, L<FP::Ops>, L<FP::Array>, L<FP::PureArray>

=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut

package FP::StrictList;
use strict;
use warnings;
use warnings FATAL => 'uninitialized';
use Exporter "import";

our @EXPORT    = qw(strictnull is_strictlist strictlist);
our @EXPORT_OK = qw(
    cons
    first second rest car cdr car_and_cdr first_and_rest
    strictlist_reverse__map_with_length_with_tail
    strictlist_reverse__map_with_length
    strictlist_array__reverse__map_with_length
    strictlist_array__map_with_length
);
our %EXPORT_TAGS = (all => [@EXPORT, @EXPORT_OK]);

use FP::List;
use Chj::TEST;
use FP::Combinators qw(flip2of3 flip);
use Scalar::Util qw(blessed);

package FP::StrictList::List {

    sub strictlist {
        @_ == 1 or die "wrong number of arguments";
        my $s = shift;
        $s
    }

    sub list {
        @_ == 1 or die "wrong number of arguments";
        my $s = shift;

        # Should it *really* convert to a non-strict list? This is
        # just a list with the added information that it's proper,
        # after all; equality should work just fine, in fact the
        # current FP_Equal_equal for FP::List is not sensitive on
        # subclasses (looks like has different issues though); *but*,
        # `equal` itself will short cut to an `undef` if the types are
        # not the same, so that won't work. XX should this change??
        FP::List::list($s->values)
    }

    sub stream {
        @_ == 1 or die "wrong number of arguments";
        my ($l) = @_;

        # XX isn't this stupid? Same as above. The current load test
        # in FP::Abstract::Sequence::t requires this behaviour.
        FP::Stream::stream($l->values)
    }
}

package FP::StrictList::Null {
    our @ISA = qw(FP::StrictList::List FP::List::Null);

    sub pair_namespace {"FP::StrictList::Pair"}
    *null = \&FP::StrictList::strictnull;

    sub cons {
        @_ == 2 or die "wrong number of arguments";
        my $s = shift;

        # different than FP::List::Null::cons in that it needs to set
        # the length field, too:
        bless [$_[0], $s, 1], $s->pair_namespace
    }

    # simply inherit FP_Equal_equal

    sub FP_Show_show {
        my ($s, $show) = @_;
        "strictnull"
    }

    use FP::Interfaces;
    FP::Interfaces::implemented qw(FP::Abstract::Equal);
}

package FP::StrictList::Pair {
    our @ISA = qw(FP::StrictList::List FP::List::Pair);

    *null = \&FP::StrictList::strictnull;

    # represented as blessed [ v, pair-or-null, length]

    sub cons {
        @_ == 2 or die "wrong number of arguments";
        my $s = shift;
        bless [$_[0], $s, $$s[2] + 1], ref $s
    }

    sub length {
        $_[0][2]
    }

    # simply inherit FP_Equal_equal

    sub FP_Show_show {
        my ($s, $show) = @_;
        ("strictlist(" . $s->map($show)->strings_join(", ") . ")")
    }

    use FP::Interfaces;
    FP::Interfaces::implemented qw(FP::Abstract::Equal);
}

# nil
my $null = bless [], "FP::StrictList::Null";

sub strictnull () {
    $null
}

TEST { strictnull->cons(1)->cons(2)->array }
[2, 1];

TEST { strictnull->length }
0;
TEST { strictnull->cons(8)->length }
1;
TEST { strictnull->cons(1)->cons(9)->length }
2;

TEST {
    require FP::Show;
    FP::Show::show(cons 1, cons 2, strictnull)
}
"strictlist(1, 2)";

sub strictlist {
    my $res = strictnull;
    for (my $i = $#_; $i >= 0; $i--) {
        $res = $res->cons($_[$i]);
    }
    $res
}

TEST {
    strictlist(4, 5)->map (sub { $_[0] + 1 })
}
cons(5, cons(6, strictnull));

sub is_strictlist {
    @_ == 1 or die "wrong number of arguments";
    my ($v) = @_;
    my $r = blessed($v) // return;
    (
               $r eq "FP::StrictList::List"
            or $v->isa("FP::StrictList::List")
            or $v->isa("FP::Lazy::Promise") && &is_strictlist(force $v)
    )
}

TEST {
    [
        map { is_strictlist $_ } null,
        strictnull,
        cons(1, null),
        cons(1, strictnull)
    ]
}
['', 1, '', 1];

TEST {
    is_strictlist(strictlist(4, 5)->map (sub { $_[0] + 1 }))
}
1;

TEST {
    is_strictlist(list(4, 5)->map (sub { $_[0] + 1 }))
}
'';

TEST {
    require FP::Lazy;
    is_strictlist(FP::Lazy::lazy { cons 1, strictnull })
}
1;

# heh, can cheat it this way:
TEST {
    is_strictlist(cons 0, FP::Lazy::lazy { cons 1, cons 2, strictnull })
}
'';

# interesting, +-luck:
TEST {
    require FP::List;
    FP::List::is_list(cons 0, FP::Lazy::lazy { cons 1, cons 2, strictnull })
}
1;

use FP::DumperEqual;

TEST {
    dumperequal strictnull->cons(1), cons(1, strictnull)
}
1;

TEST {
    dumperequal strictnull->cons(1), cons(1, null)
}
'';

TEST {
    my $l = strictlist(7, 8, 9)->reverse;
    [is_strictlist($l), $l->car, $l->length]
}
[1, 9, 3];

TEST {
    strictlist(7)->reverse_with_tail(8)
}

# falls back on the default list type since '8' is not a List (a
# strictlist would not accept such a value as the tail anyway; hm,
# hopefully nobody expects this operation to give an exception?)
bless([7, 8], 'FP::List::Pair');

sub make_reverse__map_with_length_with_tail {
    my ($cons) = @_;

    sub ($$$) {
        @_ == 3 or die "wrong number of arguments";
        my ($fn, $l, $tail) = @_;
        my $a;
        while (!$l->is_null) {
            my $i = $l->length;
            ($a, $l) = $l->first_and_rest;
            $tail = &$cons(&$fn($a, $i), $tail);
        }
        $tail
    }
}

sub strictlist_reverse__map_with_length_with_tail ($$$);
*strictlist_reverse__map_with_length_with_tail
    = make_reverse__map_with_length_with_tail(\&cons);

*FP::StrictList::List::reverse__map_with_length_with_tail
    = flip2of3 \&strictlist_reverse__map_with_length_with_tail;

TEST {
    my $l = strictlist(qw(a b c))
        ->reverse__map_with_length_with_tail(sub { [@_] }, null);
    [is_strictlist($l), $l->array]
}
['', [[c => 1], [b => 2], [a => 3]]];

sub strictlist_reverse__map_with_length ($$) {
    @_ == 2 or die "wrong number of arguments";
    my ($fn, $l) = @_;
    strictlist_reverse__map_with_length_with_tail($fn, $l, strictnull)
}

*FP::StrictList::List::reverse__map_with_length
    = flip \&strictlist_reverse__map_with_length;

TEST {
    my $l = strictlist(qw(a b c))->reverse__map_with_length(sub { [@_] });
    [is_strictlist($l), $l->array]
}
[1, [[c => 1], [b => 2], [a => 3]]];

sub strictlist_array__reverse__map_with_length ($$) {
    @_ == 2 or die "wrong number of arguments";
    my ($fn, $l) = @_;
    my $i = $l->length;
    make_reverse__map_with_length_with_tail(
        sub {
            my ($v, $ary) = @_;

            #unshift @$ary, $v; is this faster?:
            $$ary[--$i] = $v;
            $ary
        }
    )->($fn, $l, []);
}

*FP::StrictList::List::array__reverse__map_with_length
    = flip \&strictlist_array__reverse__map_with_length;

TEST {
    strictlist(qw(a b c))->array__reverse__map_with_length(sub { [@_] });
}
[[c => 1], [b => 2], [a => 3]];

sub strictlist_array__map_with_length ($$) {
    @_ == 2 or die "wrong number of arguments";
    my ($fn, $l) = @_;
    my $i   = 0;
    my $len = $l->length;
    my $ary = [];
    $$ary[$len - 1] = undef;    # preallocate array, faster?
    make_reverse__map_with_length_with_tail(
        sub {
            my ($v, $ary) = @_;

            #push @$ary, $v;
            $$ary[$i++] = $v;
            $ary
        }
    )->($fn, $l, $ary);
}

*FP::StrictList::List::array__map_with_length
    = flip \&strictlist_array__map_with_length;

TEST {
    strictlist(qw(a b c))->array__map_with_length(sub { [@_] });
}
[[a => 3], [b => 2], [c => 1]];

1
