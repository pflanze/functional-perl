# Sun Jun 13 00:04:06 2004  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2004 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Util::Repl - read-eval-print loop

=head1 SYNOPSIS

 # repl($histfilepath,$package);
 # no, make it different.
 my $repl= new Chj::Util::Repl;
 $repl->set_prompt("foo> ");# if left undefined, "$package> " is used.
 $repl->set_historypath("somefile"); # default is ~/.perl-repl_history
 $repl->run;

=head1 DESCRIPTION

Enters an interactive read-eval-print loop.
Term::ReadLine with history is active.
The loop can be exited by typing ctl-d.
Entering the empty string re-eval's the last entry.
Some autocompletion exists.

There are some special commands:

=over 4

=item :package Foo

Use  package Foo for subsequent entries and ->run calls on the same Repl object.

=item :l code

Eval code in list context, print the result as one element per line, and store it as array ref in $res

=back

For a list of all settable options see source of this module.

=item TODO

 - 'A::Class-> ' method completion
 - maybe '$ans->[1]->' method completion

=item IDEAS

 - maybe handle ->SUPER:: completion?
 - differ between emptylistofcompletions (no &subs for example) (empty list) and no sigil there so dunno-how-to-complete (undef?, exception?, ??).

=item BUGS

Completion:

 - $ does not filter out scalars only, since perl is not able to do so :/
 - % and * make completion stop working unless you put a space after those sigils. (@ and & work as they should)
 - keep the last 10 or so completion lists, and use those in the -> case if the var's type could not be determined.

=cut

#'

# Changelog:
# cj Mon, 19 Jul 2004 01:40:36 +0200: add check if $ENV{HOME}


package Chj::Util::Repl;

use strict;

sub myeval {# this has to be at the top before any lexicals are defined! so that lexicals from this module are not active in the eval'ed code.
    eval $_[0]
}

use Chj::Class::methodnames;
use Chj::xoutpipe();
use Chj::end();
use Chj::xtmpfile;

use Class::Array -fields=>
  -publica=> (
	      'Historypath', #undef=none, but a default is set
	      'MaxHistLen',
	      'Prompt', # undef= build one from package on the fly
	      'Package', # undef= use caller's package
	      'DoCatchINT',
	      'DoRepeatWhenEmpty',
	      'DoCatchExceptions',#well, without this true, not even the history would be written currently, bound to be changed
	      'KeepResultIn',
	      'Pager',
	     );

sub new {
    my $class=shift;
    my$self= $class->SUPER::new;
    $$self[Historypath]="$ENV{HOME}/.perl-repl_history" if $ENV{HOME};# check is important heh
    $$self[MaxHistLen]= 100;
    #$$self[Prompt]= "repl> ";
    #$$self[Package]="repl";
    $$self[DoCatchINT]=1;
    $$self[DoRepeatWhenEmpty]=1;
    $$self[DoCatchExceptions]=1;
    $$self[KeepResultIn]="res";
    $$self[Pager]= $ENV{PAGER}||"less"; #ischn't that senselees to look up for nothing if we want to override it? issch't it besser to make an accessor.
    $self
}

sub splitpackage { #todo auslagern?.
    my ($package)=@_;#may be partial.
    if ($package=~ /(.*)::(.*)/s) {
	($1,$2)
    } else {
	("",$package)
    }
}

my $PACKAGE= qr/\w+(?:::\w+)*/;
use Chj::Util::Repl::corefuncs();
our @builtins=  # those cannot be fetched from any namespace as it seems.
  #do {
  #    my $txt=<<'END';
  Chj::Util::Repl::corefuncs;


sub __signalhandler { die "SIGINT\n" }

