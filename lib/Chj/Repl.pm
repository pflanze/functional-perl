#
# Copyright (c) 2004-2015 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

Chj::Repl - read-eval-print loop

=head1 SYNOPSIS

 my $repl= new Chj::Repl;
 $repl->set_prompt("foo> ");
 # ^ if left undefined, "$package$perhapslevel> " is used
 $repl->set_historypath("somefile"); # default is ~/.perl-repl_history
 $repl->set_env_PATH ($safe_PATH); # default in taint mode is
   # '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
   # $ENV{PATH} otherwise.
 $repl->run;
 # or $repl->run($skip)  to skip $skip levels

=head1 DESCRIPTION

Enters an interactive read-eval-print loop.  Term::ReadLine with
history is active.  The loop can be exited by typing ctl-d.  Entering
nothing re-evaluates the last entry.  Some autocompletion exists.

When the entered line starts with ':' or ',' (both characters are
equivalent), then it is interpreted as containing special commands or
modes. Enter ':h' or ':help' or ':?' (or the equivalents starting with
the comma like ',?', from now on whenever the text days ':' you can
also use the comma) to get a help text including the currently active
settings.

If the 'KeepResultIn' field is set to a string, the scalar with the
given mae is set to either an array holding all the result values (in
:l mode) or the result value (in :1 mode).

By default, in the :d and :s modes the results of a calculation are
carried over to the next entry in $VAR1 etc. as shown by the display
of the result. Those are lexical variables.

This does not turn on the Perl debugger, hence programs are not slowed
down.

=head1 FEATURES

Read the help text that is displayed by entering ":h" or ",h" in the
repl.

=head1 TODO

 - 'A::Class-> ' method completion
 - for '$Foo ->bar<tab>' completion, if $Foo contains a valid class
   name, use it
 - maybe '$ans->[1]->' method completion

=head1 IDEAS

 - should stdout and stderr of the evaluation context go to the pager,
   too?
 - maybe handle ->SUPER:: completion?
 - differ between emptylistofcompletions (no &subs for example) (empty
   list) and no sigil there so dunno-how-to-complete (undef?,
   exception?, ??).

=head1 BUGS

Completion:

 - $ does not filter out scalars only, since perl is not able to do so
 - % and * make completion stop working unless you put a space after
   those sigils. (@ and & work as they should)
 - keep the last 10 or so completion lists, and use those in the ->
   case if the var's type could not be determined.

:V breaks view of :e and similar (shows CODE..)


=head1 SEE ALSO

L<Chj::repl>: easy wrapper

=cut


package Chj::Repl;

use strict;

# Copy from Chj::WithRepl, to prevent circular dependency.  This has
# to be at the top before any lexicals are defined! so that lexicals
# from this module are not active in the eval'ed code.

sub WithRepl_eval (&;$) {
    my ($arg, $maybe_package)=@_;
    if (ref $arg) {
	eval { &$arg() }
    } else {
	my $package= $maybe_package // caller;
	eval "package $package; $arg"
    }
}

use Chj::Class::methodnames;
use Chj::xoutpipe();
use Chj::xtmpfile;
use Chj::xperlfunc qw(xexec);
use Chj::xopen qw(fh_to_fh perhaps_xopen_read);
use POSIX;
use Chj::xhome qw(xeffectiveuserhome);
use Chj::singlequote 'singlequote';
use FP::HashSet qw(hashset_union);
use FP::Hash qw(hash_xref);

sub xone_nonwhitespace {
    my ($str)=@_;
    $str=~ /^\s*(\S+)\s*\z/s
	or die "exactly one non-quoted argument must be given";
    $1
}


sub levels_to_user {
    my $n=1;
    while(1) {
	my ($package, $filename, $line, $subroutine, $hasargs,
	    $wantarray, $evaltext, $is_require, $hints, $bitmask, $hinthash)=
		caller($n);
	return $n
	    if ($package ne 'Chj::Repl'
		and
		$package ne 'Chj::repl');

	$n++;
    }
}


