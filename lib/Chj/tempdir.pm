#
# Copyright 2013-2020 by Christian Jaeger, ch at christianjaeger ch
# This is free software, offered under the terms of the MIT License.
# See the file COPYING that came bundled with this file.
#

=head1 NAME

Chj::tempdir

=head1 SYNOPSIS

=head1 DESCRIPTION

A simple tempdir procedure, without auto cleanup.

=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut

package Chj::tempdir;
use strict;
use warnings FATAL => 'uninitialized';
use Exporter "import";

our @EXPORT      = qw(tempdir);
our @EXPORT_OK   = qw();
our %EXPORT_TAGS = (all => [@EXPORT, @EXPORT_OK]);

use FP::Carp;

sub tempdir {
    @_ == 1 or fp_croak_arity 1;
    my ($base)     = @_;
    my $tries      = 0;
    my $perhapsrnd = "";
TRY: {
        my $path = "$base-${$}${perhapsrnd}";
        if (mkdir $path, 0700) {
            return $path
        } else {
            $tries++;
            $perhapsrnd = "-" . substr(rand, 2, 7);
            redo TRY if ($tries < 10);
            die "can't mkdir '$path': $!";
        }
    }
}

1
