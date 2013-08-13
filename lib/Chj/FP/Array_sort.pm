#
# Copyright 2013 by Christian Jaeger, ch at christianjaeger ch
# This is free software, offered under the terms of the MIT License.
# See the file COPYING that came bundled with this file.
#

=head1 NAME

Chj::FP::Array_sort - 'sensible' sorting setup

=head1 SYNOPSIS

 use Chj::FP::Array_sort; # for Array_sort, On, String_cmp, Number_cmp
 use Chj::FP2::List;# for car in this example
 Array_sort $ary, On \&car, \&Number_cmp

=head1 DESCRIPTION


=cut


package Chj::FP::Array_sort;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(Array_sort On String_cmp Number_cmp Complement
	   the_method);
@EXPORT_OK=qw();
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict;

sub the_method ($) {
    my ($method)=@_;
    sub {
	my $self=shift;
	$self->$method(@_)
    }
}

sub Array_sort ($ $) {
    my ($in,$cmp)=@_;
    [
     sort {
	 &$cmp($a,$b)
     } @$in
    ]
}

sub On ($ $) {
    my ($select, $cmp)=@_;
    sub {
	my ($a,$b)=@_;
	&$cmp(&$select($a), &$select($b))
    }
}

sub String_cmp ($ $) {
    $_[0] cmp $_[1]
}

sub Number_cmp ($ $) {
    $_[0] <=> $_[1]
}

sub Complement ($) {
    my ($cmp)=@_;
    sub {
	-&$cmp(@_)
    }
}

1
