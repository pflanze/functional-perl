#
# Copyright 2013 by Christian Jaeger, ch at christianjaeger ch
# This is free software, offered under the terms of the MIT License.
# See the file COPYING that came bundled with this file.
#

=head1 NAME

Chj::tempdir

=head1 SYNOPSIS

=head1 DESCRIPTION

A simple tempdir procedure, without auto cleanup.

=cut


package Chj::tempdir;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(tempdir);
@EXPORT_OK=qw();
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict;

sub tempdir ($) {
    my ($base)=@_;
    my $tries=0;
    my $perhapsrnd= "";
  TRY: {
	my $path= "$base-${$}${perhapsrnd}";
	if (mkdir $path, 0700) {
	    return $path
	} else {
	    $tries++;
	    $perhapsrnd= "-".substr(rand,2,7);
	    redo TRY if ($tries < 10);
	    die "can't mkdir '$path': $!";
	}
    }
}

1
