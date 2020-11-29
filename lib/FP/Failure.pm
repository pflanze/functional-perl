#
# Copyright (c) 2019-2020 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FP::Failure - failure values

=head1 SYNOPSIS

    use FP::Equal ':all'; use FP::Ops qw(the_method regex_substitute); use FP::List;
    use FP::Failure;
    is_equal \@FP::Failure::EXPORT, [qw(failure is_failure)];
    # but there is more in EXPORT_OK...
    use FP::Failure '*trace_failures';

    my $vals = do {
        local $trace_failures = 0;
        list(failure("not good"),
             failure(666),
             failure(undef),
             666,
             0,
             undef)
    };

    is_equal $vals->map(*is_failure),
             list(1, 1, 1, undef, undef, undef);

    is_equal $vals->map(sub { my ($v) = @_; $v ? "t" : "f" }),
             list("f", "f", "f", "t", "f", "f");

    # failure dies when called in void context (for safety, failures have
    # to be ignored *explicitly*):
    is((eval { failure("hello"); 1 } || ref $@),
       'FP::Failure::Failure');

    # get the wrapped value
    is_equal $vals->filter(*is_failure)->map(the_method "value"),
             list("not good", 666, undef);

    # get a nice message
    is_equal $vals->first->message,
             "failure: 'not good'\n";

    # record backtraces
    my $v = do {
        local $trace_failures = 1;
        failure(666, [$vals->first])
    };

    is_equal $v->message,
             "failure: 666\n  because:\n  failure: 'not good'\n";

    # request recorded backtrace to be shown
    use Path::Tiny;
    is_equal regex_substitute(sub { # cleaning up bt
                                  s/line \d+/line .../g;
                                  my $btlines = 0;
                                  $_ = join("\n",
                                           grep { not /^    \S/ or ++$btlines < 2 }
                                           split /\n/)
                              },
                              $v->message(1)),
             join("\n", "failure: 666 at ".path("lib/FP/Failure.pm")->canonpath
                        ." line ...",
                        "    (eval) at lib/FP/Repl/WithRepl.pm line ...",
                        "  because:",
                        "  failure: 'not good'");

    # Wrapper that just returns 0 unless configured to create a failure
    # object:

    use FP::Failure qw(*use_failure fails);
    use FP::Show;

    is show(do { local $use_failure = 0; fails("hi") }),
       0;
    is show(do { local $use_failure = 1; fails("hi") }),
       "Failure('hi', undef, undef)";


    # Utility container for holding both a message and values:

    use FP::Failure qw(message messagefmt);

    is failure(message "Hi", "foo", 9)->message,
       "failure: Hi: 'foo', 9\n";
    is failure(message "Hi")->message,
       "failure: Hi\n";

    # messagefmt is currently still passing everything through FP::Show;
    # what should it do, implement another fmt character?
    is failure(messagefmt "Hi %s %d", "foo", 9)->message,
       "failure: Hi 'foo' 9\n";


=head1 DESCRIPTION

Values meant to represent errors/failures and to be distinguishable
from non-error values. They are overloaded to be false in boolean
context (although doing a boolean test is not safe to distinguish from
non-failure values, as obviously those include false as well), or
checked via the `is_failure` function.

The `value` method delivers the first argument given to `failure`,
`maybe_parents` the second, which is an array of the parents, meant
for chaining failures (reasons why this failure happened). `message`
produces a somewhat nice to read string, multi-line if parents are
chained in.

Calling the constructor in void context throws the constructed failure
value as an exception.

If the variable `$FP::Failure::trace_failures` is set to true (it can
be imported mutably via '*trace_failures'; default: false), then a
stack trace is collected with the failures and displayed with
`message` (if a true value is passed to message ?). (XX: use
`BACKTRACE=1` idea here, too?  Implement the same in `Chj::Backtrace`,
too, and FP::Repl::Trap if fitting?)

If the variable `$FP::Failure::use_failure` is set to true (it can be
imported mutably via '*use_failures'; default: false), then the
optionally exported wrapper function `fails` calls `failure` with its
arguments, otherwise it returns `0` (fully compatible with standard
Perl booleans, and a little bit faster).

=head1 TODO

Instead of using `FP::Failure::Failure` as base class, create a
failure protocol (FP::Abstract::Failure) instead?

=head1 SEE ALSO

Implements: L<FP::Abstract::Pure>, L<FP::Struct::Show>

=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut

package FP::Failure;
use strict;
use warnings;
use warnings FATAL => 'uninitialized';
use Exporter "import";

our @EXPORT    = qw(failure is_failure);
our @EXPORT_OK = qw(*trace_failures *use_failure fails
    message messagefmt);
our %EXPORT_TAGS = (all => [@EXPORT, @EXPORT_OK]);

