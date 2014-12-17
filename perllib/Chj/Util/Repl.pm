#
# Copyright 2004-2014 by Christian Jaeger, ch at christianjaeger . ch
# Published under the same terms as perl itself
#

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
Entering the empty string re-evaluates the last entry.
Some autocompletion exists.

There are some special commands:

=over 4

=item :package Foo

Use package Foo for subsequent entries and ->run calls on the same
Repl object.

=item :l code

Eval code in list context, print the result as one element per line,
and store it as array ref in $res

=back

For a list of all settable options see source of this module.

=item TODO

 - 'A::Class-> ' method completion
 - maybe '$ans->[1]->' method completion
 - fix problem with exception display w/o :l mode
 - with :v, already the output during computation should go to less, right? or introduce :V maybe?
 - fix '$Foo ->bar<tab>' completion where $Foo just actually contains the classname (or even an object) at runtime ehr parsetime already.

=item IDEAS

 - maybe handle ->SUPER:: completion?
 - differ between emptylistofcompletions (no &subs for example) (empty list) and no sigil there so dunno-how-to-complete (undef?, exception?, ??).

=item BUGS

Completion:

 - $ does not filter out scalars only, since perl is not able to do so :/
 - % and * make completion stop working unless you put a space after those sigils. (@ and & work as they should)
 - keep the last 10 or so completion lists, and use those in the -> case if the var's type could not be determined.

=cut


package Chj::Util::Repl;

use strict;

sub myeval {# this has to be at the top before any lexicals are
            # defined! so that lexicals from this module are not
            # active in the eval'ed code.
    eval $_[0]
}

use Chj::Class::methodnames;
use Chj::xoutpipe();
use Chj::end();
use Chj::xtmpfile;
use POSIX;

use Class::Array -fields=>
  -publica=> (
	      'Historypath', #undef=none, but a default is set
	      'MaxHistLen',
	      'Prompt', # undef= build one from package on the fly
	      'Package', # undef= use caller's package
	      'DoCatchINT',
	      'DoRepeatWhenEmpty',
	      'DoCatchExceptions', # well, without this true, not even
                                   # the history would be written
                                   # currently, bound to be changed
	      'KeepResultIn',
	      'Pager',
	     );

sub new {
    my $class=shift;
    my$self= $class->SUPER::new;
    $$self[Historypath]= "$ENV{HOME}/.perl-repl_history" if $ENV{HOME};
    $$self[MaxHistLen]= 100;
    #$$self[Prompt]= "repl> ";
    #$$self[Package]="repl";
    $$self[DoCatchINT]=1;
    $$self[DoRepeatWhenEmpty]=1;
    $$self[DoCatchExceptions]=1;
    $$self[KeepResultIn]="res";
    $$self[Pager]= $ENV{PAGER} || "less";
    $self
}

# (move to some lib?)
sub splitpackage {
    my ($package)=@_; # may be partial.
    if ($package=~ /(.*)::(.*)/s) {
	($1,$2)
    } else {
	("",$package)
    }
}

my $PACKAGE= qr/\w+(?:::\w+)*/;

use Chj::Util::Repl::corefuncs();
our @builtins= Chj::Util::Repl::corefuncs;


sub __signalhandler { die "SIGINT\n" }

our $term; # local'ized but old value is reused if present.

our $current_history; # local'ized; array(s).

