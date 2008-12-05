# Wed Jun  4 02:43:07 2003  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2003 by Christian Jaeger
# Published under the same terms as perl itself.
#
# $Id$

=head1 NAME

Chj::IO::Tempfile

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 NOTES

If you kill the program i.e. using Ctl-C, it will not clean up
it's temp file.
(wen ich noch wüsst wo ich das mit signals oder whatever gelöst
hatte. gibts eine sauber lösg?)

=cut

#'

package Chj::IO::Tempfile;
use base "Chj::IO::File";
use strict;
use Fcntl;
use Carp;
use POSIX qw(EEXIST EINTR ENOENT);
#use Chj::xperlfunc; #hm, dependency? ja ist overkill, geht gut ohne.

our $MAXTRIES=10;
our $DEFAULT_AUTOCLEAN=1; # 0=never unlink automatically, 1= unlink on destruction, 2= unlink immediately.

my %metadata; # numified => [ (path-->not any more), autoclean [,{hashwithattributes}] ]
		# für die putback permanentize putreal restore stay makestayif irgend funktion.
		##  ehr, sisi, path again:  numified=> [ basepath, autoclean,...]
		##  ehr doch nicht, weil da hin der echte random path gespeichert wird ?
		##  ehr aber dasch ein anderes lexical metadata!
		# also, basepath. obwohl das etwas unsicher ist: user könnte auch einfach dir gegeben haben.
# numified => [ basepath,
#		autoclean,
#		[{hashwithattributes}],
#	      ]

