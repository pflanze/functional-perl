# Mon Jul 14 07:58:53 2003  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2003 by Christian Jaeger
# Published under the same terms as perl itself.
#
# $Id$

=head1 NAME

Chj::IO::Tempdir

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::IO::Tempdir;
@ISA="Chj::IO::Dir"; require Chj::IO::Dir;

use strict;
use Carp;
use Errno qw(EEXIST EINTR);
use overload
  #'""'=> "path",
  #fallback=> 1, arggkack
  '""' => \&stringify,
  '0+' => \&numify,
  ;

our $MAXTRIES=10;
our $DEFAULT_AUTOCLEAN=1; # 0=no, 1=yes and warn if not present in DESTROY, 2=yes but don't warn.

my %meta;

sub numify {
    my $self=shift;
    #warn "numify:";
    #GAGL
    my $class= ref $self;
    bless $self, "Chj::IO::Tempdir::FOOOOOOO"; # this is even how overload::StrVal works.
    my $num= $self+0;
    bless $self, $class;
    #warn "numify: '$num'\n";
    $num
}
sub stringify {
    my $self=shift;
    $self->path
}

sub xtmpdir {
    my $class=shift;
    @_<=2 or croak "xtmpdir expects 0 to 2 arguments";
    my ($opt_basepath,$opt_mask)=@_;
    my $basepath= defined($opt_basepath) ? $opt_basepath : "/tmp/";
    my $mask= defined($opt_mask) ? $opt_mask : 0700; # 0777 would be the perl default
    my $item;
    my $n= $MAXTRIES;
    TRY: {
	$item= int(rand(999)*1000+rand(999));
	my $path= "$basepath$item";
	if (mkdir $path,$mask) {
	    #my $self= [ $path ];
	    #return bless $self,$class;   ### tja, ist halt eben kein fh; aber es wäre auch doof extra ein opendir zu machen für nix. Aber ein symbol?  !!!!
	    my $self= $class->SUPER::new;
	    $self->set(path=>$path, autoclean=> $DEFAULT_AUTOCLEAN);
	    #use Data::Dumper;
	    #warn Dumper(\%meta);
	    return $self;
	} elsif ($! == EEXIST  or $! == EINTR) {
	    if (--$n > 0) {
		redo TRY;
	    } else {
		croak "xtmpdir: too many attempts to create a tempfile starting with path '$basepath'";
	    }
	} else {
	    croak "xtmpdir: could not create dir '$path': $!";
	}
    }
}

sub set {
    my $self=shift;
    %{$meta{pack "I",$self}} = @_   # löscht das bestehende alte keys? ###ç
}

sub path { ## hmmmmm, lvalue geht nur solange gut als ich wirklich nix damit hier anfangen muss, z.B. zuweisung an mehrere orte geht schon nicht mehr.;  hmm lvalue geht wegen bugs eh nicht.
    my $self=shift;
    #our %OVERLOAD;
    #local %OVERLOAD;
    #local *OVERLOAD;
    #no overload;
    # This sucks. Mon, 14 Jul 2003 23:00:14 +0200
#    my $class= ref $self;
#    bless $self, "Chj::IO::Tempdir::FOOOOOOO"; # this is even how overload::StrVal works.
    my $key= pack "I", $self;
#    warn "AH key '$key'";
#    bless $self, $class;
    # works but really sucks, since in super classes will be still wrong.
    if (@_) {
	#warn "WARRRRRUMMMMMM";
	($meta{$key}{path})=@_
    } else {
	#warn "WITH KEY '$key'..";
	#my $val=
	$meta{$key}{path};
	#warn "val: '$val'\n"; ##
	#$val
    }
}
sub autoclean { # NOTE: setting autoclean to 2 on already opened files will not be useful (no immediate deletion, no autodeletion, thus same effect as 0).
    my $self=shift;
    if (@_) {
	($meta{pack "I",$self}{autoclean})=@_;
    } else {
	$meta{pack "I",$self}{autoclean}
    }
}
# sub tmpfiles {
#     my $self=shift;
#     $meta{pack "I",$self}{tmpfiles}
# }
#no see below

sub xtmpfile {
    my $self=shift;
    my ($mode,$autoclean)=@_;
    defined (my $path= $self->path)
      or die "xtmpfile: can't create tmpfile inside undefined dir";
    require Chj::IO::Tempfile;
    my $ret= Chj::IO::Tempfile->xtmpfile($path."/",$mode,$autoclean);
    # $self->tmpfiles->{$ret->path}= $ret;  nein muss umgekehrt sein mann
    $ret->attribute("parent_dir_obj",$self);
    $ret
}

sub DESTROY {
    my $self=shift;
    #warn "DESTROY $self";
    local ($@,$!,$?);
    my $str= pack "I",$self;
    if (my $autoclean=$meta{$str}{autoclean}) {
	rmdir $meta{$str}{path}
	  or do{
	      warn "autoclean: could not remove dir '$meta{$str}{path}': $!" ###immer? und eben: reihenfolge mit den tmpfiles.  wie kann ich   cleanalltmpfiles machen?
		unless $autoclean and $autoclean==2
	    };
    }
    delete $meta{$str};
    #warn "/DESTROY $self";
}

1;
