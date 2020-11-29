#
# Copyright (c) 2004-2020 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FP::Repl::Repl - read-eval-print loop

=head1 SYNOPSIS

 my $repl = new FP::Repl::Repl;
 $repl->set_prompt("foo> ");
 # ^ if left undefined, "$package$perhapslevel> " is used
 $repl->set_historypath("somefile"); # default is ~/.fp-repl_history
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

If the 'Maybe_keepResultIn' field is set to a string, the scalar with the
given mae is set to either an array holding all the result values (in
:l mode) or the result value (in :1 mode).

By default, in the :d and :s modes the results of a calculation are
carried over to the next entry in $VAR1 etc. as shown by the display
of the result. Those are lexical variables.

This does not turn on the Perl debugger, hence programs are not slowed
down.

=head1 FEATURES

Read the help text that is displayed by entering ":h", ",h", ":?" or
",?" in the repl.

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
 - make package lexicals accessible when entering a package with :p

=head1 BUGS

Completion:

 - $ does not filter out scalars only, since perl is not able to do so
 - % and * make completion stop working unless you put a space after
   those sigils. (@ and & work as they should)
 - keep the last 10 or so completion lists, and use those in the ->
   case if the var's type could not be determined.

:V breaks view of :e and similar (shows CODE..)


=head1 SEE ALSO

L<FP::Repl>: easy wrapper

=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut

package FP::Repl::Repl;

use strict;
use warnings;
use warnings FATAL => 'uninitialized';

# Copy from FP::Repl::WithRepl, to prevent circular dependency.  This has
# to be at the top before any lexicals are defined! so that lexicals
# from this module are not active in the eval'ed code.

sub WithRepl_eval (&;$) {
    my ($arg, $maybe_package) = @_;
    if (ref $arg) {
        eval { &$arg() }
    } else {
        my $package = $maybe_package // caller;
        eval "package $package; $arg"
    }
}

use Chj::Class::methodnames;
use Chj::xoutpipe();
use Chj::xtmpfile;
use Chj::xperlfunc qw(xexec);
use Chj::xopen qw(fh_to_fh perhaps_xopen_read);
use POSIX;
use Chj::xhome qw(xhome);
use Chj::singlequote 'singlequote';
use FP::HashSet qw(hashset_union);
use FP::Hash qw(hash_xref);
use FP::Repl::StackPlus;
use FP::Lazy;
use FP::Show;
use Scalar::Util qw(blessed);
use FP::Carp;

sub maybe_tty {
    my $path = "/dev/tty";
    if (open my $fh, "+>", $path) {
        $fh
    } else {
        warn "opening '$path': $!";
        undef
    }
}

sub xone_nonwhitespace {
    my ($str) = @_;
    $str =~ /^\s*(\S+)\s*\z/s
        or die "exactly one non-quoted argument must be given";
    $1
}

my $HOME = xhome;
our $maybe_historypath        = "$HOME/.fp-repl_history";
our $maybe_settingspath       = "$HOME/.fp-repl_settings";
our $maxHistLen               = 100;
our $doCatchINT               = 1;
our $doRepeatWhenEmpty        = 1;
our $doKeepResultsInVARX      = 1;
our $pager                    = $ENV{PAGER} || "less";
our $mode_context             = 'l';
our $mode_formatter           = 'd';
our $mode_viewer              = 'a';
our $mode_lexical_persistence = 'X';
our $maybe_env_path
    = '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin';

use Chj::Class::Array -fields => -publica => (
    'Maybe_historypath',     # undef=none, but a default is set
    'Maybe_settingspath',    # undef=none, but a default is set
    'MaxHistLen', 'Maybe_prompt',    # undef= build fresh one from package&level
    'Maybe_package',                 # undef= use caller's package
    'DoCatchINT',          'DoRepeatWhenEmpty', 'Maybe_keepResultIn',
    'DoKeepResultsInVARX', 'Pager',             'Mode_context',         # char
    'Mode_formatter',              # char
    'Mode_viewer',                 # char
    'Mode_lexical_persistence',    # char
    'Maybe_input',                 # fh
    'Maybe_output',                # fh
    'Maybe_env_PATH',              # maybe string
);

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new;
    $$self[Maybe_historypath]        = $maybe_historypath;
    $$self[Maybe_settingspath]       = $maybe_settingspath;
    $$self[MaxHistLen]               = $maxHistLen;
    $$self[DoCatchINT]               = $doCatchINT;
    $$self[DoRepeatWhenEmpty]        = $doRepeatWhenEmpty;
    $$self[DoKeepResultsInVARX]      = $doKeepResultsInVARX;
    $$self[Pager]                    = $pager;
    $$self[Mode_context]             = $mode_context;
    $$self[Mode_formatter]           = $mode_formatter;
    $$self[Mode_viewer]              = $mode_viewer;
    $$self[Mode_lexical_persistence] = $mode_lexical_persistence;
    $$self[Maybe_env_PATH]           = $maybe_env_path if ${^TAINT};
    $self
}

