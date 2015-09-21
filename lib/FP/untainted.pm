#
# Copyright (c) 2015 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FP::untainted - functional untainting

=head1 SYNOPSIS

 use FP::untainted;
 exec untainted($ENV{CMD}); # doesn't change the taint flag on $ENV{CMD}

 use FP::untainted 'is_untainted';
 # complement of Scalar::Util's 'tainted'

=head1 DESCRIPTION

L<Taint::Util> offers `untaint`, but it changes its argument. This
module provides a pure function to do the same (it (currently) uses a
regex match instead of XS to do so, though.)

Should this module stay? Vote your opinion if you like.

=cut


package FP::untainted;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(untainted);
@EXPORT_OK=qw(is_untainted);
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict; use warnings FATAL => 'uninitialized';

sub untainted ($) {
    $_[0]=~ /(.*)/s or die "??";
    $1
}

use Scalar::Util 'tainted';

sub is_untainted ($) {
    not tainted $_[0]
}

1
