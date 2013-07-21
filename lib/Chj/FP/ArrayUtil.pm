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
@EXPORT_OK=qw(array_xone
	      array_hashing_uniq
	      array_fold
	      array_every
	      min
	      max);
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict;
use Carp;

sub array_xone ($) {
    my ($a)=@_;
    @$a==1 or croak "expecting 1 element, got ".@$a;
    $$a[0]
}

sub array_hashing_uniq ($;$ ) {
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

sub array_fold ($$$) {
    my ($fn,$start,$ary)=@_;
    for (@$ary) {
	$start= &$fn($_,$start);
    }
    $start
}

sub array_every ($$) {
    my ($fn,$ary)=@_;
    for (@$ary) {
	return 0 unless &$fn($_);
    }
    1
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

__END__
calc> :l array_every sub { ($_[0] % 2) == 0 }, [ 1, 2, 3 ]
0
calc> :l array_every sub { ($_[0] % 2) == 0 }, [ 2, 4, -6 ]
1
calc> :l array_every sub { ($_[0] % 2) == 0 }, [ ]
1
