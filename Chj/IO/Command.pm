# Thu May 29 23:23:36 2003  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2003 by Christian Jaeger
# Published under the same terms as perl itself.
#
# $Id$

=head1 NAME

Chj::IO::Command

=head1 SYNOPSIS

 use Chj::IO::Command;
 # my $mail= Chj::IO::Command->new_out("sendmail","-t");  or:
 # my $mail= Chj::IO::Command->new_writer("sendmail","-t"); or:
 my $mail= Chj::IO::Command->new_receiver("sendmail","-t");
 warn "sendmail has pid ".$mail->pid;
 $mail->xprint("From:..\nTo:..\n\n...");
 my $exitcode= $mail->xfinish;
 # my $date= Chj::IO::Command->new_in("date")->xcontent;
 # my $date= Chj::IO::Command->new_reader("date")->xcontent;
 my $date= Chj::IO::Command->new_sender("date")->xcontent;
 # there's also ->new_err, which allows to gather errors
 
 # or catch stdout and stderr both together: 
 my $str= Chj::IO::Command->new_combinedsender("foo","bar","baz")->xcontent; 

=head1 DESCRIPTION

Launches external commands with input or output pipes.
Inherits from Chj::IO::Pipe.

There is no support for multiple pipes to the same process.

=head1 NOTE

'new_in' does mean input from the view of the main process. May be a
bit confusing, since it's stdout of the subprocess. Same thing for
'new_out'.  Maybe the aliases 'new_reader' and 'new_writer' are a bit
less confusing (true?).

=head1 SEE ALSO

L<Chj::IO::Pipe>, L<Chj::IO::File>

=cut

#'

package Chj::IO::Command;

use strict;

use base "Chj::IO::Pipe";
use Chj::xperlfunc;
use Chj::xpipe;
use Carp;

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

sub new_out {
    my $class=shift;
    local $^F=0;
    my ($r,$self)=xpipe;
    bless $self,$class;
    $self->xlaunch($r,0,@_); ## und wie gebe ich den Namen an?
    # goto form: würd hier auch nix helfen da oben hard codiert. EBEN: ich brauch ein
    # croak das den Ort der Herkunft anzeigen kann. à la mein DEBUG().
}
*new_writer= *new_out;
*new_write= *new_out;
*new_receiver= *new_out;

sub new_in {
    my $class=shift;
    local $^F=0;
    my ($self,$w)=xpipe;
    bless $self,$class;
    $self->xlaunch($w,1,@_);
}
*new_reader= *new_in;
*new_read= *new_in;
*new_sender= *new_in;

sub new_combinedsender {
    my $class=shift;
    local $^F=0;
    my ($self,$w)=xpipe;
    bless $self,$class;
    $self->xlaunch3(undef,$w,$w,@_);
}

sub new_err {
    my $class=shift;
    local $^F=0;
    my ($self,$w)=xpipe;
    bless $self,$class;
    $self->xlaunch($w,2,@_);
}

sub new_receiver_with_stderr_to_fh {
    my $class=shift;
    my $errfh=shift;
    local $^F=0;
    my ($r,$self)=xpipe;
    bless $self,$class;
    $self->xlaunch3($r,undef,$errfh,@_); ## ... (vgl oben)
}

sub new_inout {
    my $class=shift;
    require Chj::xsocketpair;
    my ($self,$other)= Chj::xsocketpair();
    bless $self, $class; # NOTE: this is bad practice: it makes quotedname appear "pipe" when it is in fact "socketpair", should inherit still from Chj::IO::Socketpair class, and the other one from Chj::IO::Pipe. So, should create new class that inherits from them both. (addbless could also be used to the rescue). The problem of those are that they aren't subclassing friendly for Chj::IO::Command. So I'd have to put the new_inout into it's own class, and let the user instantiate from there. that would be clean. Well, proxying (delegation) would be ok, too, if a bit bloaty.
    $self->xlaunch3($other,$other,undef, @_)
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
    local ($@,$!);
    if (defined $metadata{pack "I",$self}) {
	$self->finish;
    }
    $self->SUPER::DESTROY;
}

1;

__END__

 todo: damit meldungen per quotedname nich bloss als 'pipe' bezeichnet auch hier cmd bez. speichern.
 und: betrifft wohl File.pm:  xclose mehrfach: gibt invalid file desc  ischaber gefährlihc? !