my $maybe_setter = sub {
    my ($method) = @_;
    sub {
        @_ == 2 or fp_croak_nargs 2;
        my ($self, $v) = @_;
        my $set_maybe_method = "set_maybe_${method}";
        defined $v
            or die
            "set_${method} does not accept undef, use $set_maybe_method instead";
        $self->$set_maybe_method($v);
    }
};
for my $method (
    qw(historypath settingspath prompt package keepResultIn
    input output env_PATH)
    )
{
    no strict 'refs';
    my $var = "set_$method";
    *$var = &$maybe_setter($method);
}

sub use_lexical_persistence {
    my $self = shift;
    hash_xref(+{ m => 1, M => 1, x => 0, X => 0 },
        $self->mode_lexical_persistence)
}

sub use_strict_vars {
    my $self = shift;
    hash_xref(+{ m => 1, M => 0, x => 1, X => 0 },
        $self->mode_lexical_persistence)
}

my $settings_version = "v2";
my $settings_fields  = [

    # these should remain caller dependent:
    #maxHistLen
    #doCatchINT
    #doRepeatWhenEmpty
    #maybe_keepResultIn
    #doKeepResultsInVARX
    #pager
    qw(mode_context
        mode_formatter
        mode_viewer
        mode_lexical_persistence)
];

sub possibly_save_settings {
    my $self = shift;
    if (my $path = $self->maybe_settingspath) {
        my $f = xtmpfile $path;
        $f->xprint(
            join("\0", $settings_version, map { $self->$_ } @$settings_fields));
        $f->xclose;
        $f->xputback(0600);
    }
}

sub possibly_restore_settings {
    my $self = shift;
    if (my $path = $self->maybe_settingspath) {
        if (my ($f) = perhaps_xopen_read($path)) {
            my @v = split /\0/, $f->xcontent;
            $f->xclose;
            if (shift(@v) eq $settings_version) {
                for (my $i = 0; $i < @$settings_fields; $i++) {
                    my $method = "set_" . $$settings_fields[$i];
                    $self->$method($v[$i]);
                }
            } else {
                warn "note: not reading settings of other version from '$path'";
            }
        }
    }
}

sub saving {
    @_ == 2 or fp_croak_nargs 2;
    my ($self, $proc) = @_;
    sub {
        &$proc(@_);
        $self->possibly_save_settings;
    }
}

# (move to some lib?)
sub splitpackage {
    my ($package) = @_;    # may be partial.
    if ($package =~ /(.*)::(.*)/s) { ($1, $2) }
    else                           { ("", $package) }
}

my $PACKAGE = qr/\w+(?:::\w+)*/;

use FP::Repl::corefuncs();
our @builtins = FP::Repl::corefuncs;

# whether to use Data::Dumper in perl mode
our $Dumper_Useperl = 0;

sub __signalhandler { die "SIGINT\n" }

our $term;    # local'ized but old value is reused if present.

our $current_history;    # local'ized; array(s).

sub print_help {
    my $self      = shift;
    my ($out)     = @_;
    my $selection = sub {
        my ($meth, $val) = @_;
        my $method = "mode_$meth";
        $self->$method eq $val ? "->" : "  "
    };
    my $L = &$selection(context             => '1');
    my $l = &$selection(context             => 'l');
    my $p = &$selection(formatter           => 'p');
    my $s = &$selection(formatter           => 's');
    my $d = &$selection(formatter           => 'd');
    my $V = &$selection(viewer              => 'V');
    my $v = &$selection(viewer              => 'v');
    my $a = &$selection(viewer              => 'a');
    my $m = &$selection(lexical_persistence => 'm');
    my $M = &$selection(lexical_persistence => 'M');
    my $x = &$selection(lexical_persistence => 'x');
    my $X = &$selection(lexical_persistence => 'X');
    print $out qq{Repl help:
If a command line starts with a ':' or ',', then the remainder of the
line is interpreted as follows:

  package \$package    use \$package as new compilation package
  p \$package          shortcut for package
  DIGITS              shorthand for 'f n', see below
  -                   same as 'f n' where n is the current frameno - 1
  +                   same as 'f n' where n is the current frameno + 1
                       (both are the same as 'f' if reaching the end)
  CMD args...         one-time command
  MODES code...       change some modes then evaluate code

CMD is one of:
   e [n]  print lexical environment at level n (default: 0)
           Note: currently this does *not* show the lexicals that were
           persisted when enabling m or M mode.
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
$p P  print stringification
$s s  show from FP::Show (experimental, does not show data sharing)
$d d  Data::Dumper (default)
  viewer:
$V V  no pager
$v v  pipe to pager ($$self[Pager])
$a a  pipe to 'less --quit-if-one-screen --no-init' (default)
  lexical persistence:
   (Persisting lexicals means to carry over variables introduced with
   "my" into subsequent entries in the same repl. It prevents their
   values from being deallocated until new values are assigned or a
   new lexical with the same name is introduced. Currently these
   lexicals are carried over even when moving to another frame or
   package.)
$m m  persist lexicals, use strict 'vars'
$M M  persist lexicals, no strict 'vars'
$x x  do not persist lexicals, use strict 'vars'
$X X  do not persist lexicals, no strict 'vars' (default)

Other features:
  \$FP::Repl::Repl::args   is an array holding the arguments of the last subroutine call
                     that led to the currently selected frame
  \$FP::Repl::Repl::argsn  is an array holding the arguments of the subroutine call
                     that *leaves* the currently selected frame
};
}

