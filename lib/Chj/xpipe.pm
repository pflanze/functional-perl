#
# Copyright (c) 2003-2014 Christian Jaeger, copying@christianjaeger.ch
# Published under the same terms as perl itself
#

=head1 NAME

Chj::xpipe

=head1 SYNOPSIS

 use Chj::xpipe;
 my ($read,$write)=xpipe; # or xpipe READ,WRITE ? hmmm. not yet.
 $read->xclose;
 $write->xprint("Hello");

=head1 DESCRIPTION

Returns two Chj::IO::Pipe filehandles/objects.

=head1 NOTE

You should trap SIGPIPE or the program will exit before an exception
is thrown.

=head1 SEE ALSO

L<Chj::IO::Pipe>, L<Chj::IO::File>

=cut


package Chj::xpipe;
@ISA='Exporter';
require Exporter;
@EXPORT= qw(xpipe);
use strict;

use Chj::IO::Pipe;
use Carp;

sub xpipe {
    if (@_) {
	confess "form with arguments not yet supported";
    } else {
	my $r=new Chj::IO::Pipe;
	my $w=new Chj::IO::Pipe;
	pipe $r,$w or croak "xpipe: $!";
	($r,$w)
    }
}

1;
