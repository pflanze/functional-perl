#
# Copyright (c) 2013-2015 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FP::Array_sort - 'sensible' sorting setup

=head1 SYNOPSIS

 use FP::Array_sort; # for `array_sort`, `on`, and `cmp_complement`
 # For this example:
 use FP::Ops 'number_cmp';
 use FP::List 'car';
 array_sort $ary, on \&car, \&number_cmp

=head1 DESCRIPTION

Perl's sort is rather verbose and uses repetition of the accessor
code:

    sort { &$foo ($a) <=> &$foo ($b) } @$ary

Abstracting the repetition of the accessor as a function (`on`) and
wrapping sort as a higher-order function makes it more
straight-forward:

    array_sort $ary, on ($foo, \&number_cmp)

In method interfaces the need becomes more obvious: if $ary is one of
the FP sequences (FP::PureArray, FP::List, FP::StrictList, FP::Stream)
that supports `sort` (TODO) then:

    $s->sort (on $foo, \&number_cmp)

or if the comparison function already exists:

    $numbers->sort (\&number_cmp)

=head1 SEE ALSO

L<FP::Ops>, L<FP::Combinators>

=cut


# XX Should `on` (and `cmp_complement`?) be moved to `FP::Combinators`?


package FP::Array_sort;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(array_sort on cmp_complement);
@EXPORT_OK=qw();
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict; use warnings; use warnings FATAL => 'uninitialized';

use FP::Ops qw(string_cmp number_cmp binary_operator);
use Chj::TEST;

sub array_sort ($;$) {
    @_==1 or @_==2 or die "wrong number of arguments";
    my ($in,$maybe_cmp)=@_;
    (defined $maybe_cmp ?
     [
      sort {
	  &$maybe_cmp($a,$b)
      } @$in
     ]
     :
     [
      sort @$in
     ])
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

TEST { my $f= cmp_complement binary_operator "cmp";
       [map { &$f(@$_) }
	([2,4], [4,2], [3,3], ["abc","bbc"], ["ab","ab"], ["bbc", "abc"])] }
  [1, -1, 0, 1, 0, -1];

1
