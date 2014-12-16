# Thu May 29 20:27:41 2003  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2003 by Christian Jaeger
# Published under the same terms as perl itself.
#
# $Id$

=head1 NAME

Chj::xoutpipe

=head1 SYNOPSIS

 use Chj::xoutpipe;
 {
     my $p= xoutpipe "sendmail","-t";
     $p->xprint("From: $from\n");
     my $rv= $p->xfinish; # does close and waitpid, returns $?
     # see Chj::IO::Command for more methods.
 }

=head1 DESCRIPTION

Start external process with a writing pipe attached. Return the filehandle which
is a Chj::IO::Command (which is a Chj::IO::Pipe which is a Chj::IO::File) object.

=head1 SEE ALSO

L<Chj::IO::File>, L<Chj::xsysopen>, L<Chj::xopendir>

=cut

#     my $rv= $p->xfinish; # close and waitpid?  AH scheisse. Wo soll ich die pid hintun.

#use ...
#  die "UNFERTIG";

# cj Sat,  9 Oct 2004 01:27:42 +0200
# finishing it.

package Chj::xoutpipe;
@ISA='Exporter';
require Exporter;
@EXPORT= qw(xoutpipe);
use strict;
use Chj::IO::Command;

sub xoutpipe {
    Chj::IO::Command->new_receiver(@_);
}
*Chj::xoutpipe= \&xoutpipe;


1;
