# Thu May 29 23:23:36 2003  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2003-2014 by Christian Jaeger
# Published under the same terms as perl itself.
#

=head1 NAME

Chj::IO::CommandCommon

=head1 SYNOPSIS

 - not to be used directly -

=head1 DESCRIPTION

Common superclass ('mixin'?) for Chj::IO::Command and Chj::IO::CommandBidirectional.

=cut

#'

package Chj::IO::CommandCommon;

use strict;

use Chj::xperlfunc;
use Chj::xpipe;
use Carp;
use NEXT;
use Chj::singlequote 'singlequote_sh';

my %metadata; # numified => pid

sub _launch {
    my ($subname,$otherendclose,$closeinchild)=@_;
    sub {# curry unnecessary, but whatever
	my $self=shift;
	my ($cmd)=@_;
	my $maybe_env;
	if (ref($$cmd[0]) eq "HASH") {
	    # env settings (since with "use threads" $ENV does not work!)
	    $maybe_env= shift @$cmd;
	}
	@$cmd or die "$subname: missing cmd arguments";
	my ($readerr,$writeerr)=xpipe;
	if (my $pid= xfork) {
	    $metadata{pack"I",$self}=$pid;
	    &$otherendclose;
	    $writeerr->xclose; #" here it's clear that it's needed."
	    # close all handles that have been given for redirections? 
	    # or leave that to the user? the latter.
	    my $err= $readerr->xcontent;
	    if ($err) {
		croak (__PACKAGE__."::$subname: could not execute "
		       .join(" ",map{singlequote_sh $_}@$cmd)
		       .": $err");
	    }
	    return $self
	} else {
	    &$closeinchild;
	    if (defined $maybe_env) {
		my @newcmd= ("/usr/bin/env");
		my $env= $maybe_env;
		for my $k (keys %$env) {
		    die "invalid env key starting with '-': '$k'"
		      if $k=~ /^-/;
		    push @newcmd, "$k=$$env{$k}";
		}
		push @newcmd, @$cmd;
		$cmd= \@newcmd;
	    }
	    if (ref($$cmd[0]) eq "CODE") {
		my $code= shift @$cmd;
		eval {
		    $code->(@$cmd);
		    die "coderf did return";
		};
		$writeerr->xprint($@);# [well serialize it?..tja..]
	    } else {
		no warnings;
		exec @$cmd;
		$writeerr->xprint($!);
	    }
	    exit;
	}
    }
}

sub xlaunch {
    my $self=shift;
    my ($otherend,$hdl,@cmd)=@_;
    _launch
      ("xlaunch",
       sub {
	   $otherend->xclose;
	   # ^important; seems like it's not cleaned up and destroyed
	   # otherwise upon return from new_* methods [soon enough],
	   # xcontent and the like would block outside.
       },
       sub {
	   $otherend->xdup2($hdl);
       })
	->($self,\@cmd);
}

sub xlaunch3 {
    my $self=shift;
    my ($in,$out,$err,@cmd)=@_;
    _launch
      ("xlaunch3",
       sub { },
       sub {
	   $in->xdup2(0) if $in;
	   $out->xdup2(1) if $out;
	   $err->xdup2(2) if $err;
       })
	->($self,\@cmd);
}


sub pid {
    my $self=shift;
    $metadata{pack"I",$self}
}

sub wait {
    my $s=shift;
    waitpid $metadata{pack"I",$s},0;
    $?
}

sub finish {
    my $s=shift;
    $s->close;
    my $rv= $s->wait;
    delete$metadata{pack"I",$s};
    $rv;
}

sub finish_nowait {
    my $s=shift;
    $s->close;
    delete$metadata{pack"I",$s};
}

sub xfinish { # Note: does not throw on error exit codes. Just throws
              # on errors closing.
    my $self=shift;
    $self->xclose;
    waitpid $metadata{pack"I",$self},0;
    delete$metadata{pack"I",$self};
    $?
}

sub xxfinish { # does also throw on error exit codes.
    my $self=shift;
    $self->xclose;
    waitpid $metadata{pack"I",$self},0;
    delete $metadata{pack"I",$self};
    $?==0 or do {
	if ($? & 127) {
	    croak ("xxfinish on ".$self->quotedname
		   .": subcommand has been killed with signal ".($? & 127));
	} else {
	    croak ("xxfinish on ".$self->quotedname
		   .": subcommand gave error ".($? >>8));
	}
    };
}

sub DESTROY { # no exceptions thrown from here
    my $self=shift;
    local ($@,$!,$?);
    if (defined $metadata{pack "I",$self}) {
	$self->finish;
    }
    $self->NEXT::DESTROY;
}

1
