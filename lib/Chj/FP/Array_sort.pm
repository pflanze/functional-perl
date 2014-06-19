#
# Copyright 2013 by Christian Jaeger, ch at christianjaeger ch
# This is free software, offered under the terms of the MIT License.
# See the file COPYING that came bundled with this file.
#

=head1 NAME

Chj::FP::Array_sort - 'sensible' sorting setup

=head1 SYNOPSIS

 use Chj::FP::Array_sort; # for array_sort, on, string_cmp, number_cmp, complement
 use Chj::FP2::List;# for car in this example
 array_sort $ary, on \&car, \&number_cmp

=head1 DESCRIPTION


=cut


package Chj::FP::Array_sort;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(array_sort on string_cmp number_cmp complement
	   the_method);
@EXPORT_OK=qw();
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict; use warnings FATAL => 'uninitialized';

sub the_method {
    my ($method,@args)=@_;
    sub {
	my $self=shift;
	$self->$method(@args,@_)
	  # any reason to put args before or after _ ? So far I only
	  # have args, no _.
    }
}

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

sub string_cmp ($ $) {
    $_[0] cmp $_[1]
}

sub number_cmp ($ $) {
    $_[0] <=> $_[1]
}

sub complement ($) {
    my ($cmp)=@_;
    sub {
	-&$cmp(@_)
    }
}

1
