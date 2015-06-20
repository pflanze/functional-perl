#
# Copyright 2004-2015 by Christian Jaeger, ch at christianjaeger . ch
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

There are some special commands, they all start with ':'. Enter ':h'
or ':help' or ':?' to get a help text including the currently active
settings.

By default, the variable $res is set to either an array holding all
the result values (in :l mode) or the result value (in :1 mode).

By default, in :d mode, $VAR1 etc. (as shown by the Data::Dumper, but
directly, i.e. preserving references and code refs) are set as
well. (NOTE: this will retain memory for higher-numbered VAR's that
are not overwritten by subsequent runs! Set ->doKeepResultsInVARX(0)
to turn this off.)


=item CAVEAT

Lexical variables are currently made accessible in the scope of the
repl by way of a hack: what the code entered in the repl sees, are not
directly its surrounded lexicals, but local'ized package variables of
the same name aliased to them. This means that mutations to the
variables are updated in the original scope, but closures entered in
the repl will actually see the package variables, and once the code
entered into the repl returns, those will go away, hence in case the
closure was stored elsewhere, it will now refer to variables with
different values (perhaps empty).

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
use Chj::xtmpfile;
use POSIX;

sub xone_nonwhitespace {
    my ($str)=@_;
    $str=~ /^\s*(\S+)\s*\z/s
	or die "exactly one non-quoted argument must be given";
    $1
}

sub xchoose_from ($$) {
    my ($h,$key)=@_;
    exists $$h{$key} ? $$h{$key} : die "unknown key '$key'";
}


sub levels_to_user {
    my $n=1;
    while(1) {
	my ($package, $filename, $line, $subroutine, $hasargs,
	    $wantarray, $evaltext, $is_require, $hints, $bitmask, $hinthash)=
		caller($n);
	return $n
	    if ($package ne 'Chj::Util::Repl'
		and
		$package ne 'Chj::repl');

	$n++;
    }
}