use Class::Array -fields=>
  -publica=> (
	      'Historypath', # undef=none, but a default is set
	      'Settingspath', # undef=none, but a default is set
	      'MaxHistLen',
	      'Prompt', # undef= build fresh one from package&level
	      'Package', # undef= use caller's package
	      'DoCatchINT',
	      'DoRepeatWhenEmpty',
	      'KeepResultIn',
	      'DoKeepResultsInVARX',
	      'Pager',
              'Mode_context', # char
              'Mode_formatter', # char
              'Mode_viewer', # char
	      'Maybe_input', # fh
	      'Maybe_output', # fh
	      'Env_PATH', # maybe string
	     );

sub new {
    my $class=shift;
    my $self= $class->SUPER::new;
    # XX is xeffectiveuserhome always ok over $ENV{HOME} ?
    $$self[Historypath]= xeffectiveuserhome."/.perl-repl_history";
    $$self[Settingspath]= xeffectiveuserhome."/.perl-repl_settings";
    $$self[MaxHistLen]= 100;
    $$self[DoCatchINT]=1;
    $$self[DoRepeatWhenEmpty]=1;
    $$self[DoKeepResultsInVARX]= 1;
    $$self[Pager]= $ENV{PAGER} || "less";
    $$self[Mode_context]= 'l';
    $$self[Mode_formatter]= 'd';
    $$self[Mode_viewer]= 'a';
    $$self[Env_PATH]=
      '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
	if ${^TAINT};
    $self
}

my $settings_version= "v0";
my $settings_fields=
  [
   # these should remain caller dependent:
   #maxHistLen
   #doCatchINT
   #doRepeatWhenEmpty
   #keepResultIn
   #doKeepResultsInVARX
   #pager
   qw(mode_context
      mode_formatter
      mode_viewer)
   ];

sub possibly_save_settings {
    my $self=shift;
    if (my $path= $self->settingspath) {
	my $f= xtmpfile $path;
	$f->xprint (join("\0",
			 $settings_version,
			 map {
			     $self->$_
			 }
			 @$settings_fields));
	$f->xclose;
	$f->xputback(0600);
    }
}

sub possibly_restore_settings {
    my $self=shift;
    if (my $path= $self->settingspath) {
	if (my ($f)= perhaps_xopen_read ($path)) {
	    my @v= split /\0/, $f->xcontent;
	    $f->xclose;
	    if (shift (@v) eq $settings_version) {
		for (my $i=0; $i< @$settings_fields; $i++) {
		    my $method= "set_".$$settings_fields[$i];
		    $self->$method($v[$i]);
		}
	    } else {
		warn "note: not reading settings of older version from '$path'";
	    }
	}
    }
}

sub saving ($$) {
    my ($self,$proc)=@_;
    sub {
	&$proc(@_);
	$self->possibly_save_settings;
    }
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

use Chj::Repl::corefuncs();
our @builtins= Chj::Repl::corefuncs;

# whether to use Data::Dumper in perl mode
our $Dumper_Useperl= 0;

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
    my $a= &$selection(viewer=> 'a');
    print $out qq{Repl help:
If a command line starts with a ':' or ',', then the remainder of the
line is interpreted as follows:

  package \$package    use \$package as new compilation package
  DIGITS              shorthand for 'f n', see below
  -                   same as 'f n' where n is the current frameno - 1
  +                   same as 'f n' where n is the current frameno + 1
                       (both are the same as 'f' if reaching the end)
  CMD args...         one-time command
  MODES code...       change some modes then evaluate code

CMD is one of:
   e [n]  print lexical environment at level n (default: 0)
   b|bt   print back trace
   f [n]  move to stack frame number n (at start: 0)
           without n, shows the current frame again
   y [n]  alias for f
   q      quit the process (by calling `exit`)

MODES are a combination of these characters, which change the
previously used mode (indicated on the left):
  context:
$L 1  use scalar context
$l l  use list context (default)
  formatter:
$s p  print stringification
$s s  show from FP::Show
$d d  Data::Dumper (default)
  viewer:
$V V  no pager
$v v  pipe to pager ($$self[Pager])
$a a  pipe to 'less --quit-if-one-screen --no-init' (default)

Other features:
  \$Chj::Repl::args  is an array holding the arguments of the last subroutine call
                    that led to the currently selected frame
};
}


