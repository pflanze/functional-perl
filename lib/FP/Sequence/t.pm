#
# Copyright (c) 2015 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FP::Sequence::t -- tests for FP::Sequence

=head1 SYNOPSIS

 # is tested by `t/require_and_run_tests`

=head1 DESCRIPTION


=cut


package FP::Sequence::t;

use strict; use warnings; use warnings FATAL => 'uninitialized';

# from SYNOPSIS:

 use FP::Predicates "is_sequence"; # since we can't have it in
                                   # FP::Sequence
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
  [ 1,1,1,1,1,'','','' ];


# more tests:

use FP::List ":all";

TEST {
    list(list(3), list(4,5), list(6))->flatten
} list(3, 4, 5, 6);

TEST {
    list(list(6))->flatten(list 9)
} list(6, 9);

TEST {
    list(list(6))->flatten(undef)
} improper_list(6, undef); # OK?

1
