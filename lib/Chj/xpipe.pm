#
# Copyright (c) 2003-2014 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

Chj::xpipe

=head1 SYNOPSIS

    use Chj::xpipe;
    my ($read,$write) = xpipe; # or xpipe READ,WRITE ? hmmm. not yet.
    $read->xclose;
    $write->xprint("Hello");

=head1 DESCRIPTION

Returns two Chj::IO::Pipe filehandles/objects.

=head1 NOTE

You should trap SIGPIPE or the program will exit before an exception
is thrown.

=head1 SEE ALSO

L<Chj::IO::Pipe>, L<Chj::IO::File>

=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut

package Chj::xpipe;
@ISA = 'Exporter';
require Exporter;
@EXPORT = qw(xpipe);
use strict;
use warnings;
use warnings FATAL => 'uninitialized';

use Chj::IO::Pipe;
use Carp;

sub xpipe {
    if (@_) {
        confess "form with arguments not yet supported";
    }
    else {
        my $r = new Chj::IO::Pipe;
        my $w = new Chj::IO::Pipe;
        pipe $r, $w or croak "xpipe: $!";
        ($r, $w)
    }
}

1;
