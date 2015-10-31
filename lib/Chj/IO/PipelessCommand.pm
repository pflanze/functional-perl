#
# Copyright (c) 2015 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

Chj::IO::PipelessCommand

=head1 SYNOPSIS

 use Chj::IO::PipelessCommand;
 use Chj::xopen qw(xopen_read);
 use Chj::xtmpfile;

 my $in= xopen_read $inpath;
 my $out= xtmpfile $outpath;
 my $c= Chj::IO::PipelessCommand
            ->new_with_in_out ($in,$out, $path, @args);
 # $c can't be read from or written to.
 $c->xxfinish;

=head1 DESCRIPTION


=cut


package Chj::IO::PipelessCommand;

use strict; use warnings; use warnings FATAL => 'uninitialized';

use base qw(
	    Chj::IO::CommandCommon
	   );

sub new_with_in_out {
    my $class=shift;
    my $infh=shift;
    my $outfh=shift;
    my $self= bless {}, $class;
    $self->xlaunch3($infh,$outfh,undef,@_);
}

# override as NOOPs
sub close {}
sub xclose {}

1
