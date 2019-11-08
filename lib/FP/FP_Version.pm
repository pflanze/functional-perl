#
# Copyright (c) 2015-2019 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FP::* - functional programming on Perl

=head1 SYNOPSIS

 use FP::FP_Version;
 FP::FP_Version->VERSION # or $FP::FP_Version::VERSION

=head1 DESCRIPTION

Just embeds the version variable, and the abstract (NAME) for the
distribution.

=cut


package FP::FP_Version;
@ISA="Exporter"; require Exporter;
@EXPORT=qw();
@EXPORT_OK=qw();
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict; use warnings; use warnings FATAL => 'uninitialized';

our $VERSION= "0.71";

1
