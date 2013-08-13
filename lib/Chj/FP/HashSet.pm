#
# Copyright 2013 by Christian Jaeger, ch at christianjaeger ch
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::FP::HashSet - set operations for hash tables

=head1 SYNOPSIS

 use Chj::FP::ArrayUtil 'array2hashset';
 use Chj::FP::HashSet; # ":all";

 my $A= array2hashset ["a","b","c"];
 my $B= array2hashset ["a","c","d"];
 hashset2array hashset_union($A,$B) # -> ["a","b","c","d"]
 hashset2array hashset_intersection($A,$B) # -> ["a","c"]
 hashset2array hashset_difference($A,$B) # -> ["b"]
 hashset_subset($B,$A) # -> false
 hashset_subset(+{b=>1},$A) # -> true
 hashset_size($A) # -> 3
 hashset_empty($A) # -> false
 hashset_empty(+{}) # -> true

 # a la diff tool:
 hashset_diff($A,$B) # -> {b=>"-",d=>"+"}

=head1 DESCRIPTION

Hashsets are hash tables that are expected to have keys representing
the values unambiguously (Chj::FP::ArrayUtil::array2hashset will just
use the stringification).

Note that hashset2array will use the *values* of the hashes, not the
keys.

=cut


package Chj::FP::HashSet;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(array2hashset
	   hashset2array
	   hashset_union
	   hashset_intersection
	   hashset_difference
	   hashset_subset
	   hashset_size
	   hashset_empty
	   hashset_diff
	 );
@EXPORT_OK=qw(hashset_add_hashset_d);
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict;
use Chj::TEST;

sub array2hashset ($) {
    +{
      map {
	  $_=> $_
      } @{$_[0]}
     }
}


sub hashset2array ($) {
    [
     sort values %{$_[0]}
    ]
}

sub hashset_add_hashset_d ($ $) {
    my ($r,$s)=@_;
    for (keys %$s) {
	$$r{$_} = $$s{$_}
	  unless exists $$r{$_};
    }
}

sub hashset_union {
    my %r;
    hashset_add_hashset_d(\%r,$_)
      for @_;
    \%r
}

sub hashset_intersection ($ $) {
    my ($a,$b)=@_;
    my %r;
    for (keys %$a) {
	$r{$_} = $$b{$_}
	  if exists $$b{$_};
    }
    \%r
}

sub hashset_difference ($ $) {
    my ($a,$b)=@_;
    my %r;
    for (keys %$a) {
	$r{$_} = $$a{$_}
	  unless exists $$b{$_};
    }
    \%r
}

sub hashset_subset ($ $) {
    my ($subset,$set)=@_;
    my %r;
    for (keys %$subset) {
	return 0
	  unless exists $$set{$_};
    }
    1
}

sub hashset_size ($) {
    scalar keys %{$_[0]}
}

sub hashset_empty ($) {
    not keys %{$_[0]}
}


sub hashset_diff ($ $) {
    my ($a,$b)=@_;
    my %r;
    for (keys %$a) {
	$r{$_} = "-"
	  unless exists $$b{$_};
    }
    for (keys %$b) {
	$r{$_} = "+"
	  unless exists $$a{$_};
    }
    \%r
}

{
    my $A= array2hashset ["a","b","c"];
    my $B= array2hashset ["a","c","d"];
    TEST{ hashset2array hashset_union($A,$B) }
      ["a","b","c","d"];
    TEST{ hashset2array hashset_intersection($A,$B)}
      ["a","c"];
    TEST{ hashset2array hashset_difference($A,$B)}
      ["b"];
    TEST{ hashset_subset($B,$A) }
      0;
    TEST{ hashset_subset(+{b=>1},$A) }
      1;
    TEST{ hashset_size($A)}
      3;
    TEST{ hashset_empty($A)}
      '';
    TEST{ hashset_empty(+{})}
      1;
    TEST{ hashset_diff($A,$B) }
      +{b=>"-",d=>"+"};
}

1