sub formatter {
    my $self    = shift;
    my ($terse) = @_;                      # true for :e viewing
    my $mode    = $self->mode_formatter;
    $mode = "d" if ($terse and $mode eq "p");
    hash_xref(
        +{
            p => sub {
                (join "", map { (defined $_ ? $_ : 'undef') . "\n" } @_)
            },
            s => sub {
                my $z = 1;
                (
                    join "",
                    map {
                        my $VARX
                            = ($$self[DoKeepResultsInVARX] and not $terse)
                            ? '$VAR' . $z++ . ' = '
                            : '';
                        $VARX . show($_) . ";\n"
                    } @_
                )
            },
            d => sub {
                my @v = @_;    # to survive into
                               # WithRepl_eval below

                require Data::Dumper;
                my $res;
                WithRepl_eval {
                    local $Data::Dumper::Sortkeys = 1;
                    local $Data::Dumper::Terse    = $terse;
                    local $Data::Dumper::Useperl  = $Dumper_Useperl;
                    $res = Data::Dumper::Dumper(@v);
                    1
                }
                    || do {
                    warn "Data::Dumper: " . show($@);
                    };
                $res
            }
        },
        $mode
    );
}

sub viewers {
    my $self = shift;
    my ($OUTPUT, $ERROR) = @_;
    my $port_pager_with_options = sub {
        my ($maybe_pager, @options) = @_;
        sub {
            my ($printto) = @_;

            local $SIG{PIPE} = "IGNORE";

            my $pagercmd = $maybe_pager // $self->pager;

            eval {
                # XX this now means that no options
                # can be passed in $ENV{PAGER} !
                # (stupid Perl btw). Ok hard code
                # 'less' instead perhaps!
                my $o = Chj::xoutpipe(
                    sub {

                        # set stdout and stderr in case they are
                        # redirected (stdin is the pipe)
                        my $out = fh_to_fh($OUTPUT);
                        $out->xdup2(1);
                        $out->xdup2(2);
                        $ENV{PATH} = $self->maybe_env_PATH
                            if defined $self->maybe_env_PATH;
                        xexec $pagercmd, @options
                    }
                );
                &$printto($o);
                $o->xfinish;
                1
            } || do {
                my $estr = show($@);
                unless ($estr =~ /broken pipe/i) {
                    print $ERROR "error piping to pager "
                        . "$pagercmd: $estr\n"
                        or die $!;
                }
            };
        }
    };

    my $string_pager_with_options = sub {
        my $port_pager = &$port_pager_with_options(@_);
        sub {
            my ($v) = @_;
            &$port_pager(
                sub {
                    my ($o) = @_;
                    $o->xprint($v);
                }
            );
        }
    };

    my $choosepager = sub {
        my ($pager_with_options) = @_;
        hash_xref(
            +{
                V => sub {
                    print $OUTPUT $_[0] or die "print: $!";
                },
                v => &$pager_with_options(),
                a => &$pager_with_options(
                    qw(less --quit-if-one-screen --no-init)),
            },
            $self->mode_viewer
        );
    };

    my $pager = sub {
        my ($pager_with_options) = @_;
        sub {
            my ($v) = @_;
            &$choosepager($pager_with_options)->($v);
        }
    };

    (&$pager($port_pager_with_options), &$pager($string_pager_with_options))
}

our $use_warnings = q{use warnings; use warnings FATAL => 'uninitialized';};