sub formatter {
    my $self=shift;
    my ($terse)=@_; # true for :e viewing
    my $mode= $self->mode_formatter;
    $mode= "d" if ($terse and $mode eq "p");
    hash_xref
      (+{
         p=> sub {
             (
	      join "",
	      map {
		  (defined $_ ? $_ : 'undef'). "\n"
	      } @_
             )
         },
         s=> sub {
             require FP::Show;
             my $z=1;
             (
	      join "",
	      map {
		  my $VARX= ($$self[DoKeepResultsInVARX] and not $terse) ?
		    '$VAR'.$z++.' = '
		      : '';
		  $VARX . FP::Show::show($_). "\n"
	      } @_
             )
         },
         d=> sub {
             my @v= @_; # to survive into
	     # WithRepl_eval below

             require Data::Dumper;
             my $res;
             WithRepl_eval {
		 local $Data::Dumper::Sortkeys= 1;
		 local $Data::Dumper::Terse= $terse;
		 local $Data::Dumper::Useperl= $Dumper_Useperl;
		 $res= Data::Dumper::Dumper(@v);
		 1
             } || do {
		 warn "Data::Dumper: $@";
             };
             $res
         }
        },
       $mode);
}

sub viewers {
    my $self=shift;
    my ($OUTPUT,$ERROR)=@_;
    my $port_pager_with_options= sub {
	my ($maybe_pager, @options)=@_;
	sub {
	    my ($printto)=@_;

	    local $SIG{PIPE}="IGNORE";

	    my $pagercmd= $maybe_pager // $self->pager;

	    eval {
		# XX this now means that no options
		# can be passed in $ENV{PAGER} !
		# (stupid Perl btw). Ok hard code
		# 'less' instead perhaps!
		my $o= Chj::xoutpipe
		  (sub {
		       # set stdout and stderr in case they are
		       # redirected (stdin is the pipe)
		       my $out= fh_to_fh ($OUTPUT);
		       $out->xdup2(1);
		       $out->xdup2(2);
		       $ENV{PATH}= $self->env_PATH
			 if defined $self->env_PATH;
		       xexec $pagercmd, @options
		   });
		&$printto ($o);
		$o->xfinish;
		1
	    } || do {
		my $e= $@;
		unless ($e=~ /broken pipe/i) {
		    print $ERROR "error piping to pager ".
		      "$pagercmd: $e\n"
			or die $!;
		}
	    };
	}
    };

    my $string_pager_with_options= sub {
	my $port_pager= &$port_pager_with_options (@_);
	sub {
	    my ($v)=@_;
	    &$port_pager (sub {
			      my ($o)=@_;
			      $o->xprint($v);
			  });
	}
    };

    my $choosepager= sub {
	my ($pager_with_options)= @_;
	hash_xref
	  (+{
	     V=> sub {
		 print $OUTPUT $_[0]
		   or die "print: $!";
	     },
	     v=> &$pager_with_options(),
	     a=> &$pager_with_options
	     (qw(less --quit-if-one-screen --no-init)),
	    },
	   $self->mode_viewer);
    };

    my $pager= sub {
	my ($pager_with_options)= @_;
	sub {
	    my ($v)=@_;
	    &$choosepager ($pager_with_options)->($v);
	}
    };

    (&$pager ($port_pager_with_options),
     &$pager ($string_pager_with_options))
}


sub maybe_get_lexicals {
    my ($frameno)=@_;
    require PadWalker;
    my $levels= levels_to_user;
    eval {
	PadWalker::peek_my($levels + $frameno);
    } // do {
	$@=~ /Not nested deeply enough/i ? undef : die $@;
	# this happens when running the repl when not in a subroutine,
	# right?
    }
}


our $use_warnings= q{use warnings; use warnings FATAL => 'uninitialized';};

