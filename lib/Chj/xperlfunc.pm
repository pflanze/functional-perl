#
# Copyright (c) 2003-2015 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

Chj::xperlfunc

=head1 SYNOPSIS

 my $pid= xspawn @files;
 print "Did it!\n";
 wait;
 print "The process (was pid $pid) gave ".($?>>8)."\n";

=head1 DESCRIPTION

Wrappers around core functions that throw exceptions on errors. Plus
some simple utilities, exported optionally (explicitely or as part of
the ":all" tag.)

=head1 FUNCTIONS

=over 4

=item xsystem(..)

Croaks if the command could not be started (i.e. system gave -1).
Returns the exit code of the program (== $?);

=item xxsystem(..)

Same as xsystem but also croaks if $? != 0.

=item xsystem_safe(..)

=item xxsystem_safe(..)

Same as the *xsystem calls but never run a shell, even if only one
argument is given.

=back

=head1 ADDITIONAL FUNCTIONS

These are exported by default.

=over 4

=item xstat(path)

=item xlstat(path)

=item Xstat(path)

=item Xlstat(path)

These are wrappers around stat; the x* functions die, the X* ones
return undef on ENOENT errors (and still croak on other errors like
permission problems).  When successful, they return objects (based on
array with the stat return values) with accessor methods.

If $Chj::xperlfunc::time_hires is true, these will return floating
point number strings for time stamps.

=item xlocaltime() or xlocaltime(unixtime)

These are wrappers around localtime; it never dies, but returns
objects (based on an array with the localtime values) with accessor
methods (including chainable setters). Additionally to the normal
accessors, 'Year' and 'Mon' exist, which are in the "normal"
(19xx..203x, 1..31) ranges, and 'Wday' which is 1..7 starting on
Sunday and 'wDay' which is 0..6 starting on Monday. They also have a
unixtime function to convert back to unixtime--this requires
Time::Local to be loaded explicitely.

=back

=head1 SPECIAL FUNCTIONS

These may be imported explicitely on demand.

=over 4

=item xLmtimed($), XLmtimed($)

Those call lstat first, then if it's a symlink, also stat, then return
an object with an mtime method that returns the newer mtime of the
two. Other methods are is_link (about the original path) and is_dir
and is_file (about the target path).

NOTE: those only call lstat and stat once, they don't check whether
the target is reached through several intermediate links or whether
any directory in any of the paths has newer mtime. Thus the result
can't be relied on for security (well, couldn't anyway since mtime can
be set, of course).

=item xLmtime($), XLmtime($)

Same as xLmtimed, XLmtimed but return the mtime value (or undef)
instead of a wrapper object.

=item xspawn($;)

Like xsystem, but returns as soon as the command has been started successfully,
leaving it running in the background. You may and should wait() for it some
time, you may also get SIGCHLD.

=item xlaunch($;)

Launch a program fully in the background, in a separate session, and with
double fork so that we don't need to (and never may) wait for it ever.
Using a pipe, it can still find out if the launch was successful or not.

=item xmvmkdir(first,newplace [,strict])

Move directory 'first' to 'newplace', then create a new empty dir at
place 'first' with same permissions as 'newplace'. Only root can
recreate owners different than current user and groups that the user
is not part in, of course. If 'strict' is true, croaks if it can't
recreate all permission details.

=item pathref = xtmpdir_with_paragon(pathtoexistingdir [,strict])

Create new directory using pathtoexistingdir as paragon. The new directoy
is placed into the same parent dir, with a dot prepended and .tmp and
a random number appended. The permissions are recreated. A reference of t
he path to the new directory is returned. (Reason to use a reference:
it's a lightweight object; upon deleting the last reference, it will
try to remove the tmpdir if empty.)

=item xmkdir_with_paragon  UNTESTED

=item xlinkunlink $source,$target

Has the same effect as xrename $source,$target except that it
won't overwrite $target if it already exists. This is done by using
link and unlink instead of rename.

=item xxcarefulrename $source,$target

xlinkunlink doesn't work for directories, or not always under grsec.
xxcarefulrename does resort to rename if hardlinks don't work.
But note: this is only careful, not guaranteed to be safe.

=item xlinkreplace $source,$target

This makes a new hardlink from source to target, potentially replacing
a previous target. All the same it does the replace atomically.
(It works by creating a link to a temporary location then rename.)
(Hm, strange function name?)

=item xfileno $string_or_FH

Does work with both filehandles and integer strings. Croaks if it's
neither or there's an error.

=item basename $pathstring [,$suffix(es) [,$insensitive]]

