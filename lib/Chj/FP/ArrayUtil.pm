#
# Copyright 2013 by Christian Jaeger, ch at christianjaeger ch
# This is free software, offered under the terms of the MIT License.
# See the file COPYING that came bundled with this file.
#

=head1 NAME

Chj::FP::ArrayUtil

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::FP::ArrayUtil;
@ISA="Exporter"; require Exporter;
@EXPORT=qw();
@EXPORT_OK=qw(Array_hashing_uniq
	      Array_fold
	      min
	      max);
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict;

sub Array_hashing_uniq ($;$ ) {
    my ($ary,$maybe_warn)=@_;
    my %seen;
    [
     grep {
	 my $s= $seen{$_};
	 if ($s and $maybe_warn) { &$maybe_warn($_) };
	 $seen{$_}=1;
	 not $s
     } @$ary
    ]
}

sub Array_fold ($$$) {
    my ($fn,$start,$ary)=@_;
    for (@$ary) {
	$start= &$fn($_,$start);
    }
    $start
}
		
sub min {
    my $x=shift;
    for (@_) {
	$x= $_ if $_ < $x
    }
    $x
}

sub max {
    my $x=shift;
    for (@_) {
	$x= $_ if $_ > $x
    }
    $x
}

1
