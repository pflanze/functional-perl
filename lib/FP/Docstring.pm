#
# Copyright (c) 2019-2020 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FP::Docstring

=head1 SYNOPSIS

    use FP::Docstring; # imports `__` (which does nothing) and `docstring`

    sub foo {
        __ "bars the foo out of the list";
        my ($l) = @_;
        $l->filter(sub{not $_[0] =~ /foo/})
    }

    is docstring(\&foo),
       "bars the foo out of the list";


=head1 DESCRIPTION

A docstring is a (short) string used to document subroutines that is
part of the code at runtime and hence retrievable at runtime,
e.g. from a debugger or L<FP::Repl>. It is currently also shown by
L<FP::Show> (it makes the display verbose, though, thus this might
change).

=head1 BUGS

Using single-quoted strings directly after C<__> is giving an "Bad
name after __'" error, because the Perl parser thinks of the single
quote as being a namespace delimiter. Put a space between the C<__>
and the string.

The extraction process may erroneously find things that are not
docstrings, due to it doing ad-hoc string parsing of the deparsed
code. If a docstring declaration *is* used at the beginning of the sub
then it should be safely retrieved though.

=head1 SEE ALSO

L<Docstring (Wikipedia)|https://en.wikipedia.org/wiki/Docstring>

L<FP::Repl>

=cut

package FP::Docstring;
use strict;
use warnings;
use warnings FATAL => 'uninitialized';
use Exporter "import";

our @EXPORT      = qw(__ docstring);
our @EXPORT_OK   = qw();
our %EXPORT_TAGS = (all => [@EXPORT, @EXPORT_OK]);

use Chj::TEST;

# Exception: use prototype here? Really DSL. Point it out early.
sub __ ($) { }

# optimization would be to make it syntax...

my %endquote = ('[' => ']', '(' => ')', '{' => '}');

my $warned;

sub docstring {
    @_ == 1 or die "wrong number of arguments";
    my ($fn_or_glob) = @_;
    my $fn
        = UNIVERSAL::isa($fn_or_glob,  "CODE") ? $fn_or_glob
        : UNIVERSAL::isa(\$fn_or_glob, "GLOB") ? \&$fn_or_glob
        :   die "not a coderef nor glob: $fn_or_glob";
    if (eval { require B::Deparse; 1 }) {
        my $str = B::Deparse->new->coderef2text($fn);

        #warn "str='$str'";
        if (my ($docstring) = $str =~ /\b__\('(.*?)'\);/s) {
            $docstring
        } elsif (($docstring) = $str =~ /\b__\("(.*?)"\);/s) {
            $docstring =~ s/\\n/\n/sg;
            $docstring =~ s/\\\\/\\/sg;
            $docstring =~ s/\\\$/\$/sg;
            $docstring
        } elsif (my ($quote, $docstring_and_rest) = $str =~ /\b__\(q(.)(.*)/s) {

            # sigh, really?
            my $endquote = $endquote{$quote}
                or die "don't know what quote this is: $quote";
            $docstring_and_rest =~ s/\Q$endquote\E.*//s;
            $docstring_and_rest
        } else {
            undef
        }
    } else {
        unless ($warned) {
            warn "for docstring support, install B::Deparse" unless $warned;
            $warned = 1;
        }
        undef
    }
}

# try to trick the parser:
TEST {
    docstring(sub { __ "hi\');"; $_[0] + 1 })
}
'hi\');';
TEST {
    docstring(sub { __ "hi\");"; $_[0] + 1 })
}
'hi");';

# get the quoting right:
TEST {
    docstring(sub { __ '($foo) -> hash'; $_[0] + 1 })
}
'($foo) -> hash';
TEST {
    docstring(sub { __ '("$foo")'; $_[0] + 1 })
}
'("$foo")';
TEST {
    docstring(sub { __ '(\'$foo\')'; $_[0] + 1 })
}
'(\'$foo\')';
TEST {
    docstring sub {
        __ '($str, $token, {tokenargument => $value,..})-> $str
        re-insert hidden parts';
        1
    }
}
'($str, $token, {tokenargument => $value,..})-> $str
        re-insert hidden parts';

1
