#
# Copyright 2015 by Christian Jaeger, copying@christianjaeger.ch
# Published under the same terms as perl itself
#

=head1 NAME

FP::Sequence::t -- tests for FP::Sequence

=head1 SYNOPSIS

 # is tested by `t/require_and_run_tests`

=head1 DESCRIPTION


=cut


package FP::Sequence::t;

use strict; use warnings FATAL => 'uninitialized';

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


1
