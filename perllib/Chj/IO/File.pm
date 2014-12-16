#
# Copyright (c) 2003-2014 by Christian Jaeger ch@christianjaeger.ch
# Published under the same terms as perl itself.
#

=head1 NAME

Chj::IO::File

=head1 SYNOPSIS

 my $f = new Chj::IO::File;
 $f->xopen("<foo/file.txt");
 my $g = Chj::IO::File->xopen("<foo/file.txt");

 ...

=head1 DESCRIPTION

Something like IO::File, but more lightweight (IO::File takes about 0.3 seconds
to load on my laptop, whereas this module takes less than 30ms), and with
methods that throw (currently untyped) exceptions on error.

NEW: $Chj::IO::ERRNO is set to $!+0 on strategic positions
    $Chj::IO::ERRSTR to $!
for later reference.
HACK state is creeping in. Because of ugly Perl bugs.
todo finish putting those into every other part of these modules.

=head1 CLASS METHODS

=over 4

=item new ("path")

Gives a new unopened filehandle object.  (Not really sure what for; you should
be able to use perl builtins on it.)

=item xopen (path [,.. ])

Creates new filehandle and calls builtin open, croaks on errors.
(May also be called on an existing object if I'm not wrong.)

=back

=head1 OBJECT METHODS

=over 4

=item read ( $buf, numbytes [, offset ] )

=item xread ( ... )

Calls builtin, without/with error checking.

=item xreadline

Same as builtin readline, but checks $! for errors. (Not sure that really works.)

=item xreadline_chomp

Does xreadline and chomp's the result(s) (unless undefined).

=item getline

Same as <$self>. Added since MIME::Parse expects this method.

=item xreadchunk ( length )

Read a chunk of max length chars/bytes and return it. Return undef on
end of file.

# IDEA: xxreadchunk that throws exception on end of file? So no check needed.

=item xxreadchunk ( length )

# Yeah try it. Only string exception so far

=item xsysreadcompletely( buf, length [,offset]) -> bool

Like xsysread, but resumes reading upon intterrupted system calls and
partial reads from pipes until the required length has been
read. Returns true if buf was read completely, false on EOF upon start
of message. EOF after having read part but not all of buf results in
an exception.

=item xsyswritecompletely( buf [,length [,offset]])

Like xsyswrite, but resumes writing upon interrupted system calls
until everything is written. Does not return anything.

=item content

=item xcontent

Returns full contents. Latter also checks $! for errors (see above).

=item seek / xseek

Only special thing is that if you only give one argument, it does
imply SEEK_SET as the whence value. (Hmmm well, there's also xrewind
for xseek(0) purpose.)

=item truncate / xtruncate

Totally normal. Just let me state that if your file pointer will not
be changed by this call, so be sure to call xrewind as well if you
plan to continue to write to the file handle.

=back

=head1 BUGS

I wanted to overload <> to xreadline(), but that does not work (on
perl 5.6.1), since the CORE::readline function will call into
<> again causing an infinite recursion. There does not seem to
be a solution, thus I leave <> the default (without error checking).

(BTW there's another perl bug:
http://bugs6.perl.org/rt2/Ticket/Display.html?id=6748
)

Not yet fully tested.

=head1 SEE ALSO

L<Chj::xopen>, L<Chj::IO::SysFile>, L<Chj::xsysopen>

=cut

# '}

package Chj::IO::File;

use strict;

our @ISA=("IO");
sub import { };

use Symbol;
use Carp;
use Fcntl qw(:DEFAULT :flock :seek :mode);

my $has_posix;
BEGIN {
    eval {
	require POSIX;
    };
    if ($@) {
	$has_posix=0;
	require Errno;
	Errno->import( 'EINVAL');
    } else {
	$has_posix=1;
	POSIX->import( 'EINVAL');
    }
}


our $DEBUG=0;

my %filemetadata; # numified => [ opened, name, path , xreadline_backwards:data  ]

sub set_path { # sets name, too
    my $self=shift;
    my ($path)=@_;
    my $meta= $filemetadata{pack "I",$self}||[];
    $$meta[1]= $path;
    $$meta[2]= $path;
}
sub unset_path { # sets name, too
    my $self=shift;
    my ($path)=@_;
    my $meta= $filemetadata{pack "I",$self}||[];
    $$meta[1]= undef;# do not play games like "former '$$meta[1]'"
    $$meta[2]= undef;
}
sub set_opened {
    my $self=shift;
    my $meta= $filemetadata{pack "I",$self}||[];
    ($$meta[0])=@_;
}
sub opened {
    my $self=shift;
    my $meta= $filemetadata{pack "I",$self} or return;
    $$meta[0]
}
sub name {
    my $self=shift;
    my $meta= $filemetadata{pack "I",$self} or return;
    $$meta[1]
}
sub path {
    my $self=shift;
    my $meta= $filemetadata{pack "I",$self} or return;
    $$meta[2]
}
sub xpath {# ATTENTION: if path is overridden, xpath must be as well!
    my $self=shift;
    my $meta= $filemetadata{pack "I",$self} or croak "xpath: file object has not yet been opened";
    defined $$meta[2] or croak "xpath: file object does not have a path - it may have been opened with a mixed path spec";
    $$meta[2]
}
sub set_opened_name { # arguments: opened,name; well could give _path too as third argument.
    my $self=shift;
    $filemetadata{pack "I",$self}= [@_];
}
sub set_opened_path {
    my $self=shift;
    my ($opened,$path)=@_;
    $filemetadata{pack "I",$self}= [$opened,$path,$path];
}

sub _quote {
    my ($str,$alternative)=@_;
    if (defined $str) {
	$str=~ s/'/\\'/sg;
	"'$str'"
    } else {
	$alternative||"undef"
    }
}

sub quotedname {
    my $self=shift;
    _quote(scalar $self->name,"(no filename)")
}

sub _numquote {
    my ($num)=@_;
    if (defined $num) {
	$num
    } else {
	"undef"
    }
}


sub new {
    my $class=shift;
    my $self= gensym;
    bless $self,$class
}


sub xopen { # should I prototype arguments?
    my $proto=shift;
    my $self= ref $proto ? $proto : $proto->new;
    my $rv;
    if (@_==1) {
	$rv= open $self,$_[0];
    } elsif (@_>=2) {
	$rv= open $self,$_[0],@_[1..$#_];
    } else {
	croak "xopen @_: wrong number of arguments";
    }
    $rv or do {
	$Chj::IO::ERRSTR=$!; $Chj::IO::ERRNO=$!+0;
	croak "xopen @_: $!";
    };
    #my $filename= $_[0]=~ /^[<>!+]+\z/ ? $_[1] : $_[0];
    #$metadata{pack "I",$self}= $filename;
    if ($_[0]=~ /^[<>!+]+\z/) {
	# separated flags and filepath, cool
	$self->set_opened_path(1,$_[1]);
    } else {
	# one-big-mix pathspec
	$self->set_opened_name(1,$_[0]);
    }
    $self
}

sub xsysopen {
    my $proto=shift;
    my $self= ref $proto ? $proto : $proto->new;
    my $rv;
    if (@_==2) {
	$rv= sysopen $self,$_[0],$_[1]    # @_[1..$#_]; geht nicht. oder doch, war nicht dieser fehler. hrm.
    } elsif (@_==3) {
	$rv= sysopen $self,$_[0],$_[1],$_[2];
    } else {
	croak "xsysopen @_: wrong number of arguments";
    }
    $rv or do{
	$Chj::IO::ERRSTR=$!; $Chj::IO::ERRNO=$!+0;
	croak "xsysopen "._quote($_[0]).", mode $_[1], perms "._numquote($_[2]).": $!";
    };
    #$metadata{pack "I",$self}= $_[0]; #join(" ",@_); ## same as above. hm. no not quite same.
    $self->set_opened_path(1,$_[0]);
    $self
}

sub sysopen {
    my $proto=shift;
    my $self= ref $proto ? $proto : $proto->new;
    my $rv;
    if (@_==2) {
	$rv= sysopen $self,$_[0],$_[1]    # @_[1..$#_]; geht nicht. oder doch, war nicht dieser fehler. hrm.
    } elsif (@_==3) {
	$rv= sysopen $self,$_[0],$_[1],$_[2];
    } else {
	croak "sysopen @_: wrong number of arguments";
    }
    $rv or return undef;
    #$metadata{pack "I",$self}= $_[0]; #join(" ",@_); ## same as above. hm. no not quite same.
    $self->set_opened_path(1,$_[0]);
    $self
}


sub read {
    my $self=shift;
    if (@_==2) {	CORE::read $self,$_[0],$_[1] }
    elsif (@_==3) {	CORE::read $self,$_[0],$_[1],$_[2] }
    else {		croak "read: wrong number of arguments" }
}

sub xread { ## (falls Perl die nicht eh schon abfangt hier:) was ist mit EINTR und EAGAIN? geben die exceptions? sollten. Eben: sollte typisierte haben. WIRKLICH.  OOooder: keine exception sondern fertigmachenrepetieren.  oooch. aber sicher nicht so wie bareperl dass non exception unfertiger return.
    my $self=shift;
    my $rv;
    if (@_==2) {	$rv= CORE::read $self,$_[0],$_[1] }
    elsif (@_==3) {	$rv= CORE::read $self,$_[0],$_[1],$_[2] }
    else { croak "xread: wrong number of arguments" }
    defined $rv or croak "xread from ".($self->quotedname).": $!";
    $rv
}

sub xreadchunk {
    my $self=shift;
    @_==1 or croak "xreadchunk: expecting 1 parameter (length)";
    my $buf;
    my $rv=CORE::read $self,$buf,$_[0];
    defined $rv or croak "xreadchunk ".$self->quotedname.": $!";
    $rv ? $buf : undef
}

sub xxreadchunk {
    my $self=shift;
    @_==1 or croak "xreadchunk: expecting 1 parameter (length)";
    my $buf;
    my $rv=CORE::read $self,$buf,$_[0];
    defined $rv or croak "xreadchunk ".$self->quotedname.": $!";
    $rv ? $buf : die "EOF\n";
}

sub sysread { ## na, könnte auch read normal lassen (von Chj::IO::File erben). Nun?
    my $self=shift;
    if (@_==2) {	CORE::sysread $self,$_[0],$_[1] }
    elsif (@_==3) {	CORE::sysread $self,$_[0],$_[1],$_[2] }
    else {		croak "sysread: wrong number of arguments" };
}

sub xsysread { ## dito. (macht buffering einen sinn? oder besser der gefahren ausweichen? na, ich will wohl eben doch noch ein spezielles xopen_excl das per dup oder so arbeitet und normalen fh macht draus.)
    my $self=shift;
    my $rv;
    if (@_==2) {	$rv= CORE::sysread $self,$_[0],$_[1] }
    elsif (@_==3) {	$rv= CORE::sysread $self,$_[0],$_[1],$_[2] }
    else {		croak "xsysread: wrong number of arguments" };
    defined $rv or croak "xsysread from ".($self->quotedname).": $!";
    $rv
}

# similar to xsyswritecompletely
sub xsysreadcompletely {
    my $self=shift;
    my $len= $_[1];
    my $offset;
    if (@_==2) {
	$offset= 0;
    } elsif (@_==3) {
	$offset= $_[2];
    } else {
	croak "xsysreadcompletely: wrong number of arguments"
    }
    my $restlen= $len;
    my $restoffset= $offset;
  LP: {
	my $rv= CORE::sysread $self,$_[0],$restlen,$restoffset;
	if (defined $rv) {
	    $restlen -= $rv;
	    $restoffset += $rv;
	    die "bug" if $restlen < 0;
	    if ($restlen > 0) {
		if ($rv==0) {
		    if ($restlen == $len) {
			# nothing was read
			0
		    } else {
			croak "xsysreadcompletely: got EOF mid message";
		    }
		} else {
		    redo LP;
		}
	    } else {
		1
		  # or $len? but that might actually be 0
	    }
	} else {
	    my $errno= $! + 0;
	    require Errno;
	    if ($errno == Errno::EINTR()) {
		#warn "interrupted system call, redo"; # yep happens
		redo LP;
	    } else {
		croak "xsysreadcompletely from ".($self->quotedname).": $!";
	    }
	}
    }
}

sub syswrite {
    my $self=shift;
    if (@_==1) {	CORE::syswrite $self,$_[0] }
    elsif (@_==2) {	CORE::syswrite $self,$_[0],$_[1] }
    elsif (@_==3) {	CORE::syswrite $self,$_[0],$_[1],$_[2] }
    else {		croak "syswrite: wrong number of arguments" };
}

sub xsyswrite {
    my $self=shift;
    my $rv;
    if (@_==1) {	$rv= CORE::syswrite $self,$_[0] }
    elsif (@_==2) {	$rv= CORE::syswrite $self,$_[0],$_[1] }
    elsif (@_==3) {	$rv= CORE::syswrite $self,$_[0],$_[1],$_[2] }
    else {		croak "xsyswrite: wrong number of arguments" };
    defined $rv or croak "xsyswrite: from ".($self->quotedname).": $!";
    $rv
}

# similar to xsysreadcompletely
sub xsyswritecompletely {
    my $self=shift;
    if (not (@_>=1 and @_<=3)) {
	croak "xsyswritecompletely: wrong number of arguments"
    }
    my (undef,$maybe_len,$maybe_offset)=@_;
    #   ^$buf
    my $len= defined $maybe_len ? $maybe_len : length($_[0]);
    my $offset= $maybe_offset||0;

    # partial COPYPASTE from xsysreadcompletely
    my $restlen= $len;
    my $restoffset= $offset;
  LP: {
	my $rv= CORE::syswrite $self,$_[0],$restlen,$restoffset;
	if (defined $rv) {
	    $restlen -= $rv;
	    $restoffset += $rv;
	    die "bug" if $restlen < 0;
	    if ($restlen > 0) {
		redo LP;
	    }
	} else {
	    my $errno= $! + 0;
	    require Errno;
	    if ($errno == Errno::EINTR()) {
		warn "interrupted system call, redo"; #
		redo LP;
	    } else {
		croak "xsyswritecompletely to ".($self->quotedname).": $!";
	    }
	}
    }
}

sub xreadline { ## todo: test error case. Difficult to do.
    my $self=shift;
    undef $!; # needed!
    if (wantarray) {
	my $lines= [ CORE::readline($self) ];
	if ($!) {
	    croak "xreadline from ".($self->quotedname).": $!";
	}
	@$lines
    } else {
	my $bufref= \ (scalar CORE::readline($self)); # dito
	if ($!) {
	    croak "xreadline from ".($self->quotedname).": $!";
	}
	$$bufref
    }
}

sub xreadline_chomp {
    my $s=shift;
    if (wantarray) {
	map {
	    chomp; $_
	} $s->xreadline
    } else {
	if (defined (my $ln= $s->xreadline)) {
	    chomp $ln;
	    $ln
	} else {
	    return
	}
    }
}

sub getline {
    my $self=shift;
    <$self>
}

sub xreadline0 {
    my $self=shift;
    local $/= "\0";
    $self->xreadline
}
#^ 'since it would be tedious' to add  once again  wantarray checking and then mapping with a Chomp   we leave that up to the receiver, good idea?.
sub xreadline0chop {
    my $self=shift;
    local $/= "\0";
    # and yes we really *have* to differ. or it would give the number of items. SIGH.
    if (wantarray) {
	map {
	    chop; $_
	} $self->xreadline
    } else {
	my $str= $self->xreadline;
	chop $str;
	$str
    }
}


{
    my $SLICE_LENGTH= 1024*8;
    my $LINEBREAK= "\n";# \r\n usw alles testen todo  und ins obj eben
    my $REVERSELINEBREAK= reverse $LINEBREAK;#!

    ##todo zeug in obj sollte gelöscht werden wenn eine der setpos methoden gemacht  und  hm  objekt vs filehandle  was in perlcore  was hier  was in OS  mess.:
    #my $BUFFER="";# string in *rerverse* order so that the *%&* regexes work.
    #my @LINES;

sub xreadline_backwards {
    my $self=shift;
    my $meta= $filemetadata{pack "I",$self}||=[];
    my $data= $$meta[3]||={};
    my $lines= $$data{lines}||=[];
    my $bufferp= \($$data{buffer}||="");
    while(!@$lines) {
	#$self->xseek(-$SLICE_LENGTH,SEEK_CUR);# problem: was passiert wenn ich über fileanfang hinweg seeke? xseek on 'xyz': Das Argument ist ungültig at (eval 19) line 1
	my $curpos= tell($self);
	if (!defined($curpos) or $curpos<0) {##correct? docu is very unprecise!
	    croak "xreadline_backwards on ".$self->quotedname.": can't seek on this filehandle?: tell: $!";
	}
	my $newpos= $curpos - $SLICE_LENGTH; $newpos=0 if $newpos<0;
	my $len_to_go= ($curpos > $SLICE_LENGTH)? $SLICE_LENGTH : $curpos;
	if ($len_to_go<=0) {
	    #warn "debug xreadline_backwards: start of file reached and nothing to go";
	    return;
	}
	$self->xseek(-($curpos > $SLICE_LENGTH ? $SLICE_LENGTH : $len_to_go),SEEK_CUR);
	my $totbuf;
	while ($len_to_go) {
	    my $buf;
	    if (my $len=$self->xread($buf, $len_to_go)) {
		$totbuf.=$buf;
		$len_to_go-=$len;
		if ($len_to_go<0) {
		    die "strange error (bug?, or maybe file changed while reading?), len_to_go = $len_to_go";
		}
	    } else {
		#die "strange error (bug?, or maybe file changed while reading?): expecting len_to_go=$len_to_go but xread returns len $len";
		#return;
		# nix mehr zu lesen   problem hinter fileende lesen?
	    }
	}
	#$self->xseek(-($curpos > $SLICE_LENGTH ? $SLICE_LENGTH : $len_to_go),SEEK_CUR);
	# ^- nochmals! weil damit es wieder da isch wo wir angefangen hatten  zickzacknähen.
	$self->xseek($newpos,SEEK_SET);
	
	# now append that to BUFFER.
	$$bufferp.= reverse $totbuf;
	# now tac off stuff from beginning.
	if ($newpos>0) { # there is something left to be read from top of file, so require a linebreak to be seen
	    while (length ($$bufferp)
		   and
		   # eine zeile ist: entweder string+ ohne linebreak hintendran, oder string{0} und linebreak  bis \z.
		   $$bufferp=~ s/^(\Q$REVERSELINEBREAK\E)(?=\Q$REVERSELINEBREAK\E)//s
		   ||
		   $$bufferp=~ s/^(.+?)(?=\Q$REVERSELINEBREAK\E)//s
		  ) {
		#warn "match1!!!!!!!!!!!: '$1'";
		push @$lines,scalar reverse( $1);
	    }
	} else { # no need to require a linebreak, begin of string is ok too.
	    while (length ($$bufferp)
		   and
		   $$bufferp=~ s/^(\Q$REVERSELINEBREAK\E)(\Q$LINEBREAK\E|\z)/$2/s
		   ||
		   $$bufferp=~ s/^(.+?)(\Q$LINEBREAK\E|\z)/$2/s
		  ) {
		#warn "match2: '$1'";
		#push @LINES,reverse $1;
		#warn "pushed2: ".reverse($1);
		#my $a=$1;
		push @$lines,scalar reverse( $1);#boah scalar.
	    }
	} # PUH.
    }
    #my $rv=
      shift @$lines;
    #warn "returning: '$rv'";
    #$rv
}
}
	
	

sub content {
    my $self=shift;
    #carp "content: you are using a non-error checking function";
    local $/;
    CORE::readline($self)
}

sub xcontent {
    my $self=shift;
    undef $!; # neeeded!
    local $/;
    my $ref= \ scalar CORE::readline($self);
    # ^- scalar is needed! or it will give undef on empty files.
    croak "xcontent on ".($self->quotedname).": $!" if $!;
    $$ref
}

# bad copypaste..
sub xcontentref {
    my $self=shift;
    undef $!; # neeeded!
    local $/;
    my $ref= \ scalar CORE::readline($self);
    # ^- scalar is needed! or it will give undef on empty files.
    croak "xcontentref on ".($self->quotedname).": $!" if $!;
    $ref
}

sub syscontent { # prolly not that efficient
    my $self=shift;
    my $buf;
    local $@;
    eval {
	$buf= \ $self->xcontent
    };
    $@ ? undef : $$buf
}
use constant BUFSIZ=> 4096*16; # 64kb
sub xsyscontent { # funny, but it seems this is more memory efficient than xcontent??
		# but it's slower. So it makes mem copies but is able to work with
		# lower memory limits??
    my $self=shift;
    my ($buf,@buf);
    while ($self->xread($buf,BUFSIZ)){ # guaranteed to either give true and data or false and it's the end or an exception
	push @buf,$buf;
    }
    join("",@buf)
}

sub print {
    my $self=shift;
    print $self @_
}
sub xprint {
    my $self=shift;
    print $self @_ or croak "xprint to ".($self->quotedname).": $!";
}

sub xprintln {
    my $self=shift;
    print $self @_,"\n" or croak "xprintln to ".($self->quotedname).": $!";
}

# is there any need for something like xsysprint? Maybe once unicode is used!
# I'll not write it yet.
# Hm, oder doch:

sub sysprint {
    my $self=shift;
    local $@;
    my $rv= eval {
	$self-> xsysprint(@_);
    };
    $@ ? undef : $rv
}

sub xsysprint { # (returns the number of chars written = length of all inputs)
		## is this unicode safe?
    my $self=shift;
    # hm, writev(2) would make sense here.. but we are not going so far.
    # Would it make sense to write all parts in individual write calls? Prolly not. So:
    my $bufref= @_ > 1 ?  \ join("",@_) : \$_[0];
    # Empirics (perl 5.6.1 iirc) show that join costs a copy even in the nargs==1 case
    # (even with taking a reference), thus we special case it.
    my $len=length $$bufref;
    my $pos=0;
    my $n;
    while ($pos<$len) {
	$pos>0 ?
	  $n=CORE::syswrite $self,substr($$bufref,$pos)
	  : $n=CORE::syswrite $self,$$bufref ;
	# Empirics show that even substr with pos 0 makes a copy, thus we specialcase it.
	defined $n or croak "xsysprint to ".($self->quotedname).": $!";##hm, will this die in the EINTR case? (should it?) todo
	$pos+=$n;
    }
    $pos
}

# xsysprintcompletely would be complicated; use xsyswritecompletely
# instead

our $use_sendfile; # may be set by user if he likes.
our $sendfile_bufsize= 4096*8; # is this somehow relevant for readahead?

sub xsendfile_to {
    my $self=shift;
    my ($out,$offset,$count)=@_;
    if (!defined $use_sendfile) {
	local $@;
	eval {
	    require IO::SendFile;
	};
	if ($@) { $use_sendfile=0; } else { $use_sendfile=1 };
    }
    ## offset is unclear: from current position (skip like), or begin
    ## of file? (whence is missing)
    $offset ||= 0;
    $count= 2**31-1
      unless defined $count; ## well...

    if (0&&$use_sendfile) {
	# seems buggy, perhaps with big files (stream-cut script)
	undef $!;
	IO::SendFile::sendfile(CORE::fileno $out, fileno $self,
			       \ $offset,
			       $count);
	# or die "xsendfile_to from ".($self->quotedname).": $!";
	if ($!) {
	    if ($!==EINVAL) {
		warn "xsendfile_to: got EINVAL, trying non-sendfile version instead"
		  if $DEBUG;
		#copy from below!
		my $buf;
		while($self->xsysread($buf,$sendfile_bufsize)) {
		    $out->xsyswritecompletely($buf);
		    #warn "wrote a piece" if $DEBUG;
		}
		#/copy
	    } else {
		croak "xsendfile_to from ".$self->quotedname.": $!" if $!;
	    }
	}
	#warn "offset=$offset now"; no need to loop?, even alarm
	#signals won't interrupt the sendfile call, surprisingly.
	
	## should change position so that it's the same with pureperl
	## and C implementation.
    } else {
	croak "offset not implemented" if $offset;

	# pure perl:
	my $buf;
	if (defined $count) {
	    my $tot=0;
	    while ($tot<$count) {
		my $cnt= $self->xsysread($buf,do {
		    if (($tot+$sendfile_bufsize)<= $count) {
			$sendfile_bufsize
		    } else {
			$count - $tot
		    }
		    #always hoping that floats are not a problem??..... so ugly prl.
		});
		last unless $cnt;
		$tot+= $cnt;
		$out->xsyswritecompletely($buf);
		#warn "wrote a piece" if $DEBUG;
	    }
	} else {
	    while($self->xsysread($buf,$sendfile_bufsize)) {
		$out->xsyswritecompletely($buf);
		#warn "wrote a piece" if $DEBUG;
	    }
	}
    }
}
#*xsendfile= \&xsendfile_to; really?

# same as xsendfile_to but use read/print from the buffering layer;
# xsendfile_to should have been called xsyssendfile_to but now it's
# probably too late right? and I'm resorting to this name:

sub xprintfile_to {
    my $self=shift;
    (@_>=1 and @_<=2) or croak "xprintfile_to needs 1-3 arguments";
    my ($out,$offset,$count)=@_;
    croak "xprintfile_to: offset currently not implemented" if $offset;
    #almost-copy from xsendfile_to:
    my $buf;
    if (defined $count) {
	my $tot=0;
	while ($tot<$count) {
	    my $cnt= $self->xread($buf,do {
		if (($tot+$sendfile_bufsize)<= $count) {
		    $sendfile_bufsize
		} else {
		    $count - $tot
		}
		#'always hoping that floats are not a problem??..... so ugly prl.'
	    });
	    last unless $cnt;
	    $tot+= $cnt;
	    $out->xprint($buf);
	    #warn "wrote a piece" if $DEBUG;
	}
    } else {
	while($self->xread($buf,$sendfile_bufsize)) {
	    $out->xprint($buf);
	    #warn "wrote a piece" if $DEBUG;
	}
    }
    #/almostcopy
}


sub xrewind {
    my $self=shift;
    seek $self,0,0
      or croak "xrewind on ".($self->quotedname).": $!";
    sysseek $self,0,0
      or croak "xrewind on ".($self->quotedname).": $!";
}

sub xseek {
    my $self=shift;  @_==1 or @_==2
      or croak "xseek: wrong number of arguments";
    seek $self,$_[0], defined $_[1] ? $_[1] : SEEK_SET
      or croak "xseek on ".($self->quotedname).": $!";
}

sub seek {
    my $self=shift;  @_==1 or @_==2 or croak "seek: wrong number of arguments";
    seek $self,$_[0], defined $_[1] ? $_[1] : SEEK_SET;
}

sub xtell {
    my $self=shift; @_==0
      or croak "xtell: wrong number of arguments";
    my $res= tell $self;
    if ($res==-1) {
	croak "xtell on ".($self->quotedname).": $!";
    } else {
	$res
    }
}

sub tell {
    my $self=shift; @_==0
      or croak "tell: wrong number of arguments";
    my $res= tell $self;
    if ($res==-1) {
	undef
    } else {
	$res
    }
}


sub xtruncate {
    my $self=shift;
    my ($len)=@_;
    $len||=0;
    truncate ($self,$len)
      or croak "xtruncate on ".($self->quotedname).": $!";
}

sub truncate {
    my $self=shift;
    my ($len)=@_;
    $len||=0;
    truncate ($self,$len);
}


sub dup2 {
    my $self=shift;
    local $@;
    eval { # slow and lazy way
	$self->xdup2(@_);
    };
    ! $@
}

sub xdup2 {
    my $self=shift;
    my $myfileno= CORE::fileno $self;
    defined $myfileno
      or croak "xdup2: filehandle of ".($self->quotedname)." is undefined (maybe it's closed?)";
    require POSIX;
    for my $dup (@_) {
	my $fileno= $dup=~ /^\d+\z/s ? $dup : CORE::fileno $dup;
	defined $fileno
	  or croak "xdup2: filehandle $dup returns no fileno (maybe it's closed?)";
	#open $dup,'<&'.$myfileno or croak "?: $!";
	# Works for reading handles. Problem: must use < or > depending on handle,
	# even +> does not work instead of <.
	# Thus instead:
	POSIX::dup2($myfileno,$fileno)
	  or croak "xdup2 ".$self->quotedname." (fd $myfileno) to $dup (fd $fileno): $!";
    }
}

sub xdup { # (return objects)
    my $self=shift;
    warn "xdup: this method is unfinished and only can create output filehandles yet";
    my $myfileno= CORE::fileno $self;
    defined $myfileno
      or croak "xdup: filehandle of ".($self->quotedname)." is undefined (maybe it's closed?)";
    require POSIX;
    my $fd= POSIX::dup($myfileno)
      or croak "xdup ".$self->quotedname." (fd $myfileno): $!";
    # turn an fd into a perl filehandle:
    #  IO::Handle has:            if ($io->fdopen(CORE::fileno(STDIN),"r")) {
    #  which works like:     open($io, _open_mode_string($mode) . '&' . $fd)
    # XX HACK:
    my $new= ref($self)->new;
    open $new,">&=$fd"
      or die "xdup: error building perl fh from fd $fd";
    $new
      # XX hm IO::Handle::fdopen is checkint if it's a glob already
}

sub xdupfd { # return integers
    my $s=shift;
    require POSIX;
    my $myfileno= CORE::fileno $s;
    defined $myfileno
      or croak "xdup: filehandle of ".($s->quotedname)." is undefined (maybe it's closed?)";
    POSIX::dup($myfileno)
	or croak "xdup ".$s->quotedname." (fd $myfileno): $!";
}

sub autoflush {
    my $self=shift;
    if (@_) {
	my ($v)=@_;
	my $old=select $self;my $oldv=$|; $|=$v; select $old; $oldv
    } else {
	defined wantarray
	  or croak "autoflush: used in void context without arguments (note that this is ".__PACKAGE__.", not IO::Handle)";
	my $old=select $self;my $oldv=$|; select $old; $oldv
    }
}

sub flush {
    my $self=shift;
    require IO::Handle;
    IO::Handle::flush($self);
}

sub xflush {
    my $self=shift;
    require IO::Handle;
    IO::Handle::flush($self)
	or die "xflush ".$self->quotedname.": $!";
}

sub xclose {
    my $self=shift;
    CORE::close $self or croak "xclose ".$self->quotedname.": $!";
    $self->set_opened(0);
}

sub close {
    my $s=shift;
    CORE::close($s);
    $s->set_opened (0);
}

*xxfinish= \&xclose;
*xfinish= \&xclose;

sub xunlink {
    my $self=shift;
    my $path= $self->xpath;
    unlink $path
      or croak "xunlink '$path': $!";
    $self->unset_path;
}

sub xlink {
    my $self=shift;
    my ($newpath)=@_;
    my $path= $self->xpath;
    link $path,$newpath
      or croak "xlink '$path','$newpath': $!";
}

sub xrename {
    my $self=shift;
    my ($to)=@_;
    my $path= $self->xpath;
    rename $path,$to
      or croak "xrename '$path' to '$to': $!";
    $self->set_path($to);
}

sub xlinkunlink {
    my $self=shift;
    my ($newpath)=@_;
    my $path= $self->xpath;
    link $path,$newpath
      or croak "xlinkunlink: link '$path','$newpath': $!";
    unlink $path
      or croak "xlinkunlink: unlink '$path': $!";
    $self->set_path($newpath);
}


if ($has_posix) { # untested?
    *stat= sub {
	my $self=shift;
	if (defined (my $fd=CORE::fileno($self))) {
	    POSIX::fstat($fd);
	} else {
	    (); ## or die?
	}
    };
} else {
    *stat= sub {
	die ("this system does not have POSIX so we can't fstat; ".
	     "if you wish you could stat the saved filename instead, ".
	     "though that could be dangerous; died");
    };
}


sub xstat {
    my $s=shift;
    require Chj::xperlfunc;
    Chj::xperlfunc::xstat($s)
}


sub fileno {
    my $s=shift;
    CORE::fileno($s)
  }


if ($has_posix) {
    my $base= do {
	if (-d "/dev/fd") {
	    "/dev/fd"
	} elsif (-d "/proc/self/fd") {
	    "/proc/self/fd"
	} else {
	    warn "missing /dev/fd or /proc/self/fd, fd_dev_path method will not work";
	    undef
	}
    };
    *Fd_dev_path= sub {
	my ($fileno)=@_;
	$base . "/" . $fileno
    };
    *fd_dev_path= sub {
	my $s=shift;
	Fd_dev_path(CORE::fileno($s))
    };
}


sub DESTROY {
    my $self=shift;
    local ($@,$!,$?);
    if ($self->opened) {
	CORE::close($self)
	  or carp "$self DESTROY: close: $!";
    }
    delete $filemetadata{pack "I",$self};
}


1