use Class::Array -fields=>
  -publica=> (
	      'Historypath', #undef=none, but a default is set
	      'MaxHistLen',
	      'Prompt', # undef= build one from package on the fly
	      'Package', # undef= use caller's package
	      'DoCatchINT',
	      'DoRepeatWhenEmpty',
	      'KeepResultIn',
	      'DoKeepResultsInVARX',
	      'Pager',
              'Mode_context', # char
              'Mode_formatter', # char
              'Mode_viewer', # char
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
    $$self[KeepResultIn]="res";
    $$self[DoKeepResultsInVARX]= 1;
    $$self[Pager]= $ENV{PAGER} || "less";
    $$self[Mode_context]= 'l';
    $$self[Mode_formatter]= 'd';
    $$self[Mode_viewer]= 'V';
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


sub print_help {
    my $self= shift;
    my ($out)=@_;
    my $selection= sub {
	my ($meth,$val)=@_;
	my $method= "mode_$meth";
	$self->$method eq $val ? "->" : "  "
    };
    my $L= &$selection(context=> '1');
    my $l= &$selection(context=> 'l');
    my $s= &$selection(formatter=> 's');
    my $d= &$selection(formatter=> 'd');
    my $V= &$selection(viewer=> 'V');
    my $v= &$selection(viewer=> 'v');
    print $out qq{Repl help:
currently these commands are implemented:
  :package \$package   use \$package as new compilation package
  :p \$package         currently alias to :package
  :CMD args...         one-time command
  :MODES code...       change some modes then evaluate code

CMD is one of:
   e [n]  print lexical environment at level n (default: 0)
   b|bt   print back trace

MODES are a combination of these characters, which change the
previously used mode (indicated on the left):
  context:
$L 1  use scalar context
$l l  use list context (default)
  formatter:
$s s  show stringification
$d d  show dump (default)
  viewer:
$V V  no pager
$v v  pipe to pager ($$self[Pager])
};
}


our $use_warnings= q{use warnings; use warnings FATAL => 'uninitialized';};

our $eval_lexicals;
use Chj::singlequote 'singlequote';
sub eval_code {
    my $self= shift;
    my ($code, $get_package)=@_;
    my $skip= levels_to_user;
    require PadWalker;
    local $eval_lexicals= PadWalker::peek_my($skip);
    my $aliascode=
	join ("",
	      map {
		  my $varname= $_;
		  my $sigil= substr $varname, 0, 1;
		  my $barename= substr $varname, 1;
		  ('local our '.$varname.';'
		   .'*'.$barename
		   .' = $$Chj::Util::Repl::eval_lexicals{'
		   .singlequote($_)
		   .'};')
	      }
	      keys %$eval_lexicals);
    my $use_method_signatures=
      $Method::Signatures::VERSION ? "use Method::Signatures" : "";
    my $use_functional_parameters_=
      $Function::Parameters::VERSION ? "use Function::Parameters" : "";
    myeval ("package ".&$get_package()."; $aliascode; (); ".
	    "no strict 'vars'; $use_warnings; ".
	    "$use_method_signatures; $use_functional_parameters_; ".
	    $code)
}


# TODO: split this monstrosity into pieces.
sub run {
    my $self=shift;

    my $caller=caller(0);
    my $get_package= sub { $$self[Package] || $caller };

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
		     $ { &$get_package()."::".$varnam }

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
		       &$get_package()."> ");
		  1
	      } || do {
		  if (!length ref($@) and $@=~ /^SIGINT\n/s) {
		      print $STDOUT "\n";
		      redo DO;
		  } else {
		      die $@
		  }
	      };
	      return $line;
	    }
	};

	# for repetitions:
	my $evaluator= sub { }; # noop
      READ: {
	    while ( defined (my $input = &$myreadline) ) {
		if (length $input) {
		    my ($cmd,$args)=
		      $input=~ /^ *\:(\?|\w+\b)(.*)/s ?
			($1,$2)
			  :(undef,$input);

		    if (defined $cmd) {
			# handle commands
			eval {

			    my $set_package= sub {
				# (no package parsing, trust user)
				$$self[Package]= xone_nonwhitespace($args);
				$args=""; # XX HACK
			    };

			    my $help= sub { $self->print_help ($STDOUT) };

			    my $bt= sub {
				require Carp;
				require Chj::Backtrace;
				#local $Carp::CarpLevel=2;
				my $msg= Chj::Backtrace::Clean (Carp::longmess());
				# Since $Carp::CarpLevel doesn't really
				# seem to do what I want, hack up the
				# string:
				$msg=~ s|^\s*at [^\n]+/Repl.pm line \d+\n||s;
				print $msg;
				$args=""; # XX HACK; also, really silently drop stuff?
			    };

			    my %commands=
				(
				 h=> $help,
				 help=> $help,
				 '?'=> $help,
				 package=> $set_package,
				 p=> $set_package,
				 1=> sub { $$self[Mode_context]="1" },
				 l=> sub { $$self[Mode_context]="l" },
				 s=> sub { $$self[Mode_formatter]="s" },
				 d=> sub { $$self[Mode_formatter]="d" },
				 V=> sub { $$self[Mode_viewer]="V" },
				 v=> sub { $$self[Mode_viewer]="v" },
				 e=> sub {
				     my $skip= levels_to_user;
				     require PadWalker;
				     use Data::Dumper;
				     # XX clean up: don't want i in the regex
				     my ($maybe_level)=
					 $args=~ /^i?\s*(\d+)?\s*\z/
					 or die "expecting digits or no argument, got '$cmd'";
				     $args=""; # can't s/// above when expecting value
				     my $lexicals= eval {
					 PadWalker::peek_my($skip + ($maybe_level // 0));
				     }; # XXX check exceptions

				     if (defined $lexicals) {
					 local $Data::Dumper::Terse= 1;
					 for my $key (sort keys %$lexicals) {
					     if ($key=~ /^\$/) {
						 print "$key = ".Dumper(${$$lexicals{$key}});
					     } else {
						 print "\\$key = ".Dumper($$lexicals{$key});
					     }
					 }
				     } else {
					 print "level too deep\n"
				     }
				 },
				 bt=> $bt,
				 b=> $bt,
				);

			    while (length $cmd) {
				# XX why am I checking with and without chopping here?
				if (my $sub= $commands{$cmd}) {
				    &$sub;
				    last;
				} else {
				    my $subcmd= chop $cmd;
				    if (my $sub= $commands{$subcmd}) {
					&$sub;
					last; # XX why last? shouldn't we
					      # continue with what's left of
					      # $cmd ?
				    } else {
					print $STDERR "unknown command or mode :$cmd\n";
					last;
				    }
				}
			    }

			    1
			} || do {
			    print $STDERR "$@";
			    redo READ;
			}
		    }

		    # build up evaluator

		    my $eval=
			xchoose_from
			(+{
			   1=> sub {
			       my $vals= [ scalar $self->eval_code ($args, $get_package) ];
			       ($vals, $@)
			   },
			   l=> sub {
			       my $vals= [ $self->eval_code ($args, $get_package) ];
			       ($vals, $@)
			   },
			  },
			 $self->mode_context);

		    my $format_vals=
		      xchoose_from
			(+{
			   s=> sub {
			       (
				join "",
				map {
				    (defined $_ ? $_ : 'undef'). "\n"
				} @_
			       )
			   },
			   d=> sub {
			       # save values by side effect; UGLY? Fits
			       # here just because we only want to set in
			       # :d mode
			       if ($$self[DoKeepResultsInVARX]) {
				   no strict 'refs';
				   for my $i (0..@_-1) {
				       my $varname= &$get_package()."::VAR".($i+1);
				       no strict 'refs';
				       $$varname= $_[$i];
				   }
			       }

			       # actually do the formatting job:
			       require Data::Dumper;
			       scalar Data::Dumper::Dumper(@_);
			       # don't forget the scalar here. *Sigh*.
			   }
			  },
			 $self->mode_formatter);

		    my $view_string=
			xchoose_from
			(+{
			   V=> sub {
			       print $STDOUT $_[0]
				 or die "print: $!";
			   },
			   v=> sub {
			       eval {
				   my $o= Chj::xoutpipe ($$self[Pager]);
				   $o->xprint($_[0]);
				   $o->xfinish;
				   1
			       } || do {
				   print $STDERR "error piping to pager ".
				     "$$self[Pager]: $@\n"
				       or die $!;
			       };
			   },
			  },
			 $self->mode_viewer);

		    $evaluator= sub {
			my ($results,$error)= &$eval;

			&$view_string(do {
			    if (ref $error or $error) {
				my $err= (UNIVERSAL::can($error,"plain") ?
					  # e.g. EiD style wrapped "normal" exceptions
					  # have this method for formatting as
					  # 'plaintext' (in a programmer's sense)
					  $error->plain
					  : "$error");
				chomp $err;
				$err."\n"; # no prefix? no safe way to differentiate.
			    } else {
				if (my $varname= $$self[KeepResultIn]) {
				    $varname= &$get_package()."::$varname"
				      unless $varname=~ /::/;
				    no strict 'refs';
				    $$varname= $self->mode_context eq "1" ?
				      $$results[0] : $results;
				}
				&$format_vals(@$results)
			    }
			});
		    };

		    &$evaluator;

		} elsif ($$self[DoRepeatWhenEmpty]) {
		    &$evaluator;
		} else {
		    next;
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
*set_keepresultin= *set_keepResultIn{CODE};


__END__
todo:
- Some::Package-><tab><tab>
- Data::Dump::Streamer einbau
- $hash->{<tab>
