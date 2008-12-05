# Thu May 29 23:23:36 2003  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2003 by Christian Jaeger
# Published under the same terms as perl itself.
#
# $Id$

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

#use base "Chj::IO::Pipe"; nope, that has to be done using multiple inheritance from the subclass. This class must not have the same base as Chj::IO::Pipe's, for not confusing inheritance of quotedname().
use Chj::xperlfunc;
use Chj::xpipe;
use Carp;
use NEXT;

my %metadata; # numified => pid

sub _launch {
    my ($subname,$otherendclose,$closeinchild)=@_;
    sub {# curry unnötig, aber was sells (so gewachsen)
	my $self=shift;
	my ($cmd)=@_;
	@$cmd or die "$subname: missing cmd arguments";
	my ($readerr,$writeerr)=xpipe;
	if (my $pid= xfork) {
	    $metadata{pack"I",$self}=$pid;
	    &$otherendclose;
	    $writeerr->xclose; #" here it's clear that it's needed."
	    # close all handles that have been given for redirections? or leave that to the user? the latter.
	    my $err= $readerr->xcontent;
	    if ($err) {
		croak __PACKAGE__."::$subname: could not execute @$cmd: $err";
	    }
	    return $self
	} else {
	    &$closeinchild;
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
	   $otherend->xclose; # important; seems like it's not cleaned up and destroyed otherwise upon return from new_* methods [soon enough], xcontent and the like would block outside.
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

sub xfinish { # Note: does not throw on error exit codes. Just throws on errors closing.
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
    delete$metadata{pack"I",$self};# das macht doch destructor oder? ah nein das erwartet genau dass dies gelöscht wurde. Na, hat eh nur pid drin.
    $?==0 or do {
	if ($? & 127) {
	    croak "xxfinish on ".$self->quotedname.": subcommand has been killed with signal ".($? & 127);
	} else {
	    croak "xxfinish on ".$self->quotedname.": subcommand gave error ".($? >>8);
	}
    };
}

# sub stringify { # this class is not overloaded, but put it here so we can at least call it manually if needed.
#     my $s=shift;
#     #$s->pid  ;#HRMMM we do not have more data recorded.  noch schlimmer: ist undef nach beendigung. sigh
# }
# *name= \&stringify;#override name from super class. good?  todo

sub DESTROY { # no exceptions thrown from here
    my $self=shift;
    local ($@,$!,$?);
    if (defined $metadata{pack "I",$self}) {
	$self->finish;
    }
    $self->NEXT::DESTROY;
}

1;

#  old comments: (from before partitioning into CommandCommon and subclasses)
# todo: damit meldungen per quotedname nich bloss als 'pipe' bezeichnet auch hier cmd bez. speichern.
# und: betrifft wohl File.pm:  xclose mehrfach: gibt invalid file desc  ischaber gefährlihc? !
