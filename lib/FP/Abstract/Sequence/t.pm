#
# Copyright (c) 2015-2019 Christian Jaeger, copying@christianjaeger.ch
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

This is alpha software! Read the package README.

=cut


package FP::Abstract::Sequence::t;

use strict; use warnings; use warnings FATAL => 'uninitialized';

# from SYNOPSIS:

 use FP::Predicates "is_sequence"; # since we can't have it in
                                   # FP::Abstract::Sequence
 use FP::PureArray;
 use FP::StrictList;
 use FP::List;
 use FP::Stream;
 use FP::Array 'array';

 use Chj::TEST;

 TEST { list(purearray(3,4),
             strictlist(3,4),
             list(3,4),
             stream(3,4),
             cons(3,4), # ok this can't really count as a sequence,
                        # what to do about it?
             array(3,4), # Could `autobox` change this?
             3,
             {3=>4},
        )->map(*is_sequence)->array }
  [ 1,1,1,1,1,0,0,0 ];


# more tests:

use FP::List ":all";
use FP::Ops qw(the_method number_eq);
use FP::Array_sort qw(on); # XX should really be in another place.
use FP::Array qw(array_first array_second);
use FP::Stream qw(:all);

TEST {
    list(list(3), list(4,5), list(6))->flatten
} list(3, 4, 5, 6);

TEST {
    list(list(6))->flatten(list 9)
} list(6, 9);

TEST {
    list(list(6))->flatten(undef)
} improper_list(6, undef); # OK?

TEST { list(3,4,5)->max } 5;
TEST { list(3,4,5,-1)->min } -1;
TEST { purearray(3,-2,5)->min } -2;
TEST { [stream(3,4,5,-1)->minmax] } [-1,5];

TEST { [list([3, "a"],
             [4, "b"],
             [5, "c"],
             [-1, "d"])->minmax(*array_first)] }
  [[-1, "d"], [5, "c"]];


TEST { F list(qw())->join("-") }
  null;
TEST { F list(qw(a))->join("-") }
  list('a');
TEST { F list(qw(a b))->join("-") }
  list('a', '-', 'b');
TEST { F list(qw(a b c))->join("-") }
  list('a', '-', 'b', '-', 'c');


sub is_pair_purearray ($) {
    my ($v)=@_;
    [ is_pair $v, is_purearray $v ]
}

# consing onto a purearray just builds an improper list:
my $a;
TEST { $a= cons 0, purearray (1,2,3);
       is_pair_purearray($a) }
  [1, ''];
TEST { is_pair_purearray($a->rest) }
  ['', 1];

# but purearrays also have a cons method that does the same:
my $b;
TEST { $b= purearray (4,5)->cons(3);
       is_pair_purearray ($b) }
  [1, '' ];
TEST { is_pair_purearray($b->rest) }
  ['', 1 ];

# improper-list-but-sequence ops:
TEST { $a->length }
  4;
TEST { $b->ref(2) }
  5;


# XX add more interesting tests
TEST {
    my $s= purearray(3,4,4,5,6,8,5,5)->map_with_i(*array)->stream;
    my $r= $s->group(on *array_second, *number_eq)->array;
    [$s, $r]
} [undef,
   [list([0,3]),
    list([2,4],
         [1,4]),
    list([3,5]),
    list([4,6]),
    list([5,8]),
    list([7,5],
         [6,5])]];

TEST {
    [
     list(50,40,-10)->sum,
     list(50,40,-10)->product,
     stream(50,40,-10)->product,
     stream(50,40,-10)->sum
    ]
} [80, -20000, -20000, 80];


1