sub xtmpfile {
    my $proto=shift;
    my ($basepath,$mode,$autoclean,$mkdircb)=@_;  # basepath: /dir/startofname  (or: /dir/   but not /dir )
    $basepath||=do{my $n=$0; $n=~tr/\//-/; "/tmp/$n"};
    defined $mode or $mode= 0600;
    defined $autoclean or $autoclean=$DEFAULT_AUTOCLEAN;
    my $self;
    my $tries=0;my $called_mkdircb;
  TRY: {
#    local $@; nein hier nicht. weil sonst geht das eigene die dann nicht...
	eval {
	    $!=0;
	    #better today:
	    $Chj::IO::ERRNO=0;
	    my $rand= int(rand(99999)*100000+rand(99999));# well, weder gut genug für gefahrfälle noch sinnvoll für nongefahrfall.
	    my $path= "$basepath$rand";
	    #$DB::single=1;
	    $self= $proto->xsysopen($path, O_EXCL|O_CREAT|O_RDWR,$mode); ## O_RDWR macht genug Sinn hoff ich.
	    if ($autoclean==2) {
		unlink $path
		    or croak "xtmpfile: could not unlink '$path' that we created moments ago ???: $!";
		undef $path;
	    }
	    $metadata{pack"I",$self}=[$basepath,$autoclean];
	    #$self->set_opened_path(1,$path); gar nicht nötig, da xsysopen das schon macht.
	};
	if ($@) {
	    #warn "SUCK, '$@', '$!', ".($!+0)." -- or $Chj::IO::ERRNO / $Chj::IO::ERRSTR";
	    #^- $! doesn't survive until here (at least not with perl v5.8.4).
	    if ($Chj::IO::ERRNO==EEXIST or $Chj::IO::ERRNO == EINTR) { # not sure whether the latter test is needed
		#warn "SICK";
		if (++$tries < $MAXTRIES) {
		    redo TRY;
		} else {
		    croak "xtmpfile: too many attempts to create a tempfile starting with path '$basepath'";
		}
	    } elsif ($Chj::IO::ERRNO== ENOENT and $mkdircb) {
		#warn "JEEEEE";
		#use Chj::repl;repl;
		if ($called_mkdircb) {
		    croak "xtmpfile: got ENOENT but mkdir-callback has already been called, for '$basepath'";
		} else {
		    #&$mkdircb;
		    $mkdircb->($basepath);
		    $called_mkdircb=1;
		    redo TRY;
		}
	    } else {
		### hehe: möchte auch dies machen können, messages neu wrappen. Quasi exception objekte um-ownern. !
		croak "xtmpfile: could not create tempfile starting with '$basepath': $@";
		### heh und tatsächlich ist es jetzt foobar   und $! kann ich hier (komischerweise?) auch ned mehr lesen.
	    }
	}
    }
    $self
}

sub autoclean {
    my $self=shift;
    if (@_) { # set
	my ($v)=@_;
	$metadata{pack"I",$self}[1]=$v;
	# should we return former setting? does that really make sense?
    }
    else {
	$metadata{pack"I",$self}[1]
    }
}

# # these override the ones in the File class only because of the {..}[1]=0 bit:
# sub xunlink {
#     my $self=shift;
#     my $path= $self->path;
#     unlink $path
#       or croak "xunlink '$path': $!";
#     $self->unset_path;
#     $metadata{pack"I",$self}[1]=0;
# }
# sub xrename {
#     my $self=shift;
#     my ($to)=@_;
#     rename $self->path,$to
#       or croak "xrename '".($self->path)."' to '$to': $!";
#     $self->set_path($to);
#     $metadata{pack"I",$self}[1]=0;
# }
## na, stattdessen pfad holen und wenn der undef ist ists auch erledigt?
# ah bei rename geht das nicht da ist er dann der neue.

sub xrename {
    my $self=shift;
    $self->SUPER::xrename(@_);
    $metadata{pack"I",$self}[1]=0;
}
sub xlinkunlink { #well ist ein bisschen sinnlos, xlink reicht ja wenn dann bei destroy eh geunlinkt wird.
    my $self=shift;
    $self->SUPER::xlinkunlink(@_);
    $metadata{pack"I",$self}[1]=0;
}
# sub DESTROY {
#     my $self=shift;
#     #warn "DESTROY $self";
#     #use Data::Dumper;
#     #warn "HHHHHHHHHHHHHHHHH: ",Dumper ($self),Dumper (\%metadata);
#     if ((my $metadata= $metadata{pack"I",$self})) {
# 	if ($metadata{pack"I",$self}[1] == 1) {
# 	    #local $@;
# 	    #eval {
# 	    #    $self->xunlink;
# 	    #};
# 	    #warn $@ if $@;
# 	    #$self->unlink or warn "DESTROY: unlink: $!";
# 	    #unlink($self->filename) or warn "DESTROY: unlink: $!";
# 	    unlink($metadata{pack"I",$self}[0]) or do{my $file= $metadata{pack"I",$self}[0]; warn "DESTROY: unlink '$file': $!"};
# 	}
# 	delete $metadata{pack"I",$self};
#     }
#     $self->SUPER::DESTROY;
#     #warn "/DESTROY $self";
# }
#hey we even had a bug above: it did't close. and a second bug: didn't remove File metadata. AH doch rief ja super auf.

sub DESTROY {
    my $self=shift;
    local ($@,$!,$?);
    #$self->SUPER::DESTROY; # does close if needed, and remove metadata from File class.
    if (defined(my $path= $self->path)) {
	if ($metadata{pack"I",$self}[1] == 1) {
	    unlink $path
	      or warn "DESTROY: unlink ".$self->quotedname.": $!";
	}
    }
    delete $metadata{pack"I",$self};
    $self->SUPER::DESTROY;
}
	

	
# sub autoclean_all { # called by Chj::IO::Tempdir::DESTROY; hum, that would only work ok for the sweeping algorithm of perl in cleanup phase, but we also have tempfiles going out of scope earlier! => we now require tempfiles inside tempdirs to be allocated through $tempdir->xtmpfile
#     #my $class=shift
#     for( values %metadata) {
# 	my ($path,$autoclean)=@$_;
# 	if ($autoclean) {
# 	    if (unlink $path) {
# 		warn "_autoclean_all: unlinked '$path'";
# 	    } else {
# 		warn __PACKAGE__."::_autoclean_all: could not unlink '$path': $!";
# 	    }
# 	}
#     }
# }

# v- ps wo benütze ich das überhaupt?? cj 21.10.04.
sub attribute { # :lvalue does not work because of perl bugs. :-(
    my $self=shift;
    my $key=shift;
    if (@_) {
	($metadata{pack "I",$self}[2]{$key})=@_
    } else {
	#defined $metadata{pack "I",$self}[2]{$key} or $metadata{pack "I",$self}[2]{$key}=undef;
	#return $metadata{pack "I",$self}[2]{$key}  ## return is essential or we get  Can't return a temporary from lvalue subroutine  under 5.6.1 and 5.8.0
	$metadata{pack "I",$self}[2]{$key}
    }
}

sub _xlinkrename {
    my ($from,$to)=@_;# to must be file path, not dir.
    my $tobase=$to; $tobase=~ s{/?([^/]+)\z}{} or croak "_xlinkrename: missing to parameter"; my $toname= $1; $tobase.="/" if length $tobase;
    for(1..4) {
	my $tmppath= "$tobase.$toname.".rand(10000);
	if (link $from,$tmppath) {
	    if (rename $tmppath,$to) {
		return;
	    } else {
		croak "_xlinkrename: rename $tmppath,$to: $!";
	    }
	} else {
	    if ($! == EEXIST) {
		next;
	    } else {
		croak "_xlinkrename: link $from,$tmppath: $!";
	    }
	}
    }
    croak "_xlinkrename: too many tries to make a link from '$from' to a random name around '$to': $!";
}

sub xreplace_or_withmode {
    my $self=shift;
    my ($targetpath,$orwithmode)=@_; # $orwithmode can be an integer, an octal string, or a stat object; in case of a stat object and if running as root, it also keeps uid/gid.
    my $path= $self->xpath;
    my ($uid,$gid,$mode);
    if (($uid,$gid,$mode)=(stat $targetpath)[4,5,2]) {
	my $euid= (stat $path)[4]; # better than $> because of peculiarities
	defined $euid or croak "xreplace_or_withmode: ?? can't stat own file '$path': $!";
	if ($euid == 0) {
	    chown $uid,$gid, $path
	      or croak "xreplace_or_withmode: chown '$path': $!";
	} else {
	    if ($uid != $euid) {
		carp "xreplace_or_withmode: warning: cannot set owner of '$path' to $uid since we are not root";# ein zentraler mechanismus um warnings einzuhängen analog zu exceptions wäre halt eben schon noch interessant.
		$mode &= 0777; # see below
	    }
	    chown $euid,$gid, $path
	      or do {
		  carp "xreplace_or_withmode: warning: could not set group of '$path' to $gid: $!";## only a warning, ok?
		  $mode &= 0777; # mask off setuid and such stuff. correct?
	      };
	}
	# keep backup:
	# we need it atomic, thus link. but a 'replacing link'.
	_xlinkrename $targetpath, "$targetpath~";#backup filename konfig machen?
    } else {
	if (defined $orwithmode) {
	    if (ref $orwithmode) {
		# assuming stat object
		$mode= $orwithmode->permissions;
		if ($> == 0) {
		    chown $orwithmode->uid, $orwithmode->gid, $path
		      or croak "xreplace_or_withmode: chown '$path': $!";
		}
	    } else {
		if ($orwithmode=~ /^0/) {
		    $orwithmode= oct $orwithmode;
		    defined($orwithmode) or croak "xreplace_or_withmode: illegal octal withmode value given";##ach das kommt gar nie vor, bloss zu perl compile time mit constants, nicht hiermit.
		}
		$mode= $orwithmode; # & 0777; # mask off dito, since we do not know which uid/gid the programmer meant. which is a bug in itself.   wellll , programmer should know what he's doing then, right?
	    }
	} else {
	    croak "xreplace_or_withmode: error getting target permissions and no default mode given, stat '$targetpath': $!";
	}
    }
    chmod $mode,$path
      or croak "xreplace_or_withmode: chmod '$path': $!";
    $self->xrename($targetpath);
}


sub xputback { # swapin?   put back heisst etwa 'nachstellen'?
    my $self=shift;
    my ($orwithmode)=@_;#optional
    croak "xputback: file ".$self->quotedname." is still open" if $self->opened;
    # first create backup file. hm  ah, _xlinkrename  ah, is in xreplace* anyway.
    my $basepath= $metadata{pack"I",$self}[0];
    $self->xreplace_or_withmode($basepath, $orwithmode);
}

sub basepath {
    my $self=shift;
    $metadata{pack"I",$self}[0]
}


1;
