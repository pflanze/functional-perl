#
# Copyright (c) 2013-2015 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FP::Array - pure functions to work with native Perl arrays

=head1 SYNOPSIS

 use FP::Array;
 my $lengts= $list_of_arrays->map(\&array_length);

=head1 DESCRIPTION

To disambiguate from similarly named functions for `FP::List`, they
are prefixed with `array_`.

These are also used as methods for `FP::PureArray` objects.

=head1 SEE ALSO

L<FP::Array_sort>, L<FP::PureArray>

=cut


package FP::Array;
@ISA="Exporter"; require Exporter;
@EXPORT=qw();
@EXPORT_OK=qw(array
	      array_fst
	      array_snd
	      array_ref
	      array_xref
	      array_length
	      array_is_null
	      array_set
	      array_update
	      array_push
	      array_pop
	      array_shift
	      array_unshift
	      array_sub
	      array_append
              array_reverse
	      array_xone
	      array_hashing_uniq
	      array_zip2
	      array_for_each
	      array_map
	      array_map_with_i
	      array_map_with_islast
	      array_to_hash_map
	      array_filter
	      array_zip
	      array_fold
	      array_fold_right
	      array_join
	      array_strings_join
	      array_every
	      array_any
	      array_sum
	      array_first
	      array_second
	      array_rest
	      array_to_hash_group_by
	    );
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict; use warnings; use warnings FATAL => 'uninitialized';
use Carp;
use Chj::TEST;
use FP::Div qw(min);
use FP::Ops 'add';

sub array {
    [@_]
}

sub array_fst ($) {
    $_[0][0]
}

sub array_snd ($) {
    $_[0][1]
}

sub array_ref ($$) {
    my ($a,$i)=@_;
    $$a[$i]
}

sub array_xref ($$) {
    my ($a,$i)=@_;
    # XX also check that $i is integer?
    ($i >= 0 and $i < @$a)
      or die "index out of bounds";
    $$a[$i]
}

TEST_EXCEPTION { array_xref [], 0 } "index out of bounds";
TEST { array_xref [5], 0 } 5;
TEST_EXCEPTION { array_xref [5], 1 } "index out of bounds";
TEST_EXCEPTION { array_xref [5], -1 } "index out of bounds";

sub array_length ($) {
    scalar @{$_[0]}
}

sub array_is_null ($) {
    @{$_[0]}==0
}


# functional updates

sub array_set ($$$) {
    @_==3 or die "wrong number of arguments";
    my ($a,$i,$v)=@_;
    my $a2= [@$a];
    $$a2[$i]= $v;
    $a2
}

sub array_update ($$$) {
    @_==3 or die "wrong number of arguments";
    my ($a,$i,$fn)=@_;
    my $a2= [@$a];
    $$a2[$i]= &$fn ($$a2[$i]);
    $a2
}

sub array_push {
    my $a=shift;
    my $a2= [@$a];
    push @$a2, @_;
    $a2
}

sub array_pop ($) {
    my ($a)= @_;
    my $a2= [@$a];
    my $v= pop @$a2;
    ($v, $a2)
}

sub array_shift ($) {
    my ($a)= @_;
    my $a2= [@$a];
    my $v= shift @$a2;
    ($v, $a2)
}

sub array_unshift {
    my $a=shift;
    my $a2= [@$a];
    unshift @$a2, @_;
    $a2
}

sub array_sub {
    my ($a,$from,$to)=@_; # incl $from, excl $to
    bless [@$a[$from..$to-1]], ref $a
}


# various

sub array_append {
    [ map { @$_ } @_ ]
}

sub array_reverse ($) {
    my ($v)=@_;
    [ reverse @$v ]
}

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

sub array_for_each ($$) {
    my ($fn,$v)=@_;
    for my $a (@$v) { &$fn ($a) }
}

