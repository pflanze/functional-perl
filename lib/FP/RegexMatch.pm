#
# Copyright (c) 2021 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FP::RegexMatch

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut

package FP::RegexMatch;
use strict;
use warnings;
use warnings FATAL => 'uninitialized';
use experimental 'signatures';
use Exporter "import";

our @EXPORT    = qw();
our @EXPORT_OK = qw(
    all_matches
    all_matches1
    all_matches_whole
    all_continuous_matches1
    all_continuous_matches_whole
    fullmatching
);
our %EXPORT_TAGS = (all => [@EXPORT, @EXPORT_OK]);

use Chj::TEST;
use FP::Show;

# up to 9 captures in $re, bundled in arrays
sub all_matches ($str, $re) {
    my @res;
    while ($str =~ m{$re}gc) {
        my @c;
        push @c, $1 if defined $1;
        push @c, $2 if defined $2;
        push @c, $3 if defined $3;
        push @c, $4 if defined $4;
        push @c, $5 if defined $5;
        push @c, $6 if defined $6;
        push @c, $7 if defined $7;
        push @c, $8 if defined $8;
        push @c, $9 if defined $9;
        die "can't handle more than 9 captures" if defined $10;
        push @res, \@c;
    }
    \@res
}

# only 1 capture in $re
sub all_matches1 ($str, $re) {
    my @res;
    while ($str =~ m{$re}gc) {
        die "no capture" unless defined $1;
        push @res, $1;
        die "got more than 1 capture" if defined $2;
    }
    \@res
}

# captures the whole string of all matches of $re
sub all_matches_whole ($str, $re) {
    my @res;
    while ($str =~ m{($re)}gc) {
        push @res, $1;
    }
    \@res
}

# The list of (the single capture all matches of $re), requiring them
# to follow each other continuously from the current pos. Returns the
# pos of the remainder after.
sub all_continuous_matches1 ($str, $re) {
    my @res;
    my $pos = pos($str) // 0;    # is it correct that undef pos means 0 ?
    while ($str =~ m{\G$re}gc) {
        $pos = pos($str);
        die "no capture" unless defined $1;
        push @res, $1;
        die "got more than 1 capture" if defined $2;
    }
    wantarray ? (\@res, $pos) : \@res
}

# captures the whole string of all matches of $re, requiring them to
# follow each other continuously from the current pos. Returns the pos
# of the remainder after.
sub all_continuous_matches_whole ($str, $re) {
    my @res;
    my $pos = pos($str) // 0;    # is it correct that undef pos means 0 ?
    while ($str =~ m{\G($re)}gc) {
        $pos = pos($str);
        push @res, $1;
    }
    wantarray ? (\@res, $pos) : \@res
}

# ^ XX ach  pos 0  auto since  str is COPIED MAN  KRST

sub fullmatching ($fn) {
    sub ($str, $re) {
        my ($results, $restpos) = $fn->($str, $re);
        my $rem = substr($str, $restpos);
        $rem =~ /^\s*\z/ or die "non-matching remainder: " . show($rem);
        $results
    }
}

TEST { all_matches1 "foo barO",      qr/(o)/i } ['o', 'o', 'O'];
TEST { all_matches_whole "foo barO", qr/o/i } ['o', 'o', 'O'];
TEST { [all_continuous_matches_whole "oOo barO", qr/o/i] } [['o', 'O', 'o'], 3];
TEST { [all_continuous_matches_whole "BoOo barO", qr/o/i] } [[], 0];

1
