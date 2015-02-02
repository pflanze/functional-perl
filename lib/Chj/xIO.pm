#
# Copyright 2013-2015 by Christian Jaeger, ch at christianjaeger ch
# Published under the same terms as perl itself
#

=head1 NAME

Chj::xIO - exception-throwing I/O wrappers (and utilities)

=head1 SYNOPSIS

=head1 DESCRIPTION

Much simpler procedures than my extensive OO based Chj::IO::File and
Chj::xopen modules.

=cut


package Chj::xIO;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(xprint xprintln);
@EXPORT_OK=qw(capture_stdout capture_stdout_);
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict; use warnings FATAL => 'uninitialized';

sub xprint {
    my $fh= (ref($_[0]) eq "GLOB" or UNIVERSAL::isa($_[0],"IO")) ? shift : *STDOUT{IO};
    print $fh @_
      or die "printing to $fh: $!"
}

sub xprintln {
    my $fh= (ref($_[0]) eq "GLOB" or UNIVERSAL::isa($_[0],"IO")) ? shift : *STDOUT{IO};
    print $fh @_,"\n"
      or die "printing to $fh: $!"
}


sub capture_stdout_ {
    my ($thunk)=@_;
    my $buf="";
    open my $out, ">", \$buf
      or die $!;
    {
	# XX threadsafe or not?
	local *STDOUT= $out;
	&$thunk; # dropping results
    }
    close $out
      or die $!;
    $buf
}

sub capture_stdout (&) {
    capture_stdout_(@_)
}


1