sub array_map {
    @_>1 or die "wrong number of arguments";
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

# (should one use multi-arg stream_map with stream_iota instead?..)
sub array_map_with_i {
    @_>1 or die "wrong number of arguments";
    my $fn=shift;
    my $len= min (map { scalar @$_ } @_);
    my @res;
    for (my $i=0; $i<$len; $i++) {
	$res[$i]= &$fn ($i, map { $$_[$i] } @_);
    }
    \@res
}

TEST{ array_map_with_i sub {[@_]}, [qw(a b)], [20..40] }
  [[0,"a",20], [1,"b",21]];

sub array_map_with_islast {
    @_>1 or die "wrong number of arguments";
    my $fn=shift;
    my $len= min (map { scalar @$_ } @_);
    my $last= $len - 1;
    my @res;
    for (my $i=0; $i<$len; $i++) {
	$res[$i]= &$fn ($i == $last, map { $$_[$i] } @_);
    }
    \@res
}

TEST{ array_map_with_islast sub { $_[0] }, [1,2,20] }
  [ '','',1 ];
TEST{ array_map_with_islast sub { [@_] }, [1,2,20], ["b","c"] }
  [ ['', 1, "b"], [1, 2, "c"] ];


sub array_to_hash_map {
    @_>1 or die "wrong number of arguments";
    my $fn=shift;
    my $len= min (map { scalar @$_ } @_);
    my %res;
    for (my $i=0; $i<$len; $i++) {
	my @v= &$fn (map { $$_[$i] } @_);
	@v==2 or die "wrong number of return values: ".show (\@v);
	$res{$v[0]}= $v[1];
    }
    \%res
}

TEST { array_to_hash_map(sub { my($x,$a)=@_; $a=> $x*$x },
			 [2,3,4,5],
			 ["a","b","c"]) }
  +{
    'a' => 4,
    'b' => 9,
    'c' => 16
   };


sub array_filter ($$) {
    @_==2 or die "wrong number of arguments";
    my ($fn,$v)=@_;
    [
     grep {
	 &$fn($_)
     } @$v
    ]
}

sub even {
    not ($_[0] % 2)
}

TEST { array_filter \&even, [qw(1 7 4 9 -5 0)] }
  [ 4, 0 ];


sub array_zip {
    array_map \&array, @_
}

TEST { array_zip [3,4], [qw(a b c)] }
  [[3,"a"], [4,"b"]];


# see discussion for `stream_fold` in `FP::Stream` for the reasoning
# behind the argument order of $fn
sub array_fold ($$$) {
    my ($fn,$start,$ary)=@_;
    for (@$ary) {
	$start= &$fn($_,$start);
    }
    $start
}

TEST{ array_fold sub{[@_]}, 's', [3,4] }
  [4, [3,'s']];

TEST{ require FP::List;
      array_fold (\&FP::List::cons, &FP::List::null, array (1,2))->array }
  [2,1];


sub array_fold_right ($$$) {
    @_==3 or die "wrong number of arguments";
    my ($fn,$tail,$a)=@_;
    my $i= @$a - 1;
    while ($i >= 0) {
	$tail= &$fn($$a[$i], $tail);
	$i--;
    }
    $tail
}

TEST{ require FP::List;
      FP::List::list_to_array (array_fold_right (\&FP::List::cons,
					      &FP::List::null,
					      [1,2,3])) }
  [1,2,3];


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

sub array_strings_join ($$) {
    @_==2 or die "wrong number of arguments";
    my ($ary,$val)=@_;
    join $val, @$ary
}

TEST{ array_strings_join [1,2,3], "-" }
  "1-2-3";


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

sub array_sum ($) {
    array_fold \&add, 0, $_[0]
}

*array_first= *array_fst;
*array_second= *array_snd;

sub array_rest ($) {
    my ($a)= @_;
    [ @$a[1..$#$a] ]
}

sub array_to_hash_group_by ($$) {
    my ($ary,$on)=@_;
    my %res;
    for (@$ary) {
	push @{$res{&$on ($_)}}, $_
    }
    \%res
}


1
