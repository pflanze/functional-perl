#
# Copyright (c) 2015-2019 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FP::Equal::t -- tests for FP::Equal

=head1 SYNOPSIS

=head1 DESCRIPTION

run by test suite

=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut

package FP::Equal::t;

use strict;
use warnings;
use warnings FATAL => 'uninitialized';

use FP::Equal ":all";
use Chj::TEST;

# compare arguments both straight and swapped; if the results don't
# match, return an array with both results
sub tequals {
    @_ == 2 or die "wrong num arg";
    my $x = equaln(@_);
    my $y = equaln(@_);
    if (defined $x) {
        if (defined $y) {
            if ($x eq $y) {
                return $x
            }
        }
    } else {
        if (defined $y) { [$x, $y] }
        else {
            undef
        }
    }
}

# from the synopsis
use FP::List;
use FP::Div qw(inc);
TEST { equal [1, list(2, 3)], [1, list(1,  2)->map(*inc)] } 1;
TEST { equal [1, list(2, 3)], [1, list(1,  2)] } '';
TEST { equal [1, list(2, 3)], [1, list([], 3)] } undef;

# 'systematic':
TEST { equal undef, undef } 1;
TEST { equal 1,     undef } undef;    # really give undef in
TEST { equal undef, 1 } undef;        #   this case?
TEST { equal 1,     1 } 1;
TEST { equal 1,     0 } '';
TEST { equal 0,     1 } '';
TEST { equal [], 0 } undef;
TEST { equal 0, [] } undef;
TEST { equal [], [] } 1;
TEST { my $v = []; equal $v, $v } 1;
TEST { equal [], {} } undef;
TEST { equal {}, {} } 1;
TEST { equal {}, { a => 1 } } '';
TEST { equal { a => 2 }, { a => 1 } } '';
TEST { equal { a => 1 }, { b => 1 } } '';
TEST { equal { a => 1 }, { a => 1 } } 1;
TEST { equal { a => 1, b => 2 }, { a => 1 } } '';
TEST { equal { a => 1, b => 2 }, { a => 1, b => 2 } } 1;
TEST { equal { a => 1, b => 2 }, { a => 1, B => 2 } } '';
TEST { equal { a => 1, b => 2 }, { a => 1, b => 3 } } '';
TEST { equal { a => [1, 3] }, { a => [1, 2 + 1] } } 1;
TEST { equal { a => [1, 3] }, { a => [1, 2] } } '';

TEST { equal "a", "b" } '';
TEST { equal "a", "a" } 1;

# Perl just can't disambiguate between numbers and strings, don't try
# to fight it?
TEST { tequals "2",   2 } 1;
TEST { tequals "2.0", 2.0 } '';

# Somewhere around version 5.20-5.21 Perl changed the formatting of
# inf from "inf" to "Inf". Instead of trying to figure out which
# version exactly changed it (if it's a precise version at all) try to
# determine the right way automatically:
sub positive_inf {
    my $inf = "inf" +0;
    $inf =~ /^\+?inf$/i or warn "positive_inf: got '$inf'";
    $inf
}

sub negative_inf {
    my $inf = -positive_inf;
    $inf =~ /^-inf$/i or warn "negative_inf: got '$inf'";
    $inf
}

TEST { tequals 1e+20000, positive_inf } 1;
TEST { 1e+20000 == "inf" } 1;
TEST { tequals 1 / (-1e+20000), 1 / (1e+20000) } 1;
TEST { 1 / (-1e+20000) == 1 / (1e+20000) } 1;

# so, no need to have both eq and == for those cases!

# but that's not the case here, of course:
TEST { -1e1000 == "-1e1000" } 1;
TEST { -1e1000 eq "-1e1000" } '';
TEST { tequals -1e100, "-1e100" } '';
TEST { tequals -1e10000, "-1e10000" } '';
TEST { tequals -1e10000, negative_inf } 1;
TEST { -1e10000 == "-inf" } 1;

TEST { tequals 2,   2.0 } 1;      # those are converted to the same value at
                                  # compile time.
TEST { tequals "2", "2.0" } '';

# Weak typing is where the data (or context of the language) doesn't
# say what it is.

TEST { tequals \("foo"), \("f" . "oo") } 1;
TEST { tequals \("foo"), \("bar") } '';
TEST {
    my $x = undef;
    my $y = undef;
    tequals \$x, \$y
}
1;
TEST {
    my $x = "foo";
    my $y = undef;
    tequals \$x, \$y
}
undef;

# globs
TEST { tequals *foo::bar, "*foo::bar" } undef;
TEST { tequals((*foo::bar) . "", "*foo::bar") } 1;
TEST { tequals *foo, *FP::Equal::t::foo } 1;
TEST { tequals \*foo, \*FP::Equal::t::foo } 1;
TEST { tequals \(*foo::bar), \("*foo::bar") } undef;
TEST { tequals \(*foo::bar), \(*foo::baz) } '';
TEST { tequals *foo, *bar } '';

# filehandles
TEST {
    equal * STDIN {IO}, *STDIN{IO}
}
1;    # equal pointers
TEST_EXCEPTION {
    equal * STDIN {IO}, *STDOUT{IO}
}
q{Can't locate object method "FP_Equal_equal" via package "IO::File"};

# encoding
use utf8;
{
    my ($s1, $s2);
    TEST {
        $s1 = "Smørrebrød";
        $s2 = "Smørrebrød";
        equal $s1, $s2
    }
    1;
    TEST {
        utf8::encode($s2);
        equal $s1, $s2
    }
    '';
}

# Lazy values, classes:
use FP::Stream;
use FP::Lazy;

TEST {
    tequals "a", lazy { chr 65 + 32 }
}
1;
TEST { tequals stream(1, 2), stream(1, 2) } 1;
TEST {
    tequals stream(1, 2), lazy { cons 1, stream(2) }
}
1;
TEST { tequals stream(1, 2), cons 1, stream(2) } 1;

# only one of the arguments lazy:

TEST {
    tequals lazy { 2 + 1 }, 1 + 2
}
1;

TEST {
    tequals lazy { [2 + 1] }, [lazy { 1 + 2 }]
}
1;
TEST {
    tequals lazy { [2 + 1] }, [lazy { 1 + 3 }]
}
'';

TEST {
    tequals lazy { 2 + 1 }, [1 + 2]
}
undef;
TEST {
    tequals lazy { [2 + 1] }, 1 + 2
}
undef;

# does it force identical promises?

my ($a, $b, $sideeffect);
TEST {
    $sideeffect = 0;
    $a          = lazy { $sideeffect++; 33 * 3 };
    $b          = $a;
    tequals $a, $b
}
1;
TEST {$sideeffect} 0;

TEST {
    $sideeffect = 0;
    $a          = lazy { $sideeffect++; 33 * 3 };
    $b          = lazy { $sideeffect++; 33 * 3 };
    tequals $a, $b
}
1;
TEST {$sideeffect} 2;

# lazy and undef or non-references:

TEST {
    tequals lazy {undef}, undef
}
1;
TEST {
    tequals lazy {"a"}, "a"
}
1;
TEST {
    tequals lazy {"a"}, undef
}
undef;
TEST {
    tequals lazy {undef}, "a"
}
undef;

1
