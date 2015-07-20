#
# Copyright (c) 2015 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FP - functional programming on Perl

=head1 SYNOPSIS

 use FP;
 FP->VERSION # or $FP::VERSION, current version

=head1 DESCRIPTION

Currently just embeds the version variable. Might become a bundle for
easy import of all the futures that are most useful in most functional
programs?

=cut


package FP;
@ISA="Exporter"; require Exporter;
@EXPORT=qw();
@EXPORT_OK=qw();
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict; use warnings FATAL => 'uninitialized';

our $VERSION= "0.6";

1
