#
# Copyright (c) 2019-2021 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FunctionalPerl::Htmlgen::Sourcelang -- detect programming language

=head1 SYNOPSIS

    use FunctionalPerl::Htmlgen::Sourcelang;
    is sourcelang("use Foo;"), "Perl";

=head1 DESCRIPTION

Detect if a piece of code is Perl, or more likely some other language.

=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut

package FunctionalPerl::Htmlgen::Sourcelang;
use strict;
use warnings;
use warnings FATAL => 'uninitialized';
use experimental "signatures";
use Exporter "import";

our @EXPORT      = qw(sourcelang);
our @EXPORT_OK   = qw();
our %EXPORT_TAGS = (all => [@EXPORT, @EXPORT_OK]);

use FP::Docstring;

sub sourcelang {
    __ '($codestr) -> $langname '
        . '-- langname is either "perl", or some other string';
    my ($str) = @_;
    my $perl  = 0;
    my $sh    = 0;

    $perl++ if $str =~ /(?:^|\n)\s*use\s+\w+/;
    $perl++ if $str =~ /\w+::\w+/;
    $perl++ if $str =~ /\$\w+\s*->\s*\w+/;
    $perl++ if $str =~ /\bmy\s+\$\w+\s*(?: = \s*[^;]*)?;/;
    $perl++ if $str =~ /\bmy\s+\(\$\w+/;
    $perl++ if $str =~ /\bsub\s*\{/;
    $perl += 1
        if $str
        =~ /\b(?:func?|sub)\b\s*(?:\w+\s*)?\((?:(?:\s*\$\w+\s*,)*\s*\$\w+\s*)?\)\s*\{/s;
    $perl += 1
        if $str
        =~ /sub maybe_/;   # hack, should properly fix the regex above for HEAD^
    $perl += 0.5 if $str =~ /\@\{\s*/;
    $perl += 0.5 if $str =~ /\bcompose\s*\(/;
    $perl += 0.5 if $str =~ /\\\&\w+/;
    $perl += 0.5 if $str =~ /->/;
    $perl += 0.5 if $str =~ /\(\s*\*\w+/;
    $perl += 0.5 if $str =~ /\(.*?,.*?\)/;          # (1,3,4) or ([1,3,4])
    $perl += 0.5 if $str =~ /\(\s*\[.*?\].*?\)/;    # ([1,3,4])
    do { $perl += 0.5; $sh += 0.5 } if $str =~ /\$\w+/;
    $perl += 1 if $str =~ /(?:^|\n|;)\s*push\s+\@\w+\s*,\s*/;
    $perl += 1 if $str =~ /\$VAR\d+\b/;
    $perl += 1 if $str =~ /(?:perlrepl|fperl)(?: *\d+)?>.*\bF\b/;
    $perl += 1 if $str =~ /\blazy\s*\{/;
    $sh   += 2
        if $str =~ m{(?:^|\n)\s*(?:[#\$]\s*)?(?:git |gpg |ls |chmod |cd |\./)};

    # Want repl sessions to be non highlighted? Do I ?
    $sh += 10 if $str =~ m{(?:^|\n) *main> };

    ($perl >= 1 and $perl > $sh) ? "Perl" : "shell"
}

use Chj::TEST;
use FP::List;
use FP::Either ":all";

sub test ($lang, $l) {
    lefts $l->map(
        sub ($c) {
            my $l = sourcelang $c;
            $l eq $lang ? Right undef : Left [$c, $l]
        }
    )
}

TEST {
    test "Perl", list(
        'Foo::bar;', 'use Foo;', 'my $a;', 'my $abc = 2+ 2;',
        'fun inverse ($x) { 1 / $x }',          'sub inverse ($x) { 1 / $x }',
        'PFLANZE::Node::constructors->import;', q{
    sub maybe_representable ($N, $D, $prefer_large = 1,
        $maybe_choose = $MAYBE_CHOOSE)
    {
        __ 'Returns the numbers containing $D that sum up to $N, or undef.
            If $prefer_large is true, tries to use large numbers,
            otherwise small (which is (much) less efficient).';
        ...
    }
        },

    )
}
null;

TEST {
    test "shell", list(
        'Foo;', 'my $a', 'tar -xzf foo.tgz', q{
$ ./113-1-represent_integer --repl
main> docstring \&maybe_representable 
$VAR1 = 'Returns the numbers containing $D that sum up to $N, or undef.
        If $prefer_large is true, tries to use large numbers,
        otherwise small (which is (much) less efficient).';
main> 
                       }, q{
main> \&maybe_representable 
$VAR1 = sub { 'DUMMY: main::maybe_representable at "./113-1-represent_integer" line 221'; __ 'Returns the numbers containing $D that sum up to $N, or undef.
        If $prefer_large is true, tries to use large numbers,
        otherwise small (which is (much) less efficient).' };
main> 
        },

    )
}
null;

1