use FP::Lazy 'force';
use Safe::Isa;
use FP::Carp;

package FP::Failure::Failure {

    use FP::Show;
    use Safe::Isa;

    # avoid circular dependency on FP::Predicates
    sub maybe_array {
        my ($v) = @_;
        !defined $v or ref($v) eq "ARRAY"
    }

    use FP::Struct [
        "value",
        [
            *maybe_array, "maybe_parents"

                # Array of failures that are the reason for this
                # failure. Values other than FP::Failure::Failure are
                # (mostly) ignored; allow anything to be stored so no
                # complicated logic is needed for capture.
        ],
        "maybe_trace",    # [[caller(0)],...]
        ],
        'FP::Abstract::Pure', 'FP::Struct::Show';

    use overload
        bool => sub {undef},

        # Have to provide stringification, too, or it will stringify
        # to undef and then fail to use the undef value in strings
        # because of fatal warnings... and it can't be avoided by
        # checking with `defined $v` first, as that returns
        # false. Tricky Perl features.
        '""' => sub { show $_[0] },

        # '0+' => sub { warn "hello0+"; '' },
        # fallback => 0
        ;

    sub message {
        my $s = shift;
        my ($showtrace, $maybe_indent) = @_;
        my $indent   = $maybe_indent // "";
        my $tracestr = do {
            if ($showtrace and my $t = $s->maybe_trace) {
                my $seen = 0;
                join(
                    "\n$indent    ",
                    map {
                        my (undef, $file, $line, $subname) = @$_;
                        $subname = "" unless $seen;
                        $seen    = 1;
                        "$subname at $file line $line"
                    } @$t
                )
            } else {
                ""
            }
        };

        my $valuestr = do {
            my $value = $s->value;
            $value->$_isa('FP::Failure::Abstract::Message')
                ? $value->message
                : show($value)
        };
        $indent . "failure: " . $valuestr . $tracestr . "\n" . do {
            my @parents = grep { FP::Failure::is_failure($_) }
                @{ $s->maybe_parents // [] };
            if (@parents) {
                $indent
                    . "  because:\n"
                    . join("",
                    map { $_->message($showtrace, $indent . "  ") } @parents)
            } else {
                ""
            }
        }
    }

    _END_
}

our $trace_failures = 0;    # bool

sub failure {
    @_ >= 1 and @_ <= 2 or fp_croak_nargs "1-2";
    my ($value, $maybe_parents) = @_;
    my $v = FP::Failure::Failure->new(
        $value,
        $maybe_parents,
        $trace_failures
        ? do {
            my @t;
            my $i = 0;
            while (1) {
                my $t = [caller $i];
                last unless @$t;
                push @t, $t;
                $i++
            }
            \@t
            }
        : undef
    );
    defined wantarray ? $v : die $v
}

sub is_failure {
    @_ == 1 or fp_croak_nargs 1;
    force($_[0])->$_isa("FP::Failure::Failure")
}

our $use_failure = 0;    # bool

sub fails {
    @_ >= 1 and @_ <= 2 or fp_croak_nargs "1-2";
    $use_failure            ? &failure(@_)
        : defined wantarray ? 0
        :                     die "fails called in void context";
}

package FP::Failure::Abstract::Message {
    use FP::Struct [], 'FP::Abstract::Pure', 'FP::Struct::Show';
    _END_
}

package FP::Failure::Message {
    use FP::Show;

    use FP::Struct ['messagestring', 'arguments'],
        'FP::Failure::Abstract::Message';

    sub message {
        @_ == 1 or fp_croak_nargs 1;
        my $s    = shift;
        my $args = $s->arguments;
        my $msg  = $s->messagestring;
        @$args ? "$msg: " . join(", ", map { show $_ } @$args) : $msg
    }
    _END_
}

sub message {
    my ($msgstr, @args) = @_;
    FP::Failure::Message->new($msgstr, \@args)
}

package FP::Failure::MessageFmt {
    use FP::Show;

    use FP::Struct ['formatstring', 'arguments'],
        'FP::Failure::Abstract::Message';

    sub message {
        @_ == 1 or fp_croak_nargs 1;
        my $s = shift;
        sprintf($s->formatstring, map { show $_ } @{ $s->arguments })
    }

    _END_
}

sub messagefmt {
    my ($fmtstr, @args) = @_;
    if (not $fmtstr =~ /\%\%/) {
        if (($fmtstr =~ tr/%/%/) == @args) {
            FP::Failure::MessageFmt->new($fmtstr, \@args)
        } else {
            die "wrong number of arguments (" . @args
                . ") for given format string '$fmtstr'"
        }
    } else {
        die "full fmt parsing support not implemented yet"    # XX todo
    }
}

1
