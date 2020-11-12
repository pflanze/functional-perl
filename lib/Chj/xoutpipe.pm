#
# Copyright (c) 2003-2014 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

Chj::xoutpipe

=head1 SYNOPSIS

    use Chj::xoutpipe;
    {
        my $p = xoutpipe "sendmail","-t";
        $p->xprint("From: $from\n");
        my $rv = $p->xfinish; # does close and waitpid, returns $?
        # see Chj::IO::Command for more methods.
    }

=head1 DESCRIPTION

Start external process with a writing pipe attached. Return the filehandle which
is a Chj::IO::Command (which is a Chj::IO::Pipe which is a Chj::IO::File) object.

=head1 SEE ALSO

L<Chj::IO::File>, L<Chj::xsysopen>, L<Chj::xopendir>

=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut

package Chj::xoutpipe;
@ISA = 'Exporter';
require Exporter;
@EXPORT = qw(xoutpipe);
use strict;
use warnings;
use warnings FATAL => 'uninitialized';
use Chj::IO::Command;

sub xoutpipe {
    Chj::IO::Command->new_receiver(@_);
}
*Chj::xoutpipe = \&xoutpipe;

1
