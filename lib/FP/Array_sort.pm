#
# Copyright (c) 2013-2020 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FP::Array_sort - 'sensible' sorting setup

=head1 SYNOPSIS

    use FP::Array_sort; # for `array_sort` and `on`

    use FP::Ops 'real_cmp'; use FP::Array ':all'; use FP::Equal 'is_equal';
    is_equal array_sort([[10, 'a'], [15, 'b'], [-3, 'c']],
                        on *array_first, \&real_cmp),
             [[-3, 'c'], [10, 'a'], [15, 'b']];


=head1 DESCRIPTION

Perl's sort is rather verbose and uses repetition of the accessor
code:

=for test ignore

    sort { &$foo ($a) <=> &$foo ($b) } @$ary

Abstracting the repetition of the accessor as a function (`on`) and
wrapping sort as a higher-order function makes it more
straight-forward:

    array_sort $ary, on ($foo, \&real_cmp)

In method interfaces the need becomes more obvious: if $ary is one of
the FP sequences (FP::PureArray, FP::List, FP::StrictList, FP::Stream)
that supports `sort` (TODO) then:

    $s->sort (on $foo, \&real_cmp)

or if the comparison function already exists:

    $numbers->sort (\&real_cmp)

=head1 SEE ALSO

L<FP::Ops>, L<FP::Combinators>

=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut

# XX Should `on` be moved to `FP::Combinators`?

package FP::Array_sort;
use strict;
use warnings;
use warnings FATAL => 'uninitialized';
use Exporter "import";

our @EXPORT      = qw(array_sort array_sortCompare on on_maybe);
our @EXPORT_OK   = qw();
our %EXPORT_TAGS = (all => [@EXPORT, @EXPORT_OK]);

use FP::Carp;
use Chj::TEST;
use FP::Ops qw(real_cmp);    # for pod snippets, only, right?

sub array_sort {
    @_ == 1 or @_ == 2 or fp_croak_arity "1 or 2";
    my ($in, $maybe_cmp) = @_;
    if (defined $maybe_cmp) {
        [sort { &$maybe_cmp($a, $b) } @$in]
    } else {
        [

            # To use the FP::Abstract::Compare protocol, use
            # array_sortCompare instead--we need to be backwards compatible
            # here.
            sort @$in
        ]
    }
}

sub array_sortCompare {
    @_ == 1 or fp_croak_arity 1;
    my ($in) = @_;
    [sort { $a->FP_Compare_compare($b) } @$in]
}

sub on {
    @_ == 2 or fp_croak_arity 2;
    my ($select, $cmp) = @_;
    sub {
        @_ == 2 or fp_croak_arity 2;
        my ($a, $b) = @_;
        &$cmp(&$select($a), &$select($b))
    }
}

sub on_maybe {
    @_ == 2 or fp_croak_arity 2;
    my ($maybe_select, $cmp) = @_;
    defined $maybe_select ? on($maybe_select, $cmp) : $cmp
}

1
