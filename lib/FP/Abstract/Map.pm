#
# Copyright (c) 2019 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FP::Abstract::Map - functional map protocol

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SEE ALSO

L<FP::PureHash>

=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut

package FP::Abstract::Map;

#@ISA = "Exporter"; require Exporter;
#@EXPORT = qw();
#@EXPORT_OK = qw();
#%EXPORT_TAGS = (all => [@EXPORT,@EXPORT_OK]);

use strict;
use warnings;
use warnings FATAL => 'uninitialized';

use Chj::NamespaceCleanAbove;

sub FP_Interface__method_names {
    qw(ref perhaps_ref set)
}

_END_
