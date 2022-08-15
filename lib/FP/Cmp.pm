#
# Copyright (c) 2013-2022 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#
#

=head1 NAME

FP::Cmp - 3-way comparison helpers

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SEE ALSO

=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut

package FP::Cmp;
use strict;
use utf8;
use warnings;
use warnings FATAL => 'uninitialized';

#use experimental 'signatures';
use Exporter "import";

our @EXPORT      = qw(cmp_complement cmp_then);
our @EXPORT_OK   = qw();
our %EXPORT_TAGS = (default => \@EXPORT, all => [@EXPORT, @EXPORT_OK]);

use FP::Carp;
use Chj::TEST;
use FP::Ops qw(binary_operator);

# see also `complement` from FP::Predicates
sub cmp_complement {
    @_ == 1 or fp_croak_arity 1;
    my ($cmp) = @_;
    sub {
        -&$cmp(@_)
    }
}

TEST {
    my $f = cmp_complement binary_operator "cmp";
    [
        map { &$f(@$_) } (
            [2,     4],
            [4,     2],
            [3,     3],
            ["abc", "bbc"],
            ["ab",  "ab"],
            ["bbc", "abc"]
        )
    ]
}
[1, -1, 0, 1, 0, -1];

sub cmp_then {

    # chain of cmp until one is non-0
    my @cmp = @_;
    sub {
        my ($a, $b) = @_;
        for my $cmp (@cmp) {
            if (my $res = $cmp->($a, $b)) {
                return $res
            }
        }
        0
    }
}

1
