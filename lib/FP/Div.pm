#
# Copyright (c) 2014-2020 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FP::Div - various pure functions

=head1 SYNOPSIS

=head1 DESCRIPTION


=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut

package FP::Div;
use strict;
use warnings;
use warnings FATAL => 'uninitialized';
use Exporter "import";

our @EXPORT    = qw();
our @EXPORT_OK = qw(inc dec square average
    identity
    min max minmax
    Chomp
);
our %EXPORT_TAGS = (all => [@EXPORT, @EXPORT_OK]);

use Chj::TEST;

# XX should `indentity` pass multiple values, and this be called
# `identity_scalar`? :

sub identity ($) {
    @_ == 1 or die "wrong number of arguments";
    $_[0]
}

sub inc ($) {
    @_ == 1 or die "wrong number of arguments";
    $_[0] + 1
}

sub dec ($) {
    @_ == 1 or die "wrong number of arguments";
    $_[0] - 1
}

sub square ($) {
    @_ == 1 or die "wrong number of arguments";
    $_[0] * $_[0]
}

sub average($$) {
    @_ == 2 or die "wrong number of arguments";
    ($_[0] + $_[1]) / 2
}

sub min {
    my $x = shift;
    for (@_) {
        $x = $_ if $_ < $x
    }
    $x
}

sub max {
    my $x = shift;
    for (@_) {
        $x = $_ if $_ > $x
    }
    $x
}

sub minmax {
    my $min = shift;
    my $max = $min;
    for (@_) {
        $min = $_ if $_ < $min;
        $max = $_ if $_ > $max;
    }
    ($min, $max)
}

# is there any better idea than ucfirst to distinguish from the
# builtin? `fchomp` ?
sub Chomp ($) {
    @_ == 1 or die "wrong number of arguments";
    my ($str) = @_;
    chomp $str;
    $str
}

1