sub run {
    my $self=shift;

    my $caller=caller(0);
    my $oldsigint= $SIG{INT};
    # It seems this is the only way to make signal handlers work in
    # both perl 5.6 and 5.8:
    sigaction SIGINT,
      new POSIX::SigAction __PACKAGE__.'::__signalhandler'
	or die "Error setting SIGALRM handler: $!\n";

    require Term::ReadLine;
    # only start one readline instance, do not nest (otherwise seem to
    # lead to segfaults). okay?.
    local our $term = $term || new Term::ReadLine 'Repl';
    # This means that the history from nested repls will also show up
    # in the history of the parent repl. Not saved, but within the
    # readline instance. (Correct?)
    # XX: idea: add nesting level to history filename?

    my $attribs= $term->Attribs;
    local $attribs->{attempted_completion_function}= sub {
	my ($text, $line, $start, $end) = @_;
	my $part= substr($line,0,$end);

	#reset to the default before deciding upon it:
	$attribs->{completion_append_character}=" ";

	my @matches= do {
	    # arrow completion:
	    if (my ($pre,$varnam,$brace,$alreadywritten)=
		$part=~ /(.*)\$(\w+)\s*->\s*([{\[]\s*)?(\w*)\z/s) {
		# need to know the class of that thing
		no strict 'refs';
		my $r;
		if (my $val=
		    (
		     # try to get the value, or at least the package.
		     $ { ($$self[Package]||$caller)."::".$varnam }

		     or
		     do {
			 # (if I could run code side-effect free... or
			 # compile-only and disassemble....)  Try to
			 # parse the perl myself
			 if ($part=~ /.* # force latest possible match (ok?)
				      (?:^|;)\s*
				      (?:(?:my|our)\s+)?
				      # ^ optional for no 'use strict'
				      \$$varnam
				      \s*=\s*
				      (?:new\w*\s+($PACKAGE)
				      |($PACKAGE)\s*->\s*new)
				     /sx) {
			     $r=$1;
			     1
			 } else {
			     0
			 }
		     })) {
		    #warn "got value from \$$varnam";
		    if ($r||=ref($val)) {
			if ($r eq 'HASH') {
			    #("{")
			    #("{hallo}","{ballo}")
			    if ($brace) {
				map {"$_}"} keys %$val
			    } else {
				#("{")
				map {"{$_}"} keys %$val
				  #(why no need for grep alreadywritten here?)
			    }
			}
			elsif ($r eq 'ARRAY') {
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
			    grep {
				# (no need to check for matching the
				# already-written part of the string
				# here (with something like
				# /^\Q$alreadywritten\E/), why? Maybe
				# $attribs->{completion_word} was
				# deleted or?)

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
	    } elsif ($part=~ tr/"/"/ % 2) {
		# odd number of quotes means we are inside
		()
	    } elsif ($part=~ tr/'/'/ % 2) {
		# odd number of quotes means we are inside
		()
	    } elsif ($part=~ /(^|.)\s*(${PACKAGE}(?:::)?)\z/s
		     or
		     $part=~ /([\$\@\%\*\&])
			      \s*
			      (${PACKAGE}(?:::)?|)
			      # ^ accept the empty string
			      \z/sx) {
		# namespace completion
		my ($sigil,$partialpackage)=($1,$2);

		no strict 'refs';

	        my ($upperpackage,$localpart)= splitpackage($partialpackage);
		#warn "upperpackage='$upperpackage', localpart='$localpart'\n";

		# if upperpackage is empty, it might also be a
		# non-fully qualified, i.e. local, partial identifier.
		
		my $validsigil=
		  ($sigil and
		   +{
		     '$'=>'SCALAR',
		     '@'=>'ARRAY',
		     '%'=>'HASH',
		     # ^ (problem with readline library, with a space
		     # after % it works too; need better completion
		     # function than the one from gnu readline?) 
		     # (years later: what was this?)
		     '*'=>'SCALAR',
		     # ^ really 'GLOB', but that would make it
		     # invisible. SCALAR matches everything, which is
		     # what we want.
		     '&'=>'CODE'
		    }->{$sigil});
		#print $STDERR "<$validsigil>";

		my $symbols_for_package= sub {
		    my ($package)=@_;
		    grep {
			# only show 'usable' ones.
			/^\w+(?:::)?\z/
		    } do {
			if ($validsigil) {
			    #print $STDERR ".$validsigil.";
			    grep {
				(/::\z/
				 # either it's a namespace which we
				 # want to see regardless of type, or:
				 # type exists
				 or
				 *{ $package."::".$_ }{$validsigil})
			    } keys %{ $package."::" }
			} else {
			    keys %{ $package."::" }
			}
		    }
		};
		my @a=
		  ($symbols_for_package->($upperpackage),

		   length($upperpackage) ?
		   () :
		   ($symbols_for_package->($self->[Package]||$caller),
		    ($validsigil ? () : @builtins))
		  );

		#print $STDOUT Data::Dumper::Dumper(\@a);

		# Now, if it ends in ::, or even generally, care about
		# it not appending space on completion:
		$attribs->{completion_append_character}="";

		(
		 map {
		     if (/::\z/) {
			 $_
		     } else {
			 "$_ "
		     }
		 }
		 (length ($upperpackage) ?
		  map {
		      $upperpackage."::$_"
		  } @a
		  : @a)
		)
	    } else {
		()
	    }
	};
	if (@matches) {
	    #print $STDERR "<".join(",",@matches).">";

	    $attribs->{completion_word}= \@matches;
	    # (no sorting necessary)

	    return
	      $term->completion_matches
		($text,
		 $attribs->{list_completion_function})
	} else {
	    # restore defaults.
	    $attribs->{completion_append_character}=" ";
	    return ()
	}
    };

    my $OUT = $term->OUT || *STDOUT;## * correct?
    my $STDOUT= $OUT; my $STDERR= $OUT;

    my ($oldinput);
    {
	my @history;
	local $current_history= \@history;
	# ^ this is what nested repl's will use to restore the history
	# in the $term object
	if (defined $$self[Historypath]) {
	    # clean history of C based object before we re-add the
	    # saved one:
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
	# do not add input to history automatically (-> allows me to
	# do it myself):
	$term->MinLine(undef);

	my $myreadline= sub {
	  DO: {
	      my $line;
	      eval {
		  $line=
		      $term->readline
		      ($$self[Prompt]
		       or
		       ($$self[Package]||$caller)."> ");
		  1
	      } || do {
		  if (!ref($@) and
		      ($@ eq "SIGINT\n"
		       or $@=~ /^SIGINT\n\t\w/s
		       # ^ when Chj::Backtrace is in use
		      )) {
		      print $STDOUT "\n";
		      redo DO;
		  } else {
		      die $@
		  }
	      };
	      return $line;
	    }
	};

	while ( defined (my $input = &$myreadline) ) {
	    my $res;
	    my ($evaluator,$error);
	    #my $_end=Chj::end{undef $evaluator}; #nötig?

	    if (length $input) {
		my ($cmd,$args)=
		  $input=~ /^ *\:(\w+)\b(.*)/s ?
		    ($1,$2)
		      :(undef,$input);

		$evaluator= sub {
		    $res= myeval ("package ".($$self[Package]||$caller).";".
				  "no strict 'vars'; $args");
		    $oldinput= $args;
		    $error=$@;
		    (defined $res ? $res : 'undef'), "\n"
		};

		if (defined $cmd) {
		    # special command
		    sub xonesymbol {#well, symbol is wrong name
			my ($str)=@_;
			$str=~ /^\s*(\S+)\s*\z/s
			    or die "exactly one non-quoted argument must be given\n";
			$1
		    }

		    my $help= sub {
			# (could also do $evaluator=sub{ ...  and thus
			# simplify the logic?)
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
				       my $o= Chj::xoutpipe ($$self[Pager]);
				       #$o->xprint($flag_l ? @$res : $res); ## ist es hacky, res zu nehmen, "also kein echtes chaining"
				       $o->xprint(&$evaluator); #EH nein.  eben doch einfach @data irgendwie sowas irgend.  ah ps von wegen $res  vs @res   ein lmbd kann quasi beides (sein oder/als auch liefern) hehe.   oder nun mal umgestellt eben auf value  print usserhalb.
				       $o->xfinish;
				       #$flag_noprint=1;#hmm. oder nichts von hier returnen?  aber $res soll doch der Wert bleiben?.
				       # ah, nice idea:
				       $evaluator= undef;
				   },
				  );
		    while (length $cmd) {
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
		# (XX: keep same evaluator as last time, so that list
		# context etc is preserved as well?)
		$res=
		    myeval ("package ".($$self[Package]||$caller).";".
			    "no strict 'vars'; $oldinput");
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
		my $err= (UNIVERSAL::can($error,"plain") ?
			  # e.g. EiD style wrapped "normal" exceptions
			  # have this method for formatting as
			  # 'plaintext' (in a programmer's sense)
			  $error->plain
			  : "$error");
		chomp $err;
		print $STDERR $err."\n";
	    } else {
		if ($evaluator) {
		    print $OUT (&$evaluator);
		    # odd, parens necessary otherwise getting noise,
		    # 'A h d%' instead of '1' etc.
		}
		if (my $varname= $$self[KeepResultIn]) {
		    $varname= ($$self[Package]||$caller)."::$varname"
			unless $varname=~ /::/;
		    no strict 'refs';
		    $$varname= $res;
		    #print "kept '$res' in '$varname', it is now '$$varname'\n";
		}
	    }
	    if (length $input and
		((!defined $history[-1]) or $history[-1] ne $input)) {
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
	$SIG{INT}= defined($oldsigint)? $oldsigint : "DEFAULT";
	# (Is there no other return path from sub run? should I use
	# DESTROY objects for this? -> nope, no returns, but if
	# exceptions not trapped it would fail)
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
# for backwards compatibility:
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