sub eval_code {
    my $self = shift;
    @_ == 5 or fp_croak_nargs 5;
    my ($code, $in_package, $maybe_lexicals, $maybe_kept_results,
        $maybe_lexical_persistence)
        = @_;

    # merge with previous results, if any
    my $maybe_kept_results_hash = sub {
        return unless $maybe_kept_results;
        my %r;
        for (my $i = 0; $i < @$maybe_kept_results; $i++) {
            $r{ '$VAR' . ($i + 1) } = \($$maybe_kept_results[$i]);
        }
        \%r
    };
    $maybe_lexicals
        = ($maybe_lexicals && $maybe_kept_results)
        ? hashset_union($maybe_lexicals, &$maybe_kept_results_hash)
        : ($maybe_lexicals // &$maybe_kept_results_hash);

    my $use_method_signatures
        = $Method::Signatures::VERSION ? "use Method::Signatures" : "";
    my $use_functional_parameters_
        = $Function::Parameters::VERSION
        ? "use Function::Parameters ':strict'"
        : "";
    my $use_signatures = ($] >= 5.020) ? "use experimental 'signatures'" : "";
    my $use_tail    = $Sub::Call::Tail::VERSION ? "use Sub::Call::Tail" : "";
    my $use_autobox = @FP::autobox::ISA         ? "use FP::autobox"     : "";

    my $prelude
        = "package "
        . &$in_package() . ";"
        . "use strict; "
        . ($self->use_strict_vars ? "" : "no strict 'vars'; ")
        . "$use_warnings; "
        . "$use_method_signatures; $use_functional_parameters_; "
        . "$use_signatures; $use_tail; $use_autobox; ";

    if (my $lp = $maybe_lexical_persistence) {
        my $allcode = $prelude . $code;
        if (defined $maybe_lexicals) {
            $lp->lexicals(hashset_union($lp->lexicals, $maybe_lexicals))
        }
        my $context = wantarray ? "list" : "scalar";
        $lp->context($context);
        WithRepl_eval { $lp->eval($allcode) }
    } else {
        my @v = sort keys %$maybe_lexicals if defined $maybe_lexicals;
        my $allcode
            = $prelude
            . (@v ? 'my (' . join(", ", @v) . '); ' : '') . 'sub {'
            . $code . "\n" . '}';
        my $thunk = &WithRepl_eval($allcode) // return;
        PadWalker::set_closed_over($thunk, $maybe_lexicals)
            if defined $maybe_lexicals;
        WithRepl_eval { &$thunk() }
    }
}

