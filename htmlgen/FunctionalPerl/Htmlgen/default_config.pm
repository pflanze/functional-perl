#
# Copyright (c) 2014-2015 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FunctionalPerl::Htmlgen::default_config

=head1 SYNOPSIS

=head1 DESCRIPTION


=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut

package FunctionalPerl::Htmlgen::default_config;
@ISA = "Exporter";
require Exporter;
@EXPORT      = qw($default_config);
@EXPORT_OK   = qw();
%EXPORT_TAGS = (all => [@EXPORT, @EXPORT_OK]);

use strict;
use warnings;
use warnings FATAL => 'uninitialized';
use Function::Parameters qw(:strict);

#use Sub::Call::Tail;

use Chj::xperlfunc qw(basename);

fun default__is_indexpath0($path0) {
    my $bn = lc basename($path0);
    $bn eq "index.md" or $bn eq "readme.md"
}

our $default_config = +{is_indexpath0 => \&default__is_indexpath0,};

