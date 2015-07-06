#
# Copyright (c) 2015 Christian Jaeger, copying@christianjaeger.ch
# Published under the same terms as perl itself
#

=head1 NAME

FP - functional programming on Perl

=head1 SYNOPSIS

 use FP;
 $FP::VERSION # current version

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
