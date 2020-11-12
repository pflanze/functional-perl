#
# Copyright (c) 2015-2019 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FP::PureArray::t -- tests for FP::PureArray

=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut

package FP::PureArray::t;

use strict;
use warnings;
use warnings FATAL => 'uninitialized';

use Chj::TEST;
use FP::Array ":all";
use FP::Div 'inc';
use FP::Predicates 'is_pure';
use FP::PureArray ":all";

sub clean {
    use FP::Ops qw(regex_substitute);
    regex_substitute sub {s/\s+at .*//s}, $_[0]
}

TEST {
    is_pure(purearray(4, 5))
}
1;

TEST {
    my $try = sub {    # already have TEST_EXCEPTION, but this allows it
                       # inline
        my ($th) = @_;
        my $res;
        eval { $res = $th->(); 1 } ? $res : clean $@
    };
    my $a  = purearray(1, 4, 5);
    my $a2 = $a->set(2, 7)->set(0, -1);
    my $a3 = $a2->update(2, *inc);
    my $a4 = $a3->push(9, 99)->unshift(77);
    my ($p, $a5) = $a4->pop;
    my ($s, undef) = $a4->shift;
    my $a6 = $a4->shift;
    [
        $a->ref(2), $a2->array, $a3->array, $a4->length, $p, $a5->[-1], $s,
        $a6->array, &$try(sub { $a5->ref(-1) })
    ]
}
[
    5,
    [-1, 4, 7],
    [-1, 4, 8],
    6, 99, 9, 77,
    [-1, 4, 8, 9, 99],
    'index out of bounds: -1'
];

TEST {
    my $a = purearray(1, 4, 5, 7);
    my @a = ($a->sub(0, 2), $a->sub(1, 3));
    push @a, $a->sub(2, 4);

    # throwing out of range errors
    push @a, (eval { $a->sub(3, 5) } || clean $@);

    # same for negative positions
    push @a, (eval { $a->sub(-1, 1) } || clean $@);

    # XX and about this case? Should this be an error, or revert the
    # range, or?
    push @a, (eval { $a->sub(3, 1) } || clean $@);

    array_map sub { ref $_[0] ? $_[0]->array : $_[0] }, \@a
}
[[1, 4], [4, 5], [5, 7], 'to out of range: 5', 'from out of range: -1', []];

TEST {
    purearray(1, 4, 5)->map (*inc)->sum
}
13;

TEST {
    purearray(3, 4, 5)->rest->map_with_index(sub { [@_] })
}
bless [[0, 4], [1, 5]], 'FP::_::PureArray';

TEST {
    array_clone_to_purearray([1, 2, 20])->map_with_islast(sub { $_[0] })->array
}
['', '', 1];

TEST {
    purearray(3, 4)->fold(sub { [@_] }, 's')
}
[4, [3, 's']];

TEST { (purearray 3, 4)->zip([qw(a b c)]) }
bless [[3, "a"], [4, "b"]], 'FP::_::PureArray';

TEST { (purearray 2, 3)->intersperse("a") }
bless [2, "a", 3], 'FP::_::PureArray';

TEST { purearray(1, 2, 3)->strings_join("-") }
"1-2-3";

TEST {
    (purearray 1, 2, 3)->every(sub { ($_[0] % 2) == 0 })
}
0;
TEST {
    (purearray 7)->any(sub { $_[0] % 2 })
}
1;

TEST {
    (purearray ["a", 1], ["b", 2], ["a", 4])->hash_group_by(*array_first)
}
{ 'a' => [['a', 1], ['a', 4]], 'b' => [['b', 2]] };

TEST { purearray(3)->xone } 3;
TEST_EXCEPTION { purearray(3, 4)->xone } 'expecting 1 element, got 2';

TEST { purearray(1, 3)->append(purearray(4, 5)->reverse)->array }
[1, 3, 5, 4];

TEST_STDOUT {
    require Chj::xperlfunc;
    purearray(1, 3)->for_each(\&Chj::xperlfunc::xprintln)
}
"1\n3\n";

TEST {
    require FP::Ops;
    purearray(5, 3, 8, 4)->sort (\&FP::Ops::number_cmp)->array
}
[3, 4, 5, 8];

# subclassing

{

    package FP::PureArray::_Test;
    our @ISA = 'FP::_::PureArray'
}

TEST {
    my $null = FP::PureArray::_Test->null;
    $null->set(1, 5)
}
bless [undef, 5], 'FP::PureArray::_Test';

TEST { purearray(1, 2, 3)->set(2, "a") } purearray(1, 2, 'a');
TEST {
    purearray(1, 2, 7, 3, 6)->filter(sub { $_[0] > 5 })
}
purearray(7, 6);

TEST { purearray(3, 4)->append(purearray(5, 6), purearray(7)) }
purearray 3, 4, 5, 6, 7;
TEST { purearray(3, 4)->append(FP::List::list(5, 6), purearray(7)) }
purearray 3, 4, 5, 6, 7;

1
