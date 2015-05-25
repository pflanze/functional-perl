#
# Copyright 2013 by Christian Jaeger, ch at christianjaeger ch
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
@EXPORT=qw(array_sort on complement);
@EXPORT_OK=qw();
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict; use warnings; use warnings FATAL => 'uninitialized';

use FP::Ops qw(string_cmp number_cmp);

sub array_sort ($ $) {
    my ($in,$cmp)=@_;
    [
     sort {
	 &$cmp($a,$b)
     } @$in
    ]
}

sub on ($ $) {
    my ($select, $cmp)=@_;
    sub {
	my ($a,$b)=@_;
	&$cmp(&$select($a), &$select($b))
    }
}

sub complement ($) {
    my ($cmp)=@_;
    sub {
	-&$cmp(@_)
    }
}

1