sub _completion_function {
    my ($attribs, $package, $lexicals) = @_;
    sub {
        my ($text, $line, $start, $end) = @_;
        my $part = substr($line, 0, $end);

        #reset to the default before deciding upon it:
        $attribs->{completion_append_character} = " ";

        my @matches = do {

            # arrow completion:
            my ($pre, $varnam, $brace, $alreadywritten);
            if (($pre, $varnam, $brace, $alreadywritten)
                = $part =~ /(.*)\$(\w+)\s*->\s*([{\[]\s*)?(\w*)\z/s
                or ($pre, $varnam, $brace, $alreadywritten)
                = $part =~ /(.*\$)\$(\w+)(?:\s+|(?:\s*([{\[]\s*)(\w*)))\z/s)
            {
                # need to know the class of that thing
                no strict 'refs';
                my $r;

                # try to get the value, or at least the package.
                my $val = do {
                    if (my $ref = $$lexicals{ '$' . $varnam }) {
                        $$ref
                    } else {
                        my $v = ${ $package . "::" . $varnam };
                        if (defined $v) {
                            $v
                        } else {

                            # (if I could run code side-effect free... or
                            # compile-only and disassemble....)  Try to
                            # parse the perl myself
                            if (
                                $part =~ /.* # force latest possible match (ok?)
                                (?:^|;)\s*
                                (?:(?:my|our)\s+)?
                                # ^ optional for no 'use strict'
                                \$$varnam
                                \s* = \s*
                                (?:new\w*\s+($PACKAGE)
                                |($PACKAGE)\s*->\s*new)
                                /sx
                                )
                            {
                                $r = $1;
                                1
                            } else {
                                0
                            }
                        }
                    }
                };

                # Force any potential promises, since we want to
                # complete methods on the resulting value, OK? TODO
                # once typing framework is ready (FP::Type): mark type
                # in promise, thus no need to force it.  Have to catch
                # (and ignore, OK?) exceptions.
                eval { $val = force $val; };

                if (defined $val) {

                    #warn "got value from \$$varnam";
                    if ($r ||= ref($val)) {
                        if ($r eq 'HASH'
                            or ($brace and UNIVERSAL::isa($val, 'HASH')))
                        {
                            # Could also check `$val->isa('HASH')` if
                            # we wanted to run isa overloads, but
                            # would we want to do that?

                            #("{")
                            #("{foo}","{bar}")
                            if ($brace) {
                                map {"$_}"} keys %$val
                            } else {
                                map {"{$_}"} keys %$val
                            }
                        } elsif ($r eq 'ARRAY'
                            or ($brace and UNIVERSAL::isa($val, 'ARRAY')))
                        {
                            # ^ not sure this works here; see commit messages
                            ("[")
                        } elsif ($r eq 'CODE') {
                            ("(")
                        } elsif ($r eq 'SCALAR') {
                            ("SCALAR")    ##
                        } elsif ($r eq 'IO') {
                            ("IO")        ##
                        } elsif ($r eq 'GLOB') {
                            ("GLOB")      ##
                        } else {

                            # object
                            my @a = methodnames($r);
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

                    #warn "no value from \$$varnam";
                    ()
                }
            } elsif ($part =~ tr/"/"/ % 2) {

                # odd number of quotes means we are inside
                ()
            } elsif ($part =~ tr/'/'/ % 2) {

                # odd number of quotes means we are inside
                ()
            } elsif (
                $part =~ /(^|.)\s*(${PACKAGE}(?:::)?)\z/s
                or $part =~ /([\$\@\%\*\&])
                              \s*
                              (${PACKAGE}(?:::)?|)
                              # ^ accept the empty string
                              \z/sx
                )
            {
                # namespace completion
                my ($sigil, $partialpackage) = ($1, $2);

                no strict 'refs';

                my ($upperpackage, $localpart) = splitpackage($partialpackage);

                #warn "upperpackage='$upperpackage', localpart='$localpart'\n";

                # if upperpackage is empty, it might also be a
                # non-fully qualified, i.e. local, partial identifier.

                my $globentry = (
                    $sigil and +{
                        '$' => 'SCALAR',
                        '@' => 'ARRAY',
                        '%' => 'HASH',

                        # ^ (problem with readline library, with a space
                        # after % it works too; need better completion
                        # function than the one from gnu readline?)
                        # (years later: what was this?)
                        '*' => 'SCALAR',

                        # ^ really 'GLOB', but that would make it
                        # invisible. SCALAR matches everything, which is
                        # what we want.
                        '&' => 'CODE'
                    }->{$sigil}
                );

                #print $ERROR "<$globentry>";

                my $symbols_for_package = sub {
                    my ($package) = @_;
                    grep {
                        # only show 'usable' ones.
                        /^\w+(?:::)?\z/
                    } do {
                        if ($globentry) {

                            #print $ERROR ".$globentry.";
                            grep {
                                (
                                    /::\z/

                                        # either it's a namespace which we
                                        # want to see regardless of type, or:
                                        # type exists
                                        or *{ $package . "::" . $_ }{$globentry}
                                )
                            } keys %{ $package . "::" }
                        } else {
                            keys %{ $package . "::" }
                        }
                    }
                };
                my @a = (
                    $symbols_for_package->($upperpackage),

                    length($upperpackage) ? () : (
                        $symbols_for_package->($package),
                        ($globentry ? () : @builtins),

                        # and lexicals:
                        map { /^\Q$sigil\E(.*)/s ? $1 : () }
                            sort keys %$lexicals
                    )
                );

                #print Data::Dumper::Dumper(\@a);

                # Now, if it ends in ::, or even generally, care about
                # it not appending space on completion:
                $attribs->{completion_append_character} = "";

                (
                    map {
                        if (/::\z/) {
                            $_
                        } else {
                            "$_ "
                        }
                    } (
                        length($upperpackage)
                        ? map { $upperpackage . "::$_" } @a
                        : @a
                    )
                )
            } else {
                ()
            }
        };
        if (@matches) {

            #print $ERROR "<".join(",",@matches).">";

            $attribs->{completion_word} = \@matches;

            # (no sorting necessary)

            return $term->completion_matches($text,
                $attribs->{list_completion_function})
        } else {

            # restore defaults.
            $attribs->{completion_append_character} = " ";
            return ()
        }
    }
}

our $clear_history = do {
    my $did = 0;
    sub {
        my ($term) = @_;

        # Term::ReadLine::Perl does not have clear_history, so, wrap
        # it. ->can doesn't work either (lazy loading?), so:
        eval {
            $term->clear_history;
            1
        } || do {
            warn $@ . "install Term::ReadLine::Gnu if you can" unless $did++;
        }
    }
};

our ($maybe_input, $maybe_output);    # dynamic parametrization of
                                      # filehandles

our $repl_level;    # maybe number of repl layers above
our $args;          # see '$FP::Repl::Repl::args' in help text
our $argsn;         # see '$FP::Repl::Repl::argsn' in help text

# TODO: split this monstrosity into pieces.
sub run {
    my ($self, $maybe_skip) = @_;

    my $skip  = $maybe_skip // 0;
    my $stack = FP::Repl::StackPlus->get($skip + 1);

    local $repl_level = ($repl_level // -1) + 1;

    my $frameno = 0;

    my $get_package = sub {

        # (What is $$self[Maybe_package] for? Can set the maybe_prompt
        # independently. Security feature or just overengineering?
        # Ok, remember the ":p" setting; but why not use a lexical
        # within `run`? Ok how long-lived are the repl objects, same
        # duration? Then hm is the only reason for the object to be
        # able to set up things explicitely first? Thus is it ok after
        # all?)
        my $r = $$self[Maybe_package] || $stack->package($frameno);
        $r
    };

    my $oldsigint = $SIG{INT};
    eval {
        local $SIG{__DIE__};

        # It seems this is the only way to make signal handlers work in
        # both perl 5.6 and 5.8:
        sigaction SIGINT, new POSIX::SigAction __PACKAGE__ . '::__signalhandler'
            or die "Error setting SIGINT handler: $!\n";
        1
    } || do {
        if ($^O eq 'MSWin32') {

            # XX will that work?
            $SIG{INT} = \&__signalhandler;
        } else {
            warn "could not set up signal handler: $@ ";
        }
    };

    {
        local $SIG{__DIE__};
        require Term::ReadLine;
    }

    # only start one readline instance, do not nest (doing otherwise
    # seems to lead to segfaults). okay?.
    local our $term = $term || new Term::ReadLine 'Repl';

    # This means that the history from nested repls will also show up
    # in the history of the parent repl. Not saved, but within the
    # readline instance. (Correct?)
    # XX: idea: add nesting level to history filename?

    my $attribs = $term->Attribs;

    my ($INPUT, $OUTPUT, $ERROR) = do {
        my $tty = lazy {maybe_tty};
        my $in  = $self->maybe_input // $maybe_input // force($tty) // $term->IN
            // *STDIN;
        my $out = $self->maybe_output // $maybe_output // force($tty)
            // $term->OUT // *STDOUT;
        $term->newTTY($in, $out);
        ($in, $out, $out)
    };

    # carry over input/output to subshells:
    local $maybe_input  = $INPUT;
    local $maybe_output = $OUTPUT;

    my $printerror_frameno = sub {
        my $max = $stack->max_frameno;
        print $ERROR "frame number must be between 0..$max",
            (@_ ? ", got @_" : ()), "\n";
    };

    my ($view_with_port, $view_string) = $self->viewers($OUTPUT, $ERROR);

    {
        my @history;
        local $current_history = \@history;

        # ^ this is what nested repl's will use to restore the history
        # in the $term object
        if (defined $$self[Maybe_historypath]) {

            # clean history of C based object before we re-add the
            # saved one:
            $clear_history->($term);
            if (open my $hist, "<", $$self[Maybe_historypath]) {
                @history = <$hist>;
                close $hist;
                for (@history) {
                    chomp;
                    $term->addhistory($_);
                }
            }
        }

        # do not add input to history automatically (which allows me
        # to do it myself):
        $term->MinLine(undef);

        my $myreadline = sub {
        DO: {
                my $line;
                eval {
                    $line
                        = $term->readline($$self[Maybe_prompt]
                              // &$get_package()
                            . ($repl_level ? " $repl_level" : "")
                            . ($frameno    ? "/$frameno"    : "")
                            . "> ");
                    1
                } || do {
                    if (!length ref($@) and $@ =~ /^SIGINT\n/s) {
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
        my $evaluator = sub { };    # noop

        my $maybe_kept_results;

        my $maybe_lexical_persistence;
        my $try_enable_lexical_persistence = sub {
            eval {
                require Eval::WithLexicals;
                $maybe_lexical_persistence = Eval::WithLexicals->new;
                eval { require strictures }
                    or $maybe_lexical_persistence->prelude("");
                1
            } || do {
                print $ERROR "Could not enable lexical persistence: "
                    . show($@);
                0
            }
        };
        &$try_enable_lexical_persistence() if $self->use_lexical_persistence;

    READ: {
            while (1) {

                local $attribs->{attempted_completion_function}
                    = _completion_function($attribs, &$get_package,
                    $stack->perhaps_lexicals($frameno) // {});

                my $input = &$myreadline // last;

                if (length $input) {
                    my ($cmd, $rest)
                        = $input =~ /^ *[:,] *([?+-]|[a-zA-Z]+|\d+)(.*)/s
                        ? ($1, $2)
                        : (undef, $input);

                    if (defined $cmd) {

                        if ($cmd =~ /^\d+\z/) {

                            # hacky way to allow ":5" etc. as ":f 5"
                            $rest = "$cmd $rest";
                            $cmd  = "f";
                        }

                        # handle commands
                        eval {

                            my $set_package = sub {

                                # (no package parsing, trust user)
                                $$self[Maybe_package]
                                    = xone_nonwhitespace($rest);
                                $rest = "";    # XX HACK
                            };

                            my $help = sub { $self->print_help($OUTPUT) };

                            my $bt = sub {
                                my ($maybe_frameno)
                                    = $rest =~ /^\s*(\d+)?\s*\z/
                                    or die
                                    "expecting digits or no argument, got '$cmd'";
                                local $FP::Lazy::allow_access = 1;

                                # ^ XX should be generalized, not just
                                # for FP::Lazy; or alternatively, use
                                # overload::StrVal instead of
                                # stringification in the backtrace
                                # library.
                                print $OUTPUT $stack->backtrace($maybe_frameno
                                        // $frameno);
                                $rest = "";    # XX HACK; also, really
                                               # silently drop stuff?
                            };

                            my $chooseframe = sub {
                                my ($maybe_frameno) = @_;
                                $rest = "";    # still the hack, right?
                                if (defined $maybe_frameno) {
                                    if ($maybe_frameno <= $stack->max_frameno) {
                                        $frameno = $maybe_frameno
                                    } else {
                                        &$printerror_frameno($maybe_frameno);
                                        return;
                                    }
                                }

                                # unset any explicit package as
                                # we want to use the one of the
                                # current frame
                                undef $$self[Maybe_package]
                                    ;    # even without frameno? mess

                                # Show the context: (XX same
                                # issue as with :e with overly
                                # long data (need viewer, but
                                # don't really want to, so should
                                # really use shortener)
                                print $OUTPUT $stack->desc(
                                    $frameno, $self->mode_formatter
                                    ),
                                    "\n";
                            };

                            my $select_frame = sub {
                                my ($maybe_frameno)
                                    = $rest =~ /^\s*(\d+)?\s*\z/
                                    or die "expecting frame number, "
                                    . "an integer, or nothing, got '$cmd'";
                                &$chooseframe($maybe_frameno)
                            };

                            my %commands = (
                                h    => $help,
                                help => $help,
                                '?'  => $help,
                                '-'  => sub {
                                    &$chooseframe(
                                        ($frameno > 0) ? $frameno - 1 : undef)
                                },
                                '+' => sub {
                                    &$chooseframe(
                                        ($frameno < $stack->max_frameno)
                                        ? $frameno + 1
                                        : undef)
                                },
                                package => $set_package,
                                p       => $set_package,
                                1       => saving(
                                    $self, sub { $$self[Mode_context] = "1" }
                                ),
                                l => saving(
                                    $self, sub { $$self[Mode_context] = "l" }
                                ),
                                P => saving(
                                    $self, sub { $$self[Mode_formatter] = "p" }
                                ),
                                s => saving(
                                    $self, sub { $$self[Mode_formatter] = "s" }
                                ),
                                d => saving(
                                    $self, sub { $$self[Mode_formatter] = "d" }
                                ),
                                V => saving(
                                    $self, sub { $$self[Mode_viewer] = "V" }
                                ),
                                v => saving(
                                    $self, sub { $$self[Mode_viewer] = "v" }
                                ),
                                a => saving(
                                    $self, sub { $$self[Mode_viewer] = "a" }
                                ),
                                m => saving(
                                    $self,
                                    sub {
                                        &$try_enable_lexical_persistence()
                                            and $$self[Mode_lexical_persistence]
                                            = "m"
                                    }
                                ),
                                M => saving(
                                    $self,
                                    sub {
                                        &$try_enable_lexical_persistence()
                                            and $$self[Mode_lexical_persistence]
                                            = "M"
                                    }
                                ),
                                x => saving(
                                    $self,
                                    sub {
                                        undef $maybe_lexical_persistence;
                                        $$self[Mode_lexical_persistence] = "x"
                                    }
                                ),
                                X => saving(
                                    $self,
                                    sub {
                                        undef $maybe_lexical_persistence;
                                        $$self[Mode_lexical_persistence] = "X"
                                    }
                                ),
                                e => sub {
                                    use Data::Dumper;

                                    # XX clean up: don't want i in the regex
                                    my ($maybe_frameno)
                                        = $rest =~ /^i?\s*(\d+)?\s*\z/
                                        or die
                                        "expecting digits or no argument, got '$cmd'";
                                    $rest = ""
                                        ; # can't s/// above when expecting value
                                    my $fno = $maybe_frameno // $frameno;
                                    if (my ($lexicals)
                                        = $stack->perhaps_lexicals($fno))
                                    {
                                        &$view_with_port(
                                            sub {
                                                my ($o) = @_;
                                                my $format
                                                    = $self->formatter(1);
                                                for my $key (
                                                    sort keys %$lexicals)
                                                {
                                                    if ($key =~ /^\$/) {
                                                        $o->xprint(
                                                            "$key = "
                                                                . &$format(
                                                                ${
                                                                    $$lexicals{
                                                                        $key}
                                                                }
                                                                )
                                                        );
                                                    } else {
                                                        $o->xprint(
                                                            "\\$key = "
                                                                . &$format(
                                                                $$lexicals{$key}
                                                                )
                                                        );
                                                    }
                                                }
                                            }
                                        );
                                    } else {
                                        &$printerror_frameno($fno);
                                    }
                                },
                                f => $select_frame,
                                y => $select_frame,
                                q => sub {

                                    # XX change exit code depending
                                    # on how the repl was called?
                                    # Well, at least make it a config
                                    # field?
                                    exit 0
                                },
                                bt => $bt,
                                b  => $bt,
                            );

                            while (length $cmd) {

                          # XX why am I checking with and without chopping here?
                                if (my $sub = $commands{$cmd}) {
                                    &$sub;
                                    last;
                                } else {
                                    my $subcmd = chop $cmd;
                                    if (my $sub = $commands{$subcmd}) {
                                        &$sub;
                                        last;    # XX why last? shouldn't we
                                                 # continue with what's left of
                                                 # $cmd ?
                                    } else {
                                        print $ERROR "unknown command "
                                            . "or mode: '$subcmd'\n";
                                        last;
                                    }
                                }
                            }

                            1
                        } || do {
                            print $ERROR "error handling command $cmd: "
                                . show($@);
                            redo READ;
                        }
                    }

                    # build up evaluator
                    my $eval = do {
                        my $eval_ = sub {
                            $self->eval_code(
                                $rest,
                                $get_package,
                                $stack->perhaps_lexicals($frameno) // {},
                                $maybe_kept_results,
                                $maybe_lexical_persistence
                            )
                        };
                        hash_xref(
                            +{
                                1 => sub { ([scalar &$eval_()], $@) },
                                l => sub { ([&$eval_()],        $@) },
                            },
                            $self->mode_context
                        );
                    };

                    my $format_vals = $self->formatter;

                    $evaluator = sub {
                        my ($results, $error) = do {

                            # make it possible for the code entered in
                            # the repl to access the arguments in the
                            # last call leading to this position by
                            # accessing $FP::Repl::Repl::args :
                            my $getframe = sub {
                                my ($i) = @_;
                                if (
                                    defined(
                                        my $frame = $stack->frame($frameno + $i)
                                    )
                                    )
                                {
                                    $frame->args
                                } else {
                                    "TOP"
                                }
                            };
                            local $argsn = &$getframe(0);
                            local $args  = &$getframe(1);
                            &$eval()
                        };

                        &$view_string(
                            do {
                                if (ref $error or $error) {
                                    my $err = (
                                        (defined blessed $error)
                                            && $error->can("plain")
                                        ?

                                            # error in plaintext; XX:
                                            # change to better
                                            # thought-out protocol?
                                            $error->plain
                                        : show($error)
                                    );
                                    chomp $err;
                                    $err . "\n"
                                        ; # no prefix? no safe way to differentiate.
                                } else {
                                    if (my $varname
                                        = $$self[Maybe_keepResultIn])
                                    {
                                        $varname
                                            = &$get_package() . "::$varname"
                                            unless $varname =~ /::/;
                                        no strict 'refs';
                                        $$varname
                                            = $self->mode_context eq "1"
                                            ? $$results[0]
                                            : $results;
                                    }
                                    &$format_vals(@$results)
                                }
                            }
                        );
                        $maybe_kept_results = $results
                            if $$self[DoKeepResultsInVARX];
                    };

                    &$evaluator();

                } elsif ($$self[DoRepeatWhenEmpty]) {
                    &$evaluator();
                } else {
                    next;
                }

                if (length $input
                    and ((!defined $history[-1]) or $history[-1] ne $input))
                {
                    push @history, $input;
                    chomp $input;
                    $term->addhistory($input);

                    #splice @history,0,@history-$$self[MaxHistLen] = ();
                    if ($$self[MaxHistLen] >= 0) {    # <-prevent endless loop
                        shift @history while @history > $$self[MaxHistLen];
                    }
                }
            }
        }
        print $OUTPUT "\n";
        if (defined $$self[Maybe_historypath]) {
            eval {
                my $f = xtmpfile $$self[Maybe_historypath];
                $f->xprint("$_\n") for @history;
                $f->xclose;
                $f->xputback(0600);
            };
            if (ref $@ or $@) {
                warn "could not write history file: " . show($@)
            }
        }
        $SIG{INT} = defined($oldsigint) ? $oldsigint : "DEFAULT";

        # (Is there no other return path from sub run? should I use
        # DESTROY objects for this? -> nope, no returns, but if
        # exceptions not trapped it would fail)
    }

    # restore previous history, if any
    if ($current_history) {
        $clear_history->($term);
        for (@$current_history) {
            chomp;
            $term->addhistory($_);
        }
    }
}

end Chj::Class::Array;

# for backwards compatibility:
*set_maxhistlen         = *set_maxHistLen{CODE};
*set_docatchint         = *set_doCatchINT{CODE};
*set_dorepeatwhenempty  = *set_doRepeatWhenEmpty{CODE};
*set_maybe_keepresultin = *set_maybe_keepResultIn{CODE};

