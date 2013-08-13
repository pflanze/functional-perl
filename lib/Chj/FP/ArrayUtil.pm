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
	      array_zip2
	      array_map
	      array_fold
	      array_join
	      array_every
	      array_any
	      min
	      max);
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict;
use Carp;
use Chj::TEST;

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

sub array_zip2 ($$);
sub array_zip2 ($$) {
    my ($l,$m)=@_;
    my @res;
    my $len= min(scalar @$l, scalar @$m);
    for (my $i=0; $i<$len; $i++) {
	$res[$i]= [ $$l[$i], $$m[$i] ];
    }
    \@res
}

sub array_map {
    @_>1 or die;
    my $fn=shift;
    my $len= min (map { scalar @$_ } @_);
    my @res;
    for (my $i=0; $i<$len; $i++) {
	$res[$i]= &$fn (map { $$_[$i] } @_);
    }
    \@res
}

TEST{ array_map sub { $_[0]+1}, [1,2,20] } [ 2,3,21 ];
TEST{ array_map sub { $_[0]+$_[1]}, [1,2,20], [-1,4] } [ 0,6 ];


sub array_fold ($$$) {
    my ($fn,$start,$ary)=@_;
    for (@$ary) {
	$start= &$fn($_,$start);
    }
    $start
}

sub array_join ($$) {
    my ($ary,$val)=@_;
    my @res;
    for (@$ary) {
	push @res, $_, $val
    }
    pop @res;
    \@res
}

TEST{ array_join [1,2,3],"a" }
        [
          1,
          'a',
          2,
          'a',
          3
        ];
TEST{ array_join [],"a" } [];


sub array_every ($$) {
    my ($fn,$ary)=@_;
    for (@$ary) {
	return 0 unless &$fn($_);
    }
    1
}

TEST{ array_every sub { ($_[0] % 2) == 0 }, [ 1, 2, 3 ] } 0;
TEST{ array_every sub { ($_[0] % 2) == 0 }, [ 2, 4, -6 ] } 1;
TEST{ array_every sub { ($_[0] % 2) == 0 }, [ ] } 1;

sub array_any ($$) {
    my ($fn,$ary)=@_;
    for (@$ary) {
	return 1 if &$fn($_);
    }
    0
}

TEST{ array_any sub { $_[0] % 2 }, [2,4,8] }
  0;
TEST{ array_any sub { $_[0] % 2 }, [] }
  0;
TEST{ array_any sub { $_[0] % 2 }, [2,5,8]}
  1;
TEST{ array_any sub { $_[0] % 2 }, [7] }
  1;


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