our $term; # local'ized but old value is reused if present.
our $current_history; # local'ized; array(s).
sub run {
    my $self=shift;

    my $caller=caller(0);
    #local $SIG{INT}=
    #  $$self[DoCatchINT] ? sub { die "SIGINT\n" } : $SIG{INT}; ##ok?
    my $oldsigint= $SIG{INT};
    #man perlipc:
    use POSIX;
    #sigaction SIGINT, new POSIX::SigAction sub { die "SIGINT\n" }
    sigaction SIGINT, new POSIX::SigAction __PACKAGE__.'::__signalhandler'  # the only way to make it work in both perl 5.6 and 5.8 as it seems
      or die "Error setting SIGALRM handler: $!\n";

    require Term::ReadLine;
    # only start one of them, do not nest (reason for segfaults i suppose). okay?.
    local our $term = $term || new Term::ReadLine 'Repl';
    # ok das scheint zwar zu gehen und evtl. helfen, aber history die in subrepl's term aufgebaut wird, wird dann nach quit auch in parent sein. zwar nicht gesaved, aber drin. (ps sollt ich nestlevel mit als filename verwenden? damit die nested histories auch separat gespeichert werden  nicht bloss .calc_history und .perl-repl_history)
    #nun, Term::ReadLine ist ein hash Term::ReadLine=HASH(0x8435090) und der hat history dort drin?
    #ah nein, die eignetlichen historydaten sind nicht im hash. tja. also neusetzen jedesmal.

    my $attribs= $term->Attribs;
    local $attribs->{attempted_completion_function}= sub {
	my ($text, $line, $start, $end) = @_;
	#warn "start=$start, end=$end, text='$text', line='$line'";
	my $partie= substr($line,0,$end);# nicht $start, ausser ich wolle echt so komische ersetzereien machen.
	#print $STDERR "partie='$partie'";
	$attribs->{completion_append_character}=" ";#reset to the default before deciding upon it.
	my @matches= do {
	    # arrow completion:
	    if ($partie=~ /(.*)\$(\w+)\s*->\s*([{\[]\s*)?(\w*)\z/s) {
		# need to know the class of that thing. either statically (huh) or just peek at it
		my ($pre,$varnam,$brace,$alreadywritten)=($1,$2,$3,$4);# muss ich echt selber schauen was er schon geschrieben hat und dann meine liste von values bei jedem mal ausfiltern?(->neinoffenbardochnicht¿)
		no strict 'refs';
		my $r;
		if (my $val= do{
		    # try to get the value, or at least the package.
		    $ { ($$self[Package]||$caller)."::".$varnam }
		      or
			# if I could run code side-effect free... or compile-only and disassemble....
			do {
			    # try to parse the perl myself. not very probable to succeed but who knows?
			    if ($partie=~ /.*(?:^|;)\s*(?:(?:my|our)\s+)?\$$varnam\s*=\s*(?:new\w*\s+($PACKAGE)|($PACKAGE)\s*->\s*new)/s) { # .* at the begin to force the latest possible match, ok?  my/our ist optional weil eh kein use strict herrscht.
				$r=$1;#warn "success: r=$r";
				1
			    } else {#warn "no success";
				0
			    }
			}
		}) {
		    #warn "jo, habe n value von \$$varnam gekriegt";
		    if ($r||=ref($val)) {
			if ($r eq 'HASH') {
			    #("{") #scheisse, es wird ein space hintendrangetan obwohl ich doch gar nöd fertighabenwollte.
			    #("{hallo}","{ballo}")
			    if ($brace) {
				map {"$_}"} keys %$val
			    } else {
				#("{")
				map {"{$_}"} keys %$val
				  #????????warum muss ich hier nun nicht mehr grep mit alreadywritten machen?????
			    }
			}
			elsif ($r eq 'ARRAY') { #hum, rausfinden ob es classarray isch und wenn dann, evtl fullyqualified, fieldconstants rausgeben?
			    ("[")
			}
			elsif ($r eq 'CODE') {
			    ("(")
			}
			elsif ($r eq 'SCALAR') {
			    ("SCALAR")##
			}
			elsif ($r eq 'IO') {
			    ("IO")##
			}
			elsif ($r eq 'GLOB') {
			    ("GLOB")##
			}
			else {
			    # object
			    my @a= methodnames($r);
			    #print $STDERR "[",join(",",@a),"]";
			    grep {
				# it has to match the already-written part of the string
#				/^\Q$alreadywritten\E/
#				  and
# gar nöd nötig. warum dachte ich??? evtl. wurde  $attribs->{completion_word} wieder gelöscht oder so
				    # exclude some of the possible methodnames:
				    # - all-uppercase when characters are contained.
				    not(/[A-Z]/ and uc($_) eq $_)
			    } @a
			}
		    } else {
			()
		    }
		} else {
		    #warn "no value von \$$varnam";
		    ()
		}
	    #} elsif ($partie=~ /\"(.*)\z/) {
	    } elsif ($partie=~ tr/"/"/ % 2) { # odd number of quotes means we are inside
		#print $STDERR ".";
		()
	    } elsif ($partie=~ tr/'/'/ % 2) { # odd number of quotes means we are inside
		#print $STDERR ".";
		()
	    } elsif ($partie=~ /(^|.)\s*(${PACKAGE}(?:::)?)\z/s
		or
		$partie=~ /([\$\@\%\*\&])\s*(${PACKAGE}(?:::)?|)\z/s  # |) is on purpose, accept the empty string, that's better than )? which leaves undef behind.
	       ) { # namespace completion
		####????? warum ersch jetzt gesehen?: my ($partialpackage)=@_;
		my ($sigil,$partialpackage)=($1,$2);
		#if ($sigil) {
		#    $sigil
		# if not containing colons, might also be a subroutine (heck, or anything!) of current package
		no strict 'refs';
# 		#if ($partialpackage=~ /::/) {
# 		    # really fully qualified
# 		    #my $upper= nextupperpackage($partialpackage);
# 		#    my ($upperpackage,$localpart)= splitpackage($partialpackage);
# 		    # localpart is '' if partialpackage ends in ::
# 		} else {
# 		    # not necessarily fully qualified
# 		}
	        my ($upperpackage,$localpart)= splitpackage($partialpackage);
		#warn "upperpackage='$upperpackage', localpart='$localpart'\n";
		# if upperpackage is empty, it might also be a non-fully qualified, i.e. local, partial identifier.
		#grep {
		#    /^\E$localpart\Q/
		#}
		my $validsigil=do{
		    $sigil and do {
			my $h={ '$'=>'SCALAR',
                                '@'=>'ARRAY',
                                '%'=>'HASH', # 'SCALAR',##?? 'HASH',  hm problem liegt bei readline, mit einem space nach % gehts auch. need a better completion function than the one from gnu realine? :/
                                '*'=>'SCALAR',  # really 'GLOB', but that would make it invisible. SCALAR matches everything, which is what we want. strange, huh? heh.
                                '&'=>'CODE' }; #'};
			#$h->{$sigil} ? $sigil : ''
			$h->{$sigil}
		    };
		};
		#print $STDERR "<$validsigil>";
		my $symbols_for_package= sub{
		    my ($package)=@_;
		    grep {
			# only show 'usable' ones.
			/^\w+(?:::)?\z/
		    } do {
			if ($validsigil) {
			    #print $STDERR ".$validsigil.";
			    grep {
				/::\z/  # either it's a namespace which we want to see regardless of type, or: type exists
				  or
				*{ $package."::".$_ }{$validsigil}
			    }
			    keys %{ $package."::" }
			} else {
			    keys %{ $package."::" }
			}
		    }
		};
		my @a=do {
		    ($symbols_for_package->($upperpackage),

		     length($upperpackage) ?
		     () :
		     ($symbols_for_package->($self->[Package]||$caller),
		      ($validsigil ? () : @builtins))
		    )
		};
		#print $STDOUT Data::Dumper::Dumper(\@a);
		#("HAHAHA")
		# ach so muss wirklich ganzes teil wieder ranstellen. nun ja nöd so schlecht sieht man es realistischer immer das ganze package
		# hm, nun fehlt nur noch dass, falls es mit :: aufhört, oder auch generell, nicht space anhängt bei der completion.
		#$attribs->{completion_append_character}=""; oder unten wenn es nicht stört dass nie.
		#och ich wollte nur wenn es NICHT auf :: endet. muss ich den space an den einzelnen vervollständiger fügen.
		$attribs->{completion_append_character}="";
		map {
		    if (/::\z/) {
			$_
		    } else {
			"$_ "
		    }
		} do {
		    if (length $upperpackage) {
			map {
			    $upperpackage."::$_"
			} @a
		    } else {
			@a
		    }
		}
	    } else {
		()
	    }
	};
	if (@matches) {
	    #print $STDERR "<".join(",",@matches).">";
	    $attribs->{completion_word}= \@matches;# sort is not necessary.
	    #$attribs->{completion_append_character}="";#gool.
	    return $term->completion_matches($text,
					     $attribs->{list_completion_function})
	} else {
	    # restore defaults.
	    $attribs->{completion_append_character}=" ";
	    return ()
	}
    };
    my $OUT = $term->OUT || *STDOUT;## * korrekt?
    my $STDOUT= $OUT; my $STDERR= $OUT;

    my ($oldinput);
    {
	my @history;
	local $current_history= \@history;# this is what nested repl's will use to restore the history in the $term object
	if (defined $$self[Historypath]) {
	    # clean history of C based object before we re-add the saved one:
	    $term->clear_history;
	    if (open HIST,"<$$self[Historypath]"){
		@history= <HIST>;
		close HIST;
		for (@history){
		    chomp;
		    $term->addhistory($_);
		}
	    }
	}
	$term->MinLine(undef); # do not add input to history automatically. -> allows me to do it myself.
	#sub myreadline {
	my $myreadline=sub {
	  DO:{
		my $line= eval {
		    $term->readline($$self[Prompt] or ($$self[Package]||$caller)."> ");
		};
		if ($@) {
		    if ($@ eq "SIGINT\n") {
			print $STDOUT "\n";
			redo DO;
		    } else {
			die $@
		    }
		}
		return $line;
	    }
	};
	while ( defined (my $input = &$myreadline) ) {
	    my $res;
	    my ($evaluator,$error);
	    #my $_end=Chj::end{undef $evaluator}; #nötig?
	    if (length($input)) {
		my ($cmd,$args)=
		  $input=~ /^ *\:(\w+)\b(.*)/s ?
		    ($1,$2)
		      :(undef,$input);
		$evaluator=sub {
		    $res= myeval "package ".($$self[Package]||$caller)."; no strict 'vars'; $args";
		    #$oldinput= $input;# na könnte man auch nach draussen nehmen?
		    # eh, nein , ist ja eben eh no nöd fertig. todo. eben durch evaluatorbehalten lösen.
		    $oldinput= $args;
		    $error=$@;
		    #$evaluator= sub{ (defined $res ? $res : 'undef'), "\n"};##copy from below
		    #warn "default evaluator called";
		    #$DB::single=1;
		    (defined $res ? $res : 'undef'), "\n"
		};
		if (defined $cmd) {
		    # special command
		    sub xonesymbol {#well, symbol is wrong name
			my ($str)=@_;
			$str=~ /^\s*(\S+)\s*\z/s or die "exactly one non-quoted argument must be given\n";
			$1
		    }
		    my $help=sub {
			#$evaluator=sub{ ...  könnte man hier auch so lösen doch. könnte man logik bissel vereinf.
			print $STDOUT "Repl help:\n";
			print $STDOUT "currently these commands are implemented:\n";
			print $STDOUT ":package \$pack   use \$pack as new compilation package\n";
			print $STDOUT ":l ...           evaluate ... in list context and print list one item per line\n";
			print $STDOUT ":d ...           evaluate ... in list context and print result through Data::Dumper\n";
			print $STDOUT ":v ...           evaluate ... and pipe the result to the pager ($$self[Pager])\n";
			print $STDOUT "Some commands may be chained, like :vl means view list output one line per item in the pager.\n";
			print $STDOUT "(But in contrast, at the time being, in :ld or :dl the leftmost command just overrides the other.)\n";
		    };
		    my %commands= (
				   package=>sub{
				       $$self[Package]= xonesymbol($args);
				   },
				   p=>sub{## might be replaced in later version with sth else!
				       $$self[Package]= xonesymbol($args);
				   },
				   h=>$help,
				   help=>$help,
				   l=>sub {
				       ## ps. todo should refactor so that the empty==reeval case also works with this
				       $res=
					 [ myeval "package ".($$self[Package]||$caller)."; no strict 'vars'; $args" ];
				       $error=$@;
				       $evaluator=sub{ map { "$_\n" } @$res};
				       # then later still print the ref? hm. need to go below anyway, so:
				       #$oldinput= $input; just plain wrong
				       #$input=$args; not much sense since emptyness will then eval w/o :l - see above todo
				   },
				   d=>sub {
				       $res=
					 [ myeval "package ".($$self[Package]||$caller)."; no strict 'vars'; $args" ];
				       $error=$@;
				       $evaluator= sub{
					   require Data::Dumper;
					   Data::Dumper::Dumper(@$res);
				       };
				   },
				   v=>sub {
				       #warn "opening pager $$self[Pager]";
				       my $o= Chj::xoutpipe ($$self[Pager]);
				       #$o->xprint($flag_l ? @$res : $res); ## ist es hacky, res zu nehmen, "also kein echtes chaining"
				       $o->xprint(&$evaluator); #EH nein.  eben doch einfach @data irgendwie sowas irgend.  ah ps von wegen $res  vs @res   ein lmbd kann quasi beides (sein oder/als auch liefern) hehe.   oder nun mal umgestellt eben auf value  print usserhalb.
				       $o->xfinish;
				       #$flag_noprint=1;#hmm. oder nichts von hier returnen?  aber $res soll doch der Wert bleiben?.
				       # ah, nice idea:
				       $evaluator= undef;
				   },
				  );
		    while(length $cmd){
			if (my $sub= $commands{$cmd}) {
			    eval {
				&$sub
			    };
			    print $STDOUT $@ if ref$@ or $@;
			    last;
			} else {
			    my $subcmd= chop $cmd;
			    if (my $sub= $commands{$subcmd}) {
				eval {
				    &$sub
				};
				print $STDOUT $@ if ref$@ or $@;
			    } else {
				print $STDOUT "unknown special command :$cmd\n";
				last;
			    }
			}
		    }
    #		next unless $flag_l;# excludes entry also from history, hrm. well ok except in the case of _l.
		} else {
		    # $evaluator already set.
		}
	    } elsif ($$self[DoRepeatWhenEmpty] and defined $oldinput) {
		# todo: keep same evaluator as last time or so. so that list context etc is kept as well.
		$res=
		  myeval "package ".($$self[Package]||$caller)."; no strict 'vars'; $oldinput";
		$error=$@;
		$evaluator= sub{ (defined $res ? $res : 'undef'), "\n"};##copy from above. ps wenn ich  einfach  erster step ist wert producen  mache,  und   ja  irgend  dann wär easier.  tun.
	    } else {
		next;
	    }
	    # Wed, 02 Feb 2005 18:53:20 +0100  was macht  das -^.
	    if (ref $error or $error) {
		if (!$$self[DoCatchExceptions]) {
		    die $error
		}
		my $err= (UNIVERSAL::can($error,"plain") ?  # e.g. EiD style wrapped "normal" exceptions have this method for formatting as plaintext in a programmer sense
			  $error->plain
			  : "$error");
		chomp $err;
		$err.="\n";
		print $STDERR $err;
	    } else {
		if($evaluator) {
		    print $OUT (&$evaluator);# komisch, klammern nötig sonst entsteht komischer müll, 'A h  d%' statt '1' und so.
		}
		if (my $varname= $$self[KeepResultIn]) {
		    $varname= ($$self[Package]||$caller)."::$varname" unless $varname=~ /::/;
		    no strict 'refs';
		    $$varname= $res;
		    #print "kept '$res' in '$varname', it is now '$$varname'\n";
		}
	    }
	    if (length $input and ((!defined $history[-1]) or $history[-1] ne $input)) {
		push @history,$input;
		chomp $input;
		$term->addhistory($input);
		#splice @history,0,@history-$$self[MaxHistLen] =();
		if ($$self[MaxHistLen] >= 0){# <-prevent endless loop
		    shift @history while @history>$$self[MaxHistLen];
		}
	    }
	}
	print $STDOUT "\n";
	if (defined $$self[Historypath]) {
	    eval {
		my $f= xtmpfile $$self[Historypath];
		$f->xprint("$_\n") for @history;
		$f->xclose;
		$f->xputback(0600);
	    };
	    if(ref$@ or$@){
		warn "could not write history file: $@"
	    }
	}
	$SIG{INT}= defined($oldsigint)? $oldsigint : "DEFAULT";  ##is there no other return path from sub run? should I use DESTROY objects like in C++ for this??  -> nein keine return's aber wenn exceptions not trapped gehts fehl.
    }
    # restore previous history, if any
    if ($current_history) {
	$term->clear_history;
	for (@$current_history){
	    chomp;
	    $term->addhistory($_);
	}
    }
}


end Class::Array;
# tja: for backwards compatibility:
*set_maxhistlen= *set_maxHistLen{CODE};
*set_docatchint= *set_doCatchINT{CODE};
*set_dorepeatwhenempty= *set_doRepeatWhenEmpty{CODE};
*set_docatchexceptions= *set_doCatchExceptions{CODE};
*set_keepresultin= *set_keepResultIn{CODE};


__END__
todo:
- evalscalarfix
- Some::Package-><tab><tab>
- Data::Dump::Streamer einbau
- $hash->{<tab>
