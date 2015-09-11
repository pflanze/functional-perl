#
# Copyright (c) 2015 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FP::Equals::t -- tests for FP::Equals

=head1 SYNOPSIS

=head1 DESCRIPTION

run by test suite

=cut


package FP::Equals::t;

use strict; use warnings FATAL => 'uninitialized';

use FP::Equals;
use Chj::TEST;

# from the synopsis
TEST{ equals [1, [2, 3]], [1, [1+1, 3]] } 1;
TEST{ equals [1, [2, 3]], [1, [1+2, 3]] } '';
TEST{ equals [1, [2, 3]], [1, [[], 3]] } undef;

# 'systematic':
TEST{equals undef, undef} 1;
TEST{equals 1, undef} undef; # really give undef in
TEST{equals undef, 1} undef; #   this case?
TEST{equals 1, 1} 1;
TEST{equals 1, 0} '';
TEST{equals 0, 1} '';
TEST{equals [], 0} undef;
TEST{equals 0, []} undef;
TEST{equals [], []} 1;
TEST{my $v=[]; equals $v, $v} 1;
TEST{equals [], {}} undef;
TEST{equals {}, {}} 1;
TEST{equals {}, {a=>1}} '';
TEST{equals {a=>2}, {a=>1}} '';
TEST{equals {a=>1}, {b=>1}} '';
TEST{equals {a=>1}, {a=>1}} 1;
TEST{equals {a=>1,b=>2}, {a=>1}} '';
TEST{equals {a=>1,b=>2}, {a=>1,b=>2}} 1;
TEST{equals {a=>1,b=>2}, {a=>1,B=>2}} '';
TEST{equals {a=>1,b=>2}, {a=>1,b=>3}} '';
TEST{equals {a=>[1,3]}, {a=>[1,2+1]}} 1;
TEST{equals {a=>[1,3]}, {a=>[1,2]}} '';

TEST{equals "a", "b"} '';
TEST{equals "a", "a"} 1;

# Perl just can't disambiguate between numbers and strings, don't try
# to fight it?
TEST{equals "2", 2} 1;
TEST{equals "2.0", 2.0} '';

my $inf= $^V->{version}[1] > 20 ?
  # XX where exactly was it changed?
  # v5.14.2: inf
  # v5.21.11-27-g57e8809: Inf
  "Inf" : "inf";

TEST{equals 1e+20000, $inf} 1;
TEST{ 1e+20000 == "inf" } 1;
TEST{equals 1/(-1e+2000), 1/(1e+2000) } 1;
TEST{ 1/(-1e+2000) == 1/(1e+2000) } 1;
# so, no need to have both eq and == for those cases!

# but that's not the case here, of course:
TEST{ -1e1000 == "-1e1000" } 1;
TEST{ -1e1000 eq "-1e1000" } '';
TEST{ equals -1e1000, "-1e1000" } '';
TEST{ equals -1e1000, "-$inf" } 1;
TEST{ -1e1000 == "-inf" } 1;

TEST{equals 2, 2.0} 1;	   # those are converted to the same value at
                           # compile time.
TEST{equals "2", "2.0"} '';

# Weak typing is where the data (or context of the language) doesn't
# say what it is.

TEST{equals \("foo"), \("f"."oo")} 1;
TEST{equals \("foo"), \("bar")} '';
TEST{my $x= undef;
     my $y= undef;
     equals \$x, \$y} 1;
TEST{my $x= "foo";
     my $y= undef;
     equals \$x, \$y} undef;

# globs
TEST{equals *foo::bar, "*foo::bar"} undef;
TEST{equals ((*foo::bar)."", "*foo::bar")} 1;
TEST{equals *foo, *FP::Equals::t::foo} 1;
TEST{equals \*foo, \*FP::Equals::t::foo} 1;
TEST{equals \(*foo::bar), \("*foo::bar")} undef;
TEST{equals \(*foo::bar), \(*foo::baz)} '';
TEST{equals *foo, *bar} '';


# filehandles
TEST{equals *STDIN{IO}, *STDIN{IO}} 1; # equal pointers
TEST_EXCEPTION {equals *STDIN{IO}, *STDOUT{IO}}
  q{Can't locate object method "equals" via package "IO::File"};


# encoding
use utf8;
{
    my ($s1,$s2);
    TEST{$s1= "Smørrebrød";
	 $s2= "Smørrebrød";
	 equals $s1, $s2} 1;
    TEST{utf8::encode($s2);
	 equals $s1, $s2} '';
}


# Lazy values, classes:
use FP::Stream;
use FP::List;
use FP::Lazy;

TEST {equals "a", lazy { chr 65+32 } } 1;
TEST {equals stream (1,2), stream (1,2)} 1;
TEST {equals stream (1,2), lazy { cons 1, stream (2)}} 1;
TEST {equals stream (1,2), cons 1, stream (2)} 1;

# only one of the arguments lazy:

TEST { equals lazy { 2+1 }, 1+2 } 1;
TEST { equals 1+2, lazy { 2+1 } } 1;

TEST { equals lazy { [2+1] }, [lazy { 1+2 }] } 1;
TEST { equals lazy { [2+1] }, [lazy { 1+3 }] } '';

TEST { equals lazy { 2+1 }, [1+2] } undef;
TEST { equals lazy { [2+1] }, 1+2 } undef;
# and swapped arguments (shouldn't do this manually):
TEST { equals [1+2], lazy { 2+1 } } undef;
TEST { equals 1+2, lazy { [2+1] } } undef;

# does it force identical promises?

my ($a,$b,$sideeffect);
TEST { $a= lazy { $sideeffect++; 33*3 };
       $b= $a;
       equals $a, $b
   } 1;
TEST { $sideeffect } undef;

1
