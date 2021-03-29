#
# Copyright (c) 2015-2021 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FP::Abstract::Sequence::t -- tests for FP::Abstract::Sequence

=head1 SYNOPSIS

    # is tested by `t/require_and_run_tests`

=head1 DESCRIPTION


=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut

package FP::Abstract::Sequence::t;

use strict;
use warnings;
use warnings FATAL => 'uninitialized';

use FP::Carp;

# from SYNOPSIS:

use FP::Predicates;    # qw(is_sequence is_seq);

# ^ since we can't have those in FP::Abstract::Sequence
use FP::PureArray;
use FP::StrictList;
use FP::List;
use FP::Stream;
use FP::Array 'array';
use FP::Ops qw(the_method);
use Chj::TEST;

my $t_vals = list(
    purearray(3, 4), strictlist(3, 4), list(3, 4), stream(3, 4),

    purearray(), strictlist(), list(), stream(),

    cons(3, 4),     # ok this can't really count as a sequence,
                    # what to do about it?
    array(3, 4),    # Could `autobox` change this?
    array(), 3, "character sequence", { 3 => 4 },
);

sub t_fn {
    my ($fn) = @_;
    $t_vals->map($fn)->array
}

TEST { t_fn \&is_sequence }
[1, 1, 1, 1, 1, 1, 1, 1, 1, undef, undef, undef, undef, undef];

TEST { t_fn \&is_proper_sequence }
[1, 1, 1, 1, 1, 1, 1, 1, 0, undef, undef, undef, undef, undef];

TEST { t_fn \&is_seq }
[1, 1, 1, 1, 0, 0, 0, 0, 1, undef, undef, undef, undef, undef];

my $t_seqs = $t_vals->filter(\&is_proper_sequence);
TEST { $t_seqs->map(the_method "stream")->map(the_method "list") }
GIVES {
    list(
        list(3, 4), list(3, 4), list(3, 4), list(3, 4),

        list(), list(), list(), list(),
    )
};

# more tests:

use FP::List ":all";
use FP::Ops qw(the_method number_eq);
use FP::Array_sort qw(on);    # XX should really be in another place.
use FP::Array qw(array_first array_second);
use FP::Stream qw(:all);

TEST {
    list(list(3), list(4, 5), list(6))->flatten
}
list(3, 4, 5, 6);

TEST {
    list(list(6))->flatten(list 9)
}
list(6, 9);

TEST {
    list(list(6))->flatten(undef)
}
improper_list(6, undef);    # OK?

TEST { list(3, 4, 5)->max } 5;
TEST { list(3, 4, 5, -1)->min } -1;
TEST { purearray(3, -2, 5)->min } -2;
TEST { [stream(3, 4, 5, -1)->minmax] } [-1, 5];

TEST { [list([3, "a"], [4, "b"], [5, "c"], [-1, "d"])->minmax(\&array_first)] }
[[-1, "d"], [5, "c"]];

TEST { F list(qw())->intersperse("-") }
null;
TEST { F list(qw(a))->intersperse("-") }
list('a');
TEST { F list(qw(a b))->intersperse("-") }
list('a', '-', 'b');
TEST { F list(qw(a b c))->intersperse("-") }
list('a', '-', 'b', '-', 'c');

TEST { stream(1, 44, 2)->join("-") }
'1-44-2';

sub is_pair_purearray {
    @_ == 1 or fp_croak_arity 1;
    my ($v) = @_;
    [is_pair($v), is_purearray($v)]
}

# consing onto a purearray just builds an improper list:
my $a;
TEST {
    $a = cons 0, purearray(1, 2, 3);
    is_pair_purearray($a)
}
[1, ''];
TEST { is_pair_purearray($a->rest) }
['', 1];

# but purearrays also have a cons method that does the same:
my $b;
TEST {
    $b = purearray(4, 5)->cons(3);
    is_pair_purearray($b)
}
[1, ''];
TEST { is_pair_purearray($b->rest) }
['', 1];

# improper-list-but-sequence ops:
TEST { $a->length }
4;
TEST { $b->ref(2) }
5;

# XX add more interesting tests
TEST {
    my $s = purearray(3, 4, 4, 5, 6, 8, 5, 5)->map_with_index(\&array)->stream;
    my $r = $s->group(on \&array_second, \&number_eq)->array;
    [$s, $r]
}
[
    undef,
    [
        list([0, 3]),
        list([2, 4], [1, 4]),
        list([3, 5]),
        list([4, 6]),
        list([5, 8]),
        list([7, 5], [6, 5])
    ]
];

TEST {
    [
        list(50, 40, -10)->sum,
        list(50, 40, -10)->product,
        stream(50, 40, -10)->product,
        stream(50, 40, -10)->sum
    ]
}
[80, -20000, -20000, 80];

TEST { [list(qw(a b c d e f g))->split_at(3)] }
[list('a', 'b', 'c'), list('d', 'e', 'f', 'g')];

TEST { purearray(qw(a b c d e f))->chunks_of(4)->array }
[purearray('a', 'b', 'c', 'd'), purearray('e', 'f')];

# XX chunks_of returns a stream in this case; fine? Make up some rules
# about this...

TEST_EXCEPTION { purearray(qw(a b c d e f))->strictly_chunks_of(4)->array }
'premature end of input';

# XX TODO change most of the tests in this file to test ~all sequences.
TEST { purearray(qw(a bc d e))->string } 'abcde';

# Test across all sequence types
our @sequencetypes = qw(
    purearray
    mutablearray
    list
    stream
    strictlist
);

use FP::Equal;
use FP::Show;

# use FP::List;
# use FP::Stream;
use FP::PureArray;
use FP::MutableArray;
use FP::StrictList;
use Chj::TEST;

TEST {
    for my $orig (@sequencetypes) {
        my $constructor = eval '\&' . $orig;
        die $@ if $@;
        for my $target (@sequencetypes) {
            next if $orig eq $target;    #XX TODO: make it always valid
            next if ($orig eq "mutablearray" and $target eq "purearray");   #XXX
            my $d1 = $constructor->(qw(a b c d e));
            my $d2 = Keep($d1)->$target;
            my $d3 = $d2->$orig;
            equal $d1, $d3

                # XX what is the recommended way to make/format
                # exceptions?
                or die("not equal (from $orig to $target and back): "
                    . show($d1) . " vs. "
                    . show($d3));
        }
    }
    1
}
1;

use FP::autobox;

TEST { []->group(\&number_eq) } purearray();
TEST { [1]->group(\&number_eq) } purearray(purearray(1));
TEST { [1, 3]->group(\&number_eq) } purearray(purearray(1), purearray(3));
TEST { [1, 1, 3]->group(\&number_eq) } purearray(purearray(1, 1), purearray(3));
TEST { [1, 1, 3, 3]->group(\&number_eq) }
purearray(purearray(1, 1), purearray(3, 3));
TEST { [1, 1, 3, 3, 4]->group(\&number_eq) }
purearray(purearray(1, 1), purearray(3, 3), purearray(4));
TEST { [[3, "a"], [3, "b"], [4, "c"]]->group(on(\&array_first, \&number_eq)) }
purearray(purearray([3, 'a'], [3, 'b']), purearray([4, 'c']));

1