Same as the shell util of the same name, except that it croaks in a
few cases (when an empty string is given, or when the given suffix
doesn't match).

=item dirname $pathstring

Same as the shell util (or about as my old FolderOfThisFile function),
except that it croaks if dirname of "/" or "." is requested.

=item xmkdir_p $pathstring

Works like unix's "mkdir -p": return false if the directory already
exists, true if it (and, if necessary, it's parent(s)) has(/have) been
created, croaks if some error happens on the way.

=item xlink_p $frompath, $topath

xlink's $frompath to $topath but 

=back

=cut

#'

package Chj::xperlfunc;
@ISA="Exporter";
require Exporter;
@EXPORT=qw(
	   xfork
	   xexec
	   xsystem
	   xxsystem
	   xsystem_safe
	   xxsystem_safe
	   xrename
	   xmkdir
	   xrmdir
	   xchmod
	   xchown
	   xchdir
	   xstat
	   xlstat
	   Xstat
	   Xlstat
	   xlocaltime
	   xreadlink
	   xunlink
	   xlink
	   xsymlink
	   xutime
	   xkill
	   xeval
	   xwaitpid
	   xxwaitpid
	   xwait
	   xxwait
	   xsysread
	   xchroot
	  );
@EXPORT_OK=qw(
	      xspawn
	      xlaunch
	      xmvmkdir
	      xmkdir_with_paragon
	      xtmpdir_with_paragon
              xlinkunlink
	      xlinkreplace
	      xxcarefulrename
	      xfileno
	      basename
	      dirname
	      xmkdir_p
	      xlink_p
	      xgetpwnam
	      xgetgrnam
	      caching_getpwnam
	      caching_getgrnam
	      xprint
	      xprintln
	      xLmtimed
	      XLmtimed
	      xLmtime
	      XLmtime
	      min max
	    );
              # would we really want to export these?:
	      #caching_getpwuid
	      #caching_getgrgid
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);
use strict; use warnings; use warnings FATAL => 'uninitialized';
use Carp;
use Chj::singlequote 'singlequote_many'; # the only dependency so far
use Chj::Unix::exitcode;

BEGIN {
    if ($^O eq 'linux') {
	eval 'sub EEXIST() {17} sub ENOENT() {2}'; die if $@;
    } else {
	eval 'use POSIX "EEXIST","ENOENT"'; die if $@;
    }
}

sub xfork() {
    my $pid=fork;
    defined $pid or croak "xfork: $!";
    $pid
}

sub xexec {
    #local $^W;
    no warnings;
    exec @_;
    croak "xexec ".singlequote_many(@_).": $!";
}

sub xspawn {
    croak "xspawn: too few arguments" unless @_;
    local $^F=0;
    pipe READ,WRITE or die "pipe: $!";
    if (my $pid= xfork) {
	close WRITE;
	local $_; #local $/; not really necessary
	while (<READ>){
	    close READ;
	    croak "xspawn: can't exec \"$_[0]\": $_";
	}
	close READ;
	return $pid;
    } else {
	no warnings;
	close READ;
	exec @_;
	select WRITE; $|=1;
	print $!;
	exit;
    }
}

sub xlaunch { ## NA: todo: noch nicht fertig, insbesondere geht kommunikation exec failure nich bis zum parent.
    my $pid= xfork;
    if ($pid) {
	waitpid $pid,0; # !
    } else {
	# evtl. set session zeugs.
	xspawn @_;
	exit; # !
    }
}

sub xsystem {
    @_>0 or croak "xsystem: missing arguments";
    no warnings;
    (system @_)>=0
      or croak "xsystem: could not start command '$_[0]': $!";
    $?
}

sub xxsystem {
    @_>0 or croak "xxsystem: missing arguments";
    no warnings;
    (system @_)>=0
      or croak "xxsystem: could not start command '$_[0]': $!";
    $?==0
      or croak "xxsystem: process '$_[0]' terminated with ".exitcode($?);
}

sub xsystem_safe {
    @_>0 or croak "xsystem_safe: missing arguments";
    no warnings;
    (system { $_[0] } @_)>=0
      or croak "xsystem_safe: could not start command '$_[0]': $!";
    $?
}

sub xxsystem_safe {
    @_>0 or croak "xxsystem_safe: missing arguments";
    no warnings;
    (system { $_[0] } @_)>=0
      or croak "xxsystem_safe: could not start command '$_[0]': $!";
    $?==0
      or croak "xxsystem_safe: process terminated with ".exitcode($?);
}

sub xwaitpid ( $ ; $ ) {
    my ($pid,$flags)=@_;
    defined $flags or $flags= 0;
    my $kid= waitpid $pid,$flags;
    die "xwaitpid ($pid,$flags): no child process" if $kid<0;
    # ^ "no such child" but pid -1 is okay right? so..
    #$? # hm drop $kid?  build tuple?   ?
    $kid
}

sub xxwaitpid ( $ ; $ ) {
    my ($pid,$flags)=@_;
    defined $flags or $flags= 0;
    my $kid= xwaitpid $pid,$flags;
    $? == 0
	or die "xxwaitpid ($pid,$flags): child process terminated with "
	.exitcode($?);
    $kid
}

sub xwait {
    @_==0 or croak "xwait: expecting 0 arguments";
    my $kid= wait;
    defined $kid or die "xwait: $!";# when can this happen? EINTR?
    wantarray ? ($kid, $?) : $kid
}

sub xxwait {
    @_==0 or croak "xxwait: expecting 0 arguments";
    my $kid= wait;
    defined $kid or die "xxwait: $!";# when can this happen? EINTR?
    my $status= $?;
    $status == 0
	or die "xxwait: child process $kid terminated with ".exitcode($?);
    $kid
}

sub xrename {
    @_==2 or croak "xrename: wrong number of arguments";
    rename $_[0],$_[1]
      or croak "xrename(".join(", ",@_)."): $!";
}

sub xlinkunlink {
    @_==2 or croak "xlinkunlink: wrong number of arguments";
    link $_[0],$_[1]
	or croak "xlinkunlink(".join(", ",@_)."): can't link to target: $!";
    unlink $_[0]
	or do {
	    my $err= "$!";
	    my $res= unlink $_[1];
	    # ^ could this ever be dangerous? answer is yes. does it bother me?
	    if ($res) {
		croak "xlinkunlink(".join(", ",@_)
		    ."): can't unlink source: $err, so removed target again";
	    } else {
		croak "xlinkunlink(".join(", ",@_)
		    ."): can't unlink source: $err, "
		    ."additionally an error occured while trying to unlink "
		    ."the target again: $!";
	    }
	};
}

# Since xlinkunlink doesn't work for directories, or not always under
# grsec: (But note: it's careful, not guaranteed to be safe.)
sub xxcarefulrename {
    @_==2 or croak "xxcarefulrename: wrong number of arguments";
    my ($source,$dest)=@_;
    if (link $source,$dest) {
	unlink $source
	or do {
	    my $err= "$!";
	    my $res= unlink $dest;
	    # ^ could this ever be dangerous? answer is yes. does it bother me?
	    if ($res) {
		croak "xxcarefulrename(".join(", ",@_)
		    ."): can't unlink source: $err, so removed target again";
		# note: no need to goto rename-branch, since the
		# difficult cases either won't come here (grsec
		# hardlink restriction) or won't be helped by rename
		# (non-owned source file in sticky source dir (we're
		# not even talking about the case where both source
		# and target are in sticky dirs..)).
	    } else {
		croak "xxcarefulrename(".join(", ",@_)
		    ."): can't unlink source: $err, additionally an error "
		    ."occured while trying to unlink the target again: $!";
	    }
	};
    } else {
	if (lstat $dest) {
	    # (yes, link too already fails if target exists as a
	    # dangling symlink)
	    croak "xxcarefulrename: target '$dest' already exists";
	}
	else {
	    rename $source,$dest
	      or croak "xxcarefulrename(".join(", ",@_)."): $!";
	}
    }
}


sub xlinkreplace {
    @_==2 or croak "xlinkreplace: wrong number of arguments";
    my ($source,$dest)=@_;
    ## schon wieder dieser temporary try mechanismus. sollte ich dringend eine generische func oder ein makro daf�r haben theoretisch
    # nun im gegensatz zu Tempfile.pm brauchen wir kein eval hier. Aber auch das waer ja per func/macro machbar
    my $path;
  TRY: {
	for (1..3) {
	    $!=0;
	    my $rand= int(rand(99999)*100000+rand(99999));
	    # well, not good enough for dangerous cases nor reasonable for
	    # non-dangerous cases?
	    $path= "$source.tmp$rand~";
	    last TRY if link $source,$path;
	}
	croak "xlinkreplace: failed 3 attempts to create hardlinks from "
	    ."'$source' to e.g. '$path': $!";
    }
    rename $path,$dest
      or croak "xlinkreplace: could not rename '$path' to '$dest': $!";
}


sub xmkdir {
    if (@_==1) {
	mkdir $_[0]
	  or croak "xmkdir($_[0]): $!";
    } elsif (@_==2) {
	mkdir $_[0],$_[1]
	  or croak "xmkdir(".join(", ",@_)."): $!";
    } else {
	croak "xmkdir: wrong number of arguments";
    }
}

sub xrmdir {
    if (@_==1) {
	rmdir $_[0]
	  or croak "xrmdir($_[0]): $!";
    } else {
	croak "xrmdir: wrong number of arguments";
    }
}

sub xchmod {
    @_>=1 or croak "xchmod: not enoug arguments"; # should it be >1?
    chmod shift,@_
      or croak "xchmod: $!";
}

sub xchown {
    @_>=2 or croak "xchown: not enoug arguments"; # should it be >2?
    chown shift,shift,@_
      or croak "xchown: $!";
}

sub xchdir {
    chdir $_[0] or croak "xchdir '$_[0]': $!";
}

our $time_hires=0;

sub stat_possiblyhires {
    if ($time_hires) {
	require Time::HiRes; # (that's not slow, right?)
	if (@_) {
	    @_==1 or die "wrong number of arguments";
	    Time::HiRes::stat($_[0])
	} else {
	    Time::HiRes::stat($_)
	}
    } else {
	if (@_) {
	    @_==1 or die "wrong number of arguments";
	    stat($_[0])
	} else {
	    stat($_)
	}
    }
}

sub lstat_possiblyhires {
    if ($time_hires) {
	require Chj::Linux::HiRes;
	if (@_) {
	    @_==1 or die "wrong number of arguments";
	    Chj::Linux::HiRes::lstat($_[0])
	} else {
	    Chj::Linux::HiRes::lstat($_)
	}
    } else {
	if (@_) {
	    @_==1 or die "wrong number of arguments";
	    lstat($_[0])
	} else {
	    lstat($_)
	}
    }
}

sub xstat {
    my @r;
    @_<=1 or croak "xstat: too many arguments";
    @r= stat_possiblyhires(@_ ? @_ : $_);
    @r or croak (@_ ? "xstat: '@_': $!" : "xstat: '$_': $!");
    if (wantarray) {
	@r
    } elsif (defined wantarray) {
	my $self=\@r;
	bless $self,'Chj::xperlfunc::xstat'
    }
}

sub xlstat {
    my @r;
    @_<=1 or croak "xlstat: too many arguments";
    @r= lstat_possiblyhires(@_ ? @_ : $_);
    @r or croak (@_ ? "xlstat: '@_': $!" : "xlstat: '$_': $!");
    if (wantarray) {
	@r
    } elsif (defined wantarray) {
	my $self=\@r;
	bless $self,'Chj::xperlfunc::xstat'
    }
}

use Carp 'cluck';
sub Xstat {
    my @r;
    @_<=1 or croak "Xstat: too many arguments";
    @r= stat_possiblyhires(@_ ? @_ : $_);
    @r or do {
	if ($!== ENOENT) {
	    return;
	} else {
	    croak (@_ ? "Xstat: '@_': $!" : "Xstat: '$_': $!");
	}
    };
    if (wantarray) {
	cluck "Xstat call in array context doesn't make sense";
	@r
    } elsif (defined wantarray) {
	bless \@r,'Chj::xperlfunc::xstat'
    } else {
	cluck "Xstat call in void context doesn't make sense";
    }
}
sub Xlstat {
    my @r;
    @_<=1 or croak "Xlstat: too many arguments";
    @r= lstat_possiblyhires(@_ ? @_ : $_);
    @r or do {
	if ($!== ENOENT) {
	    return;
	} else {
	    croak (@_ ? "Xlstat: '@_': $!" : "Xlstat: '$_': $!");
	}
    };
    if (wantarray) {
	cluck "Xlstat call in array context doesn't make sense";
	@r
    } elsif (defined wantarray) {
	bless \@r,'Chj::xperlfunc::xstat'
    } else {
	cluck "Xlstat call in void context doesn't make sense";
    }
}


# caching variants of perlfuncs:

sub mk_caching_getANYid {
    my ($function,$scalarindex)=@_;
    my %cache;
    sub {
	@_==1 or die "wrong number of arguments";
	my ($id)= @_;
	my $v;
	if (not defined ($v= $cache{$id})) {
	    $v= [
		 &$function ($id)
		];
	    $cache{$id}=$v;
	}
	wantarray ? @$v : $$v[$scalarindex]
    }
}
*caching_getpwuid= mk_caching_getANYid (sub{getpwuid $_[0]},0);
*caching_getgrgid= mk_caching_getANYid (sub{getgrgid $_[0]},0);

*caching_getpwnam= mk_caching_getANYid (sub{getpwnam $_[0]},2);
*caching_getgrnam= mk_caching_getANYid (sub{getgrnam $_[0]},2);

{
    package Chj::xperlfunc::xstat;
    # (Alternative to arrays: hashes, so that slices like
    # ->{"dev","ino"} could be done? But so what.)
    sub dev     { shift->[0] }
    sub ino     { shift->[1] }
    sub mode    { shift->[2] }
    sub nlink   { shift->[3] }
    sub uid     { shift->[4] }
    sub gid     { shift->[5] }
    sub rdev    { shift->[6] }
    sub size    { shift->[7] }
    sub atime   { shift->[8] }
    sub mtime   { shift->[9] }
    sub ctime   { shift->[10] }
    sub blksize { shift->[11] }
    sub blocks  { shift->[12] }

    sub set_dev     { my $s= shift; ($s->[0])=@_; }
    sub set_ino     { my $s= shift; ($s->[1])=@_; }
    sub set_mode    { my $s= shift; ($s->[2])=@_; }
    sub set_nlink   { my $s= shift; ($s->[3])=@_; }
    sub set_uid     { my $s= shift; ($s->[4])=@_; }
    sub set_gid     { my $s= shift; ($s->[5])=@_; }
    sub set_rdev    { my $s= shift; ($s->[6])=@_; }
    sub set_size    { my $s= shift; ($s->[7])=@_; }
    sub set_atime   { my $s= shift; ($s->[8])=@_; }
    sub set_mtime   { my $s= shift; ($s->[9])=@_; }
    sub set_ctime   { my $s= shift; ($s->[10])=@_; }
    sub set_blksize { my $s= shift; ($s->[11])=@_; }
    sub set_blocks  { my $s= shift; ($s->[12])=@_; }

    # test helpers:
    sub permissions { shift->[2] & 07777 }
    sub permissions_oct { sprintf('%o',shift->permissions) }
    sub permissions_u { (shift->[2] & 00700) >> 6 }
    sub permissions_g { (shift->[2] & 00070) >> 3 }
    sub permissions_o { shift->[2] & 00007 }
    sub permissions_s { (shift->[2] & 07000) >> 9 }
    sub setuid { !!(shift->[2] & 04000) }
    # ^ I have no desire to put is_ in front.
    sub setgid { !!(shift->[2] & 02000) }
    sub sticky { !!(shift->[2] & 01000) }
    sub filetype { (shift->[2] & 0170000) >> 12 } # 4*3bits

    sub has_no_subdirs { my $n= shift->nlink;
			 # XX look at device nodes and look up the filesystem type?
			 $n < 2 ? undef
			     : $n == 2 }
    
    # Guess access rights from permission bits
    # note that these might guess wrong (because of chattr stuff,
    # or things like grsecurity,lids,selinux..)!
    # Also NOTE: this does not check parent folders of this item!
    sub checkaccess_for_submask_by_uid_gids {
	my $s=shift;
	my ($mod,$uid,$gids)=@_; # the latter being an array ref!
	return 1 if $uid==0;
	if ($s->[4] == $uid) {
	    return !!($s->[2] & (00100 * $mod))
	} else {
	    if ($gids) {
		for my $gid (@$gids) {
		    length($gid)==length($gid+0)
			or Carp::croak "invalid gid argument '$gid' - maybe "
			." you forgot to split '\$)'?";
		    # XXX: what if one is member of group 0, is this special?
		    if ($s->[5] == $gid) {
			if ($s->[2] & (00010 * $mod)) {
			    return 1;
			} else {
			    # even if others are allowed, we are not
			    return 0;
			}
		    }
		}
		return !!($s->[2] & (00001 * $mod))
	    } else {
		Carp::croak "missing gids argument - might just be a ref to "
		    ."an empty array";
	    }
	}
    }
    sub readable_by_uid_gids {
	splice @_,1,0,4;
	goto &checkaccess_for_submask_by_uid_gids;
    }
    sub writeable_by_uid_gids {
	splice @_,1,0,2;
	goto &checkaccess_for_submask_by_uid_gids;
    }
    *writable_by_uid_gids= *writeable_by_uid_gids;
    sub executable_by_uid_gids {
	splice @_,1,0,1;
	goto &checkaccess_for_submask_by_uid_gids;
    }

    sub Filetype_is_file { shift == 8 }
    sub is_file { Filetype_is_file(shift->filetype) } # call it is_normalfile ?
    sub Filetype_is_dir { shift == 4 }
    sub is_dir { Filetype_is_dir(shift->filetype) }
    sub Filetype_is_link { shift == 10 }
    sub is_link { Filetype_is_link(shift->filetype) }
    *is_symlink= \&is_link;
    sub Filetype_is_socket { shift == 12 }
    sub is_socket { Filetype_is_socket(shift->filetype) }
    sub Filetype_is_chardevice { shift == 2 }
    sub is_chardevice { Filetype_is_chardevice(shift->filetype) }
    sub Filetype_is_blockdevice { shift == 6 }
    sub is_blockdevice { Filetype_is_blockdevice(shift->filetype) }
    sub Filetype_is_pipe { shift == 1 } # or call it is_fifo?
    sub is_pipe { Filetype_is_pipe(shift->filetype) }

    # (See NOTE on checkaccess_for_submask_by_uid_gids!)
    sub is_executable {
	my $s=shift;
	my ($maybe_allow_dirs, $maybe_uid, $maybe_gids)=@_;

	my $allow_dirs = $maybe_allow_dirs // 1;
	my $uid= $maybe_uid // $>;
	my $gids= $maybe_gids // [split / /, $) ];

	(($s->is_file or ($allow_dirs and $s->is_dir))
	 and
	 $s->executable_by_uid_gids($uid, $gids))
    }

    sub type {
	my $s=shift;
	if ($s->is_dir) { "dir" }
	elsif ($s->is_link) { "link" }
	elsif ($s->is_file) { "file" }
	elsif ($s->is_socket) { "socket" }
	elsif ($s->is_chardevice) { "chardevice" }
	elsif ($s->is_blockdevice) { "blockdevice" }
	elsif ($s->is_pipe) { "pipe" }
	else { die "unknown type of filetype: ".$s->filetype }
    }

    # check whether "a file has changed"
    sub equal_content {
	my $s=shift;
	my ($s2)=@_;
	($s->dev == $s2->dev
	 and $s->ino == $s2->ino
	 and $s->size == $s2->size
	 and $s->mtime == $s2->mtime)
    }
    sub equal {
	my $s=shift;
	my ($s2)=@_;
	# permissions:
	($s->equal_content($s2)
	 and $s->mode == $s2->mode
	 and $s->uid == $s2->uid
	 and $s->gid == $s2->gid
	)
    }
    sub same_node {
	my $s=shift;
	my ($s2)=@_;
	($s->ino == $s2->ino
	 and $s->dev == $s2->dev)
    }
    # for simplicity (and in cases where I copy values in 'rows' (lists of methods)):
    # ATTENTION: these are non-caching! see below.
    sub username {
	my $s=shift;
	scalar $s->getpw
    }
    sub groupname {
	my $s=shift;
	scalar $s->getgr
    }
    # note that those are sensitive to list context!:
    # (and yes those should 'probably' return such objects as these, too..)
    sub getpw {
	my $s=shift;
	getpwuid($s->uid)
    }
    sub getgr {
	my $s=shift;
	getgrgid($s->gid)
    }

    # for performance:
    sub caching_getpw {
	my $s=shift;
	Chj::xperlfunc::caching_getpwuid($s->uid);
    }
    sub caching_getgr {
	my $s=shift;
	Chj::xperlfunc::caching_getgrgid($s->gid);
    }
    sub caching_username {
	my $s=shift;
	scalar $s->caching_getpw
    }
    sub caching_groupname {
	my $s=shift;
	scalar $s->caching_getgr
    }
}

use FP::Div qw(min max); # min just for the backwards-compatible
                         # re-export

{
    package Chj::xperlfunc::mtimed;
    sub path     { shift->[0] }
    sub mtime     { shift->[1] }
    sub lstat     { shift->[2] }
    sub maybe_stat    { shift->[3] }
    # ---
    sub xstat {
	my $s=shift;
	$$s[3] || die "Xstat gave file not found for: '$$s[0]'";
    }
    sub is_link {
	shift->[2]->is_link
    }
    sub is_dir {
	my $s=shift;
	$s->is_link ? $s->xstat->is_dir : $s->lstat->is_dir
    }
    sub is_file {
	my $s=shift;
	$s->is_link ? $s->xstat->is_file : $s->lstat->is_file
    }
}

sub XLmtimed ($) {
    my ($path)=@_;
    if (my $ls= Xlstat $path) {
	bless do {
	    if ($ls->is_link) {
		if (my $s= Xstat $path) {
		    [$path,
		     max ($ls->mtime, $s->mtime),
		     $ls,
		     $s]
		} else {
		    [$path,
		     $ls->mtime,
		     $ls,
		     undef]
		}
	    } else {
		[$path,
		 $ls->mtime,
		 $ls,
		 undef]
	    }
	}, "Chj::xperlfunc::mtimed"
    } else {
	undef
    }
}

sub xLmtimed ($) {
    my ($path)=@_;
    my $t= XLmtimed $path;
    (defined $t) ? $t : die "xLmtimed: '$path': $!"
}

sub xLmtime ($) {
    my ($path)=@_;
    xLmtimed ($path)->mtime
}

sub XLmtime ($) {
    my ($path)=@_;
    if (defined (my $s= XLmtimed ($path))) {
	$s->mtime
    } else {
	undef
    }
}



{
    package Chj::xperlfunc::xlocaltime;
    sub sec      { shift->[0] }
    sub min      { shift->[1] }
    sub hour     { shift->[2] }
    sub mday     { shift->[3] }
    sub mon      { shift->[4] }  # 0..11
    sub year     { shift->[5] }  # -1900
    sub wday     { shift->[6] }  # 0=sunday
    sub yday     { shift->[7] }  # 0..36[45]
    sub isdst    { shift->[8] }
    sub Year     { shift->[5]+1900 }
    sub Mon      { shift->[4]+1 }
    sub Wday     { shift->[6]+1 }  # 1=sunday
    sub wDay     { my $d= shift->[6]; $d == 0 ? 6 : $d-1 }  # 0=monday

    sub set_sec      { my ($s,$v)=@_; $s->[0]=$v; $s }
    sub set_min      { my ($s,$v)=@_; $s->[1]=$v; $s }
    sub set_hour     { my ($s,$v)=@_; $s->[2]=$v; $s }
    sub set_mday     { my ($s,$v)=@_; $s->[3]=$v; $s }
    sub set_mon      { my ($s,$v)=@_; $s->[4]=$v; $s }  # 0..11
    sub set_year     { my ($s,$v)=@_; $s->[5]=$v; $s }  # -1900
    #sub set_wday     { my ($s,$v)=@_; $s->[6]=$v; $s }  # 0=sunday
    sub set_yday     { my ($s,$v)=@_; $s->[7]=$v; $s }  # 0..36[45]
    sub set_isdst    { my ($s,$v)=@_; $s->[8]=$v; $s }
    sub set_Year     { my ($s,$v)=@_; $s->[5]= $v - 1900; $s }
    sub set_Mon      { my ($s,$v)=@_; $s->[4]= $v - 1; $s }
    #sub set_Wday
    #sub set_wDay
    # but those don't have any effect on timelocal anyway.

    sub unixtime {
	my $s=shift;
	&Time::Local::timelocal(@$s)
    }
}

sub xlocaltime (;$ ) {
    bless [localtime(defined $_[0] ? $_[0] : time)],
      "Chj::xperlfunc::xlocaltime"
}


sub xreadlink {
    my $res= @_==0 ? readlink
	: @_==1 ? readlink $_[0]
	: croak "xreadlink: wrong number of arguments";
    defined $res or croak @_? "xreadlink @_: $!" : "xreadlink: $!";
    $res
}

sub xmkdir_with_paragon {
    @_==2 or @_==3 or croak "xmvmkdir: wrong number of arguments";
    warn "UNTESTED!";
    my ($owner,$group,$mode)= (xstat $_[1])[4,5,2];
    xmkdir $_[0],0;
    if (! chown $owner,$group,$_[0]){
	$_[2] and croak "xmvmkdir: could not recreate user or group: $!";
    }
    xchmod $mode,$_[0];
}

{
    package Chj::xperlfunc::tmpdir;
    sub DESTROY {
	my $self=shift;
	local ($@,$!);
	rmdir $$self ## hack
	  and warn "removed tmpdir '$$self'";## should it warn? prolly not.
    }
}

sub xtmpdir_with_paragon {
    @_==1 or @_==2 or croak "xtmpdir_with_paragon: wrong number of arguments";
    my ($paragon,$strict)=@_;
    my ($owner,$group,$mode)= (xstat $paragon)[4,5,2];
    my $newname;
  TRY: for (0..2) {
	$newname= $paragon;
	$newname=~ s{(^|/)([^/]+)\z}{"$1.$2.tmp".int(rand(100000))}se;
	last TRY if mkdir $newname,0;
	if ($! != EEXIST) {
	    croak "xtmpdir_with_paragon: mkdir: $!";
	}
    }
    if (! chown $owner,$group,$newname){
	if ($strict){
	    rmdir $newname;
	    croak "xtmpdir_with_paragon: could not recreate user or group: $!";
	}
    }
    if (! chmod $mode,$newname) {
	rmdir $newname;
	croak "xtmpdir_with_paragon: chmod: $!";
    }
    return bless \ $newname, 'Chj::xperlfunc::tmpdir';
    # ^ so that it will be removed upon error
}

sub xmvmkdir {
    @_==2 or @_==3 or croak "xmvmkdir: wrong number of arguments";
    xrename $_[0],$_[1];
    my ($owner,$group,$mode)= (xstat $_[1])[4,5,2];
    xmkdir $_[0],0;
    if (! chown $owner,$group,$_[0]){
	$_[2] and croak "xmvmkdir: could not recreate user or group: $!";
    }
    xchmod $mode,$_[0];
}

sub xunlink {
    for (@_) {
	unlink $_
	  or croak "xunlink '$_': $!";
    }
}
sub xlink {
    @_==2 or croak "xlink: wrong number of arguments";
    link $_[0],$_[1]
      or croak "xlink '$_[0]','$_[1]': $!";
}
sub xsymlink {
    @_==2 or croak "xsymlink: wrong number of arguments";
    symlink $_[0],$_[1]
      or croak "xsymlink to '$_[1]': $!";
}

sub xutime {
    @_>=2 or croak "xutime: wrong number of arguments";
    my ($atime,$mtime)=(shift,shift);
    utime $atime,$mtime,@_
      or croak "xutime @_: $!";
}

sub xkill{
    my $sig=shift;
    kill $sig,@_
      or croak "xkill $sig @_: $!";
}

sub xchroot ( $ ) {
    my ($rtd)=@_;
    chroot $rtd
      or die "could not chroot to '$rtd': $!";
}

sub xeval( $ ) { # meant for string eval only, of course.
    ## hm ps should one localize $@ here?
    if (defined wantarray) {
	if (wantarray) {
	    my @res=eval $_[0];
	    if (ref$@ or $@){
		die $@
	    } else {
		@res
	    }
	} else {
	    my $res= eval $_[0];
	    if (ref$@ or $@){
		die $@
	    } else {
		$res
	    }
	}
    } else {
	eval $_[0];
	if (ref$@ or $@){
	    die $@
	}
    }
}

sub xfileno {
    # takes fh or integer
    my ($arg)=@_;
    my $fd= fileno $arg;
    return $fd if defined $fd;
    return $arg+0 if $arg=~ /^\s*\d+\s*\z/;
    croak "xfileno: '$arg' is not a filehandle nor a file descriptor number";
}


sub xsysread ( $ $ $ ; $ ) {
    my $rv= do {
	if (@_ == 4) {
	    sysread $_[0], $_[1], $_[2], $_[3]
	} else {
	    sysread $_[0], $_[1], $_[2]
	}
    };
    defined $rv or die "xsysread(".singlequote_many(@_)."): $!";
    $rv
}
# ^- ok this is silly (is it?) since I've got Chj::IO::File. But that
# latter one is not yet complete, I'm debugging xreadline atm.

use FP::Show qw(show_many);

sub basename ($;$$) {
    my ($path, $maybe_suffixS, $insensitive)=@_;
    my $copy= $path;
    $copy=~ s|.*/||s;
    my $res= do {
    length($copy) ? $copy : do {
	# path ending in slash--or empty from the start.
	if ($path=~ s|/+\z||s) {
	    $path=~ s|.*/||s;
	    # ^ this is necessary since we did it on $copy only,
	    #   before!
	    if (length $path) {
		$path
	    } else {
		"/"  # or die? no.
	    }
	} else {
	    croak "basename(".show_many(@_)."): ".
	      "cannot get basename from empty string";
	}
    }};
    if (defined $maybe_suffixS) {
	if (ref($maybe_suffixS)) {
	  TRY: {
		for my $suffix (@$maybe_suffixS) {
		    ($insensitive ?
		     $res=~ s/\Q$suffix\E\z//i
		     : $res=~ s/\Q$suffix\E\z//)
		      and last TRY;
		}
		croak "basename(".show_many(@_)."): ".
		  "no suffix matches";
	    }
	} else {
	    ($insensitive ? $res=~ s/\Q$maybe_suffixS\E\z//i
	      : $res=~ s/\Q$maybe_suffixS\E\z//)
	      or croak "basename(".show_many(@_)."): ".
		"suffix does not match";
	}
    }
    $res
}

# main> :d basename  "/fun/."
#  $VAR1 = '.';
# but the shell util acts the same way.

#chris@novo:~$ basename foo/bar/cj.git/blabla  .git/blabla
#blabla
# so no, do not strip before basenaming, really do it afterwards as I do


sub dirname ($ ) {
    my ($path)=@_;
    if ($path=~ s|/+[^/]+/*\z||) {
	if (length $path) {
	    $path
	} else {
	    "/"
	}
    } else {
	# deviates from the shell in that dirname of . and / are errors. good?
	if ($path=~ m|^/+\z|) {
	    die "can't go out of file system"
	} elsif ($path eq ".") {
	    die "can't go above cur dir in a relative path";
	} elsif ($path eq "") {
	    die "can't take dirname of empty string";
	} else {
	    "."
	}
    }
}

sub xmkdir_p ($ );
sub xmkdir_p ($ ) {
    my ($path)=@_;
    # (XX: see commit d1abd3c2 in megacopy for possible improvement)
    if (-d $path) {
	#done
	()
    } else {
	if (mkdir $path) {
	    #done
	    ()
	} else {
	    if ($!==ENOENT) {
		xmkdir_p(dirname $path);
		mkdir $path or die "could not mkdir('$path'): $!";
	    } else {
		die "could not mkdir('$path'): $!";
	    }
	}
    }
}

sub xlink_p ($ $ ) {
    my ($from,$to)=@_;
    xmkdir_p (dirname $to);
    xlink $from,$to
}

# sub xuser_uid ( $ ) {
#     my ($user)=@_;
#     my ($login,$pass,$uid,$gid) = getpwnam($user)
#       or die "xuser_uid: '$user' not in passwd file";
#     $uid
# }
{
    package Chj::xperlfunc::Getpwnam;
    use Class::Array -fields=>-publica=>
      qw(name passwd uid gid quota comment gcos dir shell expire);
    sub perhaps_get {
	my $class=shift;
	my ($user)=@_;
	my $s= bless [ getpwnam ($user) ], $class;
	if (@$s) {
	    wantarray ? @$s : $s
	} else {
	    return
	}
    }
    end Class::Array;
}
sub xgetpwnam ( $ ) {
    my ($user)=@_;
    if (wantarray) {
	my @f= Chj::xperlfunc::Getpwnam->perhaps_get($user);
	@f or croak "xgetpwnam: '$user' not in passwd file";
	@f
    } else {
	Chj::xperlfunc::Getpwnam->perhaps_get($user)
	    or croak "xgetpwnam: '$user' not in passwd file";
    }
}

{
    package Chj::xperlfunc::Getgrnam;
    use Class::Array -fields=>-publica=>
      qw(name passwd gid members);
    sub perhaps_get {
	my $class=shift;
	my ($user)=@_;
	my $s= bless [ getgrnam ($user) ], $class;
	if (@$s) {
	    wantarray ? @$s : $s
	} else {
	    return
	}
    }
    end Class::Array;
}
sub xgetgrnam ( $ ) {
    my ($group)=@_;
    if (wantarray) {
	my @f= Chj::xperlfunc::Getgrnam->perhaps_get($group);
	@f or croak "xgetgrnam: '$group' not in group file";
	@f
    } else {
	Chj::xperlfunc::Getgrnam->perhaps_get($group)
	    or croak "xgetgrnam: '$group' not in group file";
    }
}


# Also see xprint and xprintln methods in Chj::IO::File.

use Chj::BuiltinTypePredicates 'is_filehandle';

sub xprint {
    my $fh= is_filehandle ($_[0]) ? shift : *STDOUT{IO};
    print $fh @_
      or die "printing to $fh: $!"
}

sub xprintln {
    my $fh= is_filehandle ($_[0]) ? shift : *STDOUT{IO};
    print $fh @_,"\n"
      or die "printing to $fh: $!"
}


1;
