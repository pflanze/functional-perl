#
# Copyright 2013-2015 by Christian Jaeger, ch at christianjaeger ch
# This is free software, offered under the terms of the MIT License.
# See the file COPYING that came bundled with this file.
#

=head1 NAME

FP::Array_sort - 'sensible' sorting setup

=head1 SYNOPSIS

 use FP::Array_sort; # for array_sort, on, string_cmp, number_cmp, complement
 use FP::List;# for car in this example
 array_sort $ary, on \&car, \&number_cmp

=head1 DESCRIPTION


=cut


package FP::Array_sort;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(array_sort on cmp_complement);
@EXPORT_OK=qw();
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict; use warnings; use warnings FATAL => 'uninitialized';

use FP::Ops qw(string_cmp number_cmp operator_2);
use Chj::TEST;

sub array_sort ($ $) {
    @_==2 or die "expecting 2 arguments";
    my ($in,$cmp)=@_;
    [
     sort {
	 &$cmp($a,$b)
     } @$in
    ]
}

sub on ($ $) {
    @_==2 or die "expecting 2 arguments";
    my ($select, $cmp)=@_;
    sub {
	@_==2 or die "expecting 2 arguments";
	my ($a,$b)=@_;
	&$cmp(&$select($a), &$select($b))
    }
}

# see also `complement` from FP::Predicates
sub cmp_complement ($) {
    @_==1 or die "expecting 1 argument";
    my ($cmp)=@_;
    sub {
	-&$cmp(@_)
    }
}

TEST { my $f= cmp_complement operator_2 "cmp";
       [map { &$f(@$_) }
	([2,4], [4,2], [3,3], ["abc","bbc"], ["ab","ab"], ["bbc", "abc"])] }
  [1, -1, 0, 1, 0, -1];

1