sub eval_code {
    my $_self= shift;
    @_==4 or die "wrong number of arguments";
    my ($code, $in_package, $in_frameno, $maybe_kept_results)=@_;

    my $maybe_lexicals= maybe_get_lexicals ($in_frameno);

    # merge with previous results, if any
    my $maybe_kept_results_hash= sub {
	return unless $maybe_kept_results;
	my %r;
	for (my $i=0; $i<@$maybe_kept_results; $i++) {
	    $r{'$VAR'.($i+1)}= \ ($$maybe_kept_results[$i]);
	}
	\%r
    };
    $maybe_lexicals=
      ($maybe_lexicals && $maybe_kept_results) ?
	hashset_union ($maybe_lexicals, &$maybe_kept_results_hash)
	  : ($maybe_lexicals // &$maybe_kept_results_hash);

    my $use_method_signatures=
      $Method::Signatures::VERSION ? "use Method::Signatures" : "";
    my $use_functional_parameters_=
      $Function::Parameters::VERSION ? "use Function::Parameters ':strict'" : "";
    my @v= sort keys %$maybe_lexicals
      if defined $maybe_lexicals;
    my $thunk= &WithRepl_eval
      ((@v ? 'my ('.join(", ", @v).'); ' : '') .
       'sub {'.
       "no strict 'vars'; $use_warnings; ".
       "$use_method_signatures; $use_functional_parameters_; ".
       $code.
       '}',
       &$in_package())
	// return;
    PadWalker::set_closed_over ($thunk, $maybe_lexicals)
	if defined $maybe_lexicals;
    WithRepl_eval { &$thunk() }
}


sub _completion_function {
    my ($attribs, $package, $lexicals)=@_;
    sub {
	my ($text, $line, $start, $end) = @_;
	my $part= substr($line,0,$end);

	#reset to the default before deciding upon it:
	$attribs->{completion_append_character}=" ";

	my @matches= do {
	    # arrow completion:
	    my ($pre,$varnam,$brace,$alreadywritten);
	    if (($pre,$varnam,$brace,$alreadywritten)=
		$part=~ /(.*)\$(\w+)\s*->\s*([{\[]\s*)?(\w*)\z/s
		or
		($pre,$varnam,$brace,$alreadywritten)=
		$part=~ /(.*\$)\$(\w+)\s+([{\[]\s*)?(\w*)\z/s) {
		# need to know the class of that thing
		no strict 'refs';
		my $r;
		if (my $val=
		    (
		     # try to get the value, or at least the package.

		     do {
			 if (my $ref= $$lexicals{'$'.$varnam}) {
			     $$ref
			 } else {
			     undef
			 }
		     }

		     or $ { $package."::".$varnam }

		     or do {
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
		
		my $globentry=
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
		#print $ERROR "<$globentry>";

		my $symbols_for_package= sub {
		    my ($package)=@_;
		    grep {
			# only show 'usable' ones.
			/^\w+(?:::)?\z/
		    } do {
			if ($globentry) {
			    #print $ERROR ".$globentry.";
			    grep {
				(/::\z/
				 # either it's a namespace which we
				 # want to see regardless of type, or:
				 # type exists
				 or
				 *{ $package."::".$_ }{$globentry})
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
		   ($symbols_for_package->($package),
		    ($globentry ? () : @builtins),
		    # and lexicals:
		    map { /^\Q$sigil\E(.*)/s ? $1 : () } sort keys %$lexicals
		   ));

		#print Data::Dumper::Dumper(\@a);

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
	    #print $ERROR "<".join(",",@matches).">";

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
    }
}

use Chj::Repl::Stack;

our $repl_level; # maybe number of repl layers above
our $args; # see '$Chj::Repl::args' in help text

# TODO: split this monstrosity into pieces.
sub run {
    my $self=shift;
    my ($maybe_skip)=@_;

    my $skip= $maybe_skip // 0;
    my $stack= Chj::Repl::Stack->get ($skip + 1);

    local $repl_level= ($repl_level // -1) + 1;

    my $frameno= 0;

    my $get_package= sub {
	# (What is $$self[Package] for? Can set the prompt
	# independently. Security feature or just overengineering?
	# Ok, remember the ":p" setting; but why not use a lexical
	# within `run`? Ok how long-lived are the repl objects, same
	# duration? Then hm is the only reason for the object to be
	# able to set up things explicitely first? Thus is it ok after
	# all?)
	my $r= $$self[Package] || $stack->package($frameno);
	$r
    };

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

    my ($INPUT, $OUTPUT, $ERROR)= do {
	my ($maybe_in, $maybe_out)=
	  ($self->maybe_input,$self->maybe_output);
	my $in= $maybe_in // $term->IN // *STDIN;
	my $out= $maybe_out // $term->OUT // *STDOUT;
	$term->newTTY ($in,$out);
	($in,$out,$out)
    };

    my $printerror_frameno= sub {
	my $max = $stack->max_frameno;
	print $ERROR
	  "frame number must be between 0..$max\n";
    };

    my ($view_with_port, $view_string)= $self->viewers ($OUTPUT,$ERROR);

    {
	my @history;
	local $current_history= \@history;
	# ^ this is what nested repl's will use to restore the history
	# in the $term object
	if (defined $$self[Historypath]) {
	    # clean history of C based object before we re-add the
	    # saved one:
	    $term->clear_history;
	    if (open my $hist, "<", $$self[Historypath]){
		@history= <$hist>;
		close $hist;
		for (@history){
		    chomp;
		    $term->addhistory($_);
		}
	    }
	}
	# do not add input to history automatically (which allows me
	# to do it myself):
	$term->MinLine(undef);

	my $myreadline= sub {
	  DO: {
	      my $line;
	      eval {
		  $line=
		      $term->readline
		      ($$self[Prompt] //
		       &$get_package()
		       .($repl_level ? " $repl_level":"")
		       .($frameno ? "/$frameno" : "")
		       ."> ");
		  1
	      } || do {
		  if (!length ref($@) and $@=~ /^SIGINT\n/s) {
		      print $OUTPUT "\n";
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
	my $maybe_kept_results;
      READ: {
	    while (1) {

		local $attribs->{attempted_completion_function}=
		  _completion_function ($attribs,
					&$get_package,
					maybe_get_lexicals($skip + $frameno)||{});

		my $input = &$myreadline // last;

		if (length $input) {
		    my ($cmd,$rest)=
		      $input=~ /^ *[:,] *([?+-]|[a-zA-Z]+|\d+)(.*)/s ?
			($1,$2)
			  :(undef,$input);

		    if (defined $cmd) {

			if ($cmd=~ /^\d+\z/) {
			    # hacky way to allow ":5" etc. as ":f 5"
			    $rest= "$cmd $rest";
			    $cmd= "f";
			}

			# handle commands
			eval {

			    my $set_package= sub {
				# (no package parsing, trust user)
				$$self[Package]= xone_nonwhitespace($rest);
				$rest=""; # XX HACK
			    };

			    my $help= sub { $self->print_help ($OUTPUT) };

			    my $bt= sub {
				my ($maybe_frameno)=
				  $rest=~ /^\s*(\d+)?\s*\z/
				    or die "expecting digits or no argument, got '$cmd'";
				print $OUTPUT $stack->backtrace ($maybe_frameno
								 // $frameno);
				$rest=""; # XX HACK; also, really
                                          # silently drop stuff?
			    };

			    my $chooseframe= sub {
				my ($maybe_frameno)= @_;
				$rest= ""; # still the hack, right?
				if (defined $maybe_frameno) {
				    if ($maybe_frameno <= $stack->max_frameno) {
					$frameno= $maybe_frameno
				    } else {
					&$printerror_frameno ();
					return;
				    }
				}
				
				# unset any explicit package as
				# we want to use the one of the
				# current frame
				undef $$self[Package]; # even without frameno? mess

				# Show the context: (XX same
				# issue as with :e with overly
				# long data (need viewer, but
				# don't really want to, so should
				# really use shortener)
				print $OUTPUT $stack->desc($frameno),"\n";
			    };

			    my $select_frame= sub {
				my ($maybe_frameno)=
				  $rest=~ /^\s*(\d+)?\s*\z/
				    or die "expecting frame number, ".
				      "an integer, or nothing, got '$cmd'";
				&$chooseframe ($maybe_frameno)
			    };

			    my %commands=
				(
				 h=> $help,
				 help=> $help,
				 '?'=> $help,
				 '-'=> sub {
				     &$chooseframe (($frameno > 0) ?
						    $frameno - 1 : undef)
				 },
				 '+'=> sub {
				     &$chooseframe (($frameno < $stack->max_frameno) ?
						    $frameno + 1 : undef)
				 },
				 package=> $set_package,
				 1=> saving ($self, sub { $$self[Mode_context]="1" }),
				 l=> saving ($self, sub { $$self[Mode_context]="l" }),
				 p=> saving ($self, sub { $$self[Mode_formatter]="p" }),
				 s=> saving ($self, sub { $$self[Mode_formatter]="s" }),
				 d=> saving ($self, sub { $$self[Mode_formatter]="d" }),
				 V=> saving ($self, sub { $$self[Mode_viewer]="V" }),
				 v=> saving ($self, sub { $$self[Mode_viewer]="v" }),
				 a=> saving ($self, sub { $$self[Mode_viewer]="a" }),
				 e=> sub {
				     use Data::Dumper;
				     # XX clean up: don't want i in the regex
				     my ($maybe_frameno)=
					 $rest=~ /^i?\s*(\d+)?\s*\z/
					 or die "expecting digits or no argument, got '$cmd'";
				     $rest=""; # can't s/// above when expecting value
				     if (defined
					 (my $lexicals= maybe_get_lexicals
					  ($skip - 1 + ($maybe_frameno // $frameno)))) {
					 &$view_with_port
					   (sub {
						my ($o)=@_;
						my $format= $self->formatter(1);
						for my $key (sort keys %$lexicals) {
						    if ($key=~ /^\$/) {
							$o->xprint
							  ("$key = ".
							   &$format(${$$lexicals{$key}}));
						    } else {
							$o->xprint
							  ("\\$key = ".
							   &$format($$lexicals{$key}));
						    }
						}
					    });
				     } else {
					 &$printerror_frameno ();
				     }
				 },
				 f=> $select_frame,
				 y=> $select_frame,
				 q=> sub {
				     # XX change exit code depending
				     # on how the repl was called?
				     # Well, at least make it a config
				     # field?
				     exit 0
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
					print $ERROR "unknown command "
					  ."or mode: '$subcmd'\n";
					last;
				    }
				}
			    }

			    1
			} || do {
			    print $ERROR "$@";
			    redo READ;
			}
		    }

		    # build up evaluator
		    my $real_frameno= sub { $skip + $frameno };
		    my $eval=
			hash_xref
			(+{
			   1=> sub {
			       my $vals=
				 [ scalar $self->eval_code
				   ($rest, $get_package, &$real_frameno(),
				    $maybe_kept_results) ];
			       ($vals, $@)
			   },
			   l=> sub {
			       my $vals=
				 [ $self->eval_code
				   ($rest, $get_package, &$real_frameno(),
				    $maybe_kept_results) ];
			       ($vals, $@)
			   },
			  },
			 $self->mode_context);

		    my $format_vals= $self->formatter;

		    $evaluator= sub {
			my ($results,$error)= do {
			    # make it possible for the code entered in
			    # the repl to access the arguments in the
			    # last call leading to this position by
			    # accessing $Chj::Repl::args :
			    my $maybe_frame= $stack->frame (&$real_frameno());
			    local $args = $maybe_frame ? $maybe_frame->args : "TOP";
			    &$eval
			};

			&$view_string(do {
			    if (ref $error or $error) {
				# XX todo: only do can in the case of
				# ref; but, remove this code anyway,
				# use FP::Show now?
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
			$maybe_kept_results= $results
			  if $$self[DoKeepResultsInVARX];
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
	print $OUTPUT "\n";
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
