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
  '""' => \&stringify,
  '0+' => \&numify,
  ;

our $MAXTRIES=10;
our $DEFAULT_AUTOCLEAN=1;
# 0=no, 1=yes and warn if not present in DESTROY, 2=yes but don't warn.
# XX or just boolean? 

my %meta;

sub numify {
    my $self=shift;
    my $class= ref $self;
    bless $self, "Chj::IO::Tempdir::FOOOOOOO"; # this is even how overload::StrVal works.
    my $num= $self+0;
    bless $self, $class;
    $num
}

sub stringify {
    my $self=shift;
    $self->path
}

sub _Addslash ($) {
    my ($str)=@_;
    $str=~ m|/$|s ? $str : $str."/"
}

sub xtmpdir {
    my $class=shift;
    @_<=2 or croak "xtmpdir expects 0 to 2 arguments";
    my ($opt_basepath,$opt_mask)=@_;
    my $basepath=
      (defined($opt_basepath) ?
       $opt_basepath
       : $ENV{CHJ_TEMPDIR_BASEPATH}
       || $ENV{CHJ_TEMPDIR} ?
       _Addslash($ENV{CHJ_TEMPDIR})
       : "/tmp/");
    my $mask= defined($opt_mask) ? $opt_mask : 0700; # 0777 would be the perl default
    my $item;
    my $n= $MAXTRIES;
    TRY: {
	$item= int(rand(999)*1000+rand(999));
	my $path= "$basepath$item";
	if (mkdir $path,$mask) {
	    my $self= $class->SUPER::new;
	    $self->set(path=>$path, autoclean=> $DEFAULT_AUTOCLEAN);
	    return $self;
	} elsif ($! == EEXIST  or $! == EINTR) {
	    if (--$n > 0) {
		redo TRY;
	    } else {
		croak "xtmpdir: too many attempts to create a ".
		  "tempfile starting with path '$basepath'";
	    }
	} else {
	    croak "xtmpdir: could not create dir '$path': $!";
	}
    }
}

sub set {
    my $self=shift;
    %{$meta{pack "I",$self}} = @_   # XX does this delete old keys?
}

sub path {
    my $self=shift;
    my $key= pack "I", $self;
    if (@_) {
	($meta{$key}{path})=@_
    } else {
	$meta{$key}{path};
    }
}

sub autoclean {
    my $self=shift;
    if (@_) {
	($meta{pack "I",$self}{autoclean})=@_;
    } else {
	$meta{pack "I",$self}{autoclean}
    }
}

sub xtmpfile {
    my $self=shift;
    my ($mode,$autoclean)=@_;
    defined (my $path= $self->path)
      or die "xtmpfile: can't create tmpfile inside undefined dir";
    require Chj::IO::Tempfile;
    my $ret= Chj::IO::Tempfile->xtmpfile($path."/",$mode,$autoclean);
    $ret->attribute("parent_dir_obj",$self);
    $ret
}

# useful for when other code creates files in it (not tmpfiles): "rm -rf"

sub rmrf {
    my $s=shift;
    require Chj::Shelllike::Rmrf;
    Chj::Shelllike::Rmrf::Rmrf ($s->path);
    # to avoid warning, and since recreation later on should be
    # understood as independent process anyway, ok?:
    $s->autoclean(0)
}

sub push_on_destruction {
    my $self=shift;
    @_==1 or die;
    my $key= pack "I", $self;
    my ($handler)=@_;
    push @{$meta{$key}{on_destruction}}, $handler
}

sub DESTROY {
    my $self=shift;
    #warn "DESTROY $self";
    local ($@,$!,$?);
    my $str= pack "I",$self;
    if (my $arr= $meta{$str}{on_destruction}) {
	&$_($self) for @$arr
    }
    if (my $autoclean=$meta{$str}{autoclean}) {
	rmdir $meta{$str}{path}
	  or do{
	      warn "autoclean: could not remove dir '$meta{$str}{path}': $!"
		unless $autoclean and $autoclean==2
		  # XX how to do right order with cleaning contained tmpfiles?
	    };
    }
    delete $meta{$str};
    #warn "/DESTROY $self";
}

1;
