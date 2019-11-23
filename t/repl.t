#!/usr/bin/env perl

# Copyright (c) 2015-2019 Christian Jaeger, copying@christianjaeger.ch
# This is free software. See the file COPYING.md that came bundled
# with this file.

use strict; use warnings; use warnings FATAL => 'uninitialized';

our $len= 672;

use lib "./lib";
use Test::Requires qw(FP::Repl::Dependencies Sub::Util);
use Test::More;
use FP::Repl;
use FP::Repl::Trap;
use Chj::xpipe;
use Chj::xperlfunc;
use Chj::xperlfunc qw(xlaunch);
use Chj::xhome qw(xeffectiveuserhome);
my $HOME= xeffectiveuserhome;

sub clean ($) {
    my ($s)=@_;

    $s=~ s/^\s*//s;
    $s=~ s/main>\s*$//s;

    my $id= do {
        my %id;
        my $counter=0;
        sub {
            my ($str)=@_;
            $id{$str} //= $counter++
        }
    };

    $s=~ s/\(eval (\d+)\)/'(eval ' . &$id ("eval $1") . ')'/sge;
    $s=~ s/\bline (\d+)\b/'line ' . &$id ("line $1")/sge;
    $s=~ s/(\w+)\((0x[0-9a-f]+)\)/"$1(0x" . &$id ("$1 $2") . ')'/sge;
    $s=~ s/(\*\w+::GEN)(\d+)/$1 . &$id("SymbolGEN $2")/sge;
    $s
}

#repl; exit;

sub t {
    my ($input,$output,@filters)=@_;

    $input=~ s/^\s+//s;
    $input=~ s/\s+$//s;

    my ($inr,$inw)= xpipe;
    my ($outr,$outw)= xpipe;
    if (xfork) {
        $inr->xclose; $outw->xclose;

        $inw->xprintln($input);
        $inw->xclose;
        my $out= $outr->xcontent;
        for my $filter (@filters) {
            local $_=$out;
            &$filter();
            $out=$_;
        }
        wait;
        @_=(
            clean($out),
            clean($output));
        if ($ENV{SHOWDIFF} and $_[0] ne $_[1]) {
            my ($package, $filename, $line)= caller;
            require Chj::xtmpfile; import Chj::xtmpfile;
            my @p=
              map {
                  my $t= xtmpfile(".t-repl-$line-");
                  $t->xprint($_[$_]);
                  $t->xclose;
                  $t->autoclean(0);
                  $t->path
              } 0,1;
            xlaunch "tkdiff", @p;
        }
        goto \&is;
    } else {
        $outr->xclose; $inw->xclose;

        $ENV{TERM}="";
        $ENV{COLORTERM}="";

        local $FP::Repl::Repl::maybe_settingspath= undef;
        local $FP::Repl::Repl::mode_formatter= 's';
        repl (maybe_input=> $inr,
              maybe_output=> $outw,
             );

        exit 0;
    }
}

my $filterHOME= sub {
    s,$HOME,<HOME>,sg
};


# ========================================================================
# The actual tests.

# To analyze test failures, install 'tkdiff' and run:
#
#  SHOWDIFF=1 t/repl.t

# When adding new tests, make sure to pass any special filters
# where necessary (the arguments to `t` after the first two).


# comments (XX: handle =pod etc., too?)
t '3 # 4',
  q{
main> 3 # 4
$VAR1 = 3;
};


# :e
t ',e',
  q{
main> ,e
$HOME = '<HOME>';
$input = ',e';
$inr = bless( \*Symbol::GEN0, 'Chj::IO::Pipe' );
$inw = bless( \*Symbol::GEN1, 'Chj::IO::Pipe' );
$output = 'DUMMY';
$outr = bless( \*Symbol::GEN2, 'Chj::IO::Pipe' );
$outw = bless( \*Symbol::GEN3, 'Chj::IO::Pipe' );
\@filters = [sub { 'DUMMY: main::__ANON__ at "t/repl.t" line 0' }, sub { 'DUMMY: main::__ANON__ at "t/repl.t" line 1' }];
},
  sub { s/(\$output = ').*(';\s*\$outr)/${1}DUMMY$2/s },
  $filterHOME;


# :e with lexicals from multiple scopes
t '
do {my $z=123; sub { my ($x)=@_; die "fun" }}->(99)
,e',
  '
main> do {my $z=123; sub { my ($x)=@_; die "fun" }}->(99)
Exception: fun at (eval 132) line 1.
main 1> ,e
$x = 99;
$z = undef;
main 1> 
fun at (eval 132) line 1.
';


# Backtrace
t '
do {my $z=123; sub { my ($x)=@_; die "fun" }}->(99)
,b',
  q+
main> do {my $z=123; sub { my ($x)=@_; die "fun" }}->(99)
Exception: fun at (eval 0) line 1.
main 1> ,b
0	FP::Repl::WithRepl::__ANON__('fun at (eval 0) line 1.\x{a}') called at (eval 0) line 1
1	main::__ANON__('99') called at (eval 0) line 1
2	main::__ANON__() called at lib/FP/Repl/Repl.pm line 2
3	FP::Repl::Repl::__ANON__() called at lib/FP/Repl/Repl.pm line 3
4	(eval)() called at lib/FP/Repl/Repl.pm line 3
5	FP::Repl::Repl::WithRepl_eval('CODE(0x11)') called at lib/FP/Repl/Repl.pm line 4
6	FP::Repl::Repl::eval_code('FP::Repl::Repl=ARRAY(0x12)', 'do {my $z=123; sub { my ($x)=@_; die "fun" }}->(99)', 'CODE(0x13)', 'HASH(0x14)', undef, undef) called at lib/FP/Repl/Repl.pm line 5
7	FP::Repl::Repl::__ANON__() called at lib/FP/Repl/Repl.pm line 6
8	FP::Repl::Repl::__ANON__() called at lib/FP/Repl/Repl.pm line 7
9	FP::Repl::Repl::__ANON__() called at lib/FP/Repl/Repl.pm line 8
10	FP::Repl::Repl::run('FP::Repl::Repl=ARRAY(0x12)', undef) called at t/repl.t line 9
11	main::t('\x{a}do {my $z=123; sub { my ($x)=@_; die "fun" }}->(99)\x{a},b', '\x{a}main> do {my $z=123; sub { my ($x)=@_; die "fun" }}->(99)\x{a}Ex...') called at t/repl.t line 10
main 1> 
fun at (eval 0) line 1.
+;


# argsn; args would contain the argument for t, thus recursive def
# (quine?..)
t '
$FP::Repl::Repl::argsn
',
  q+
main> $FP::Repl::Repl::argsn
$VAR1 = [bless(['<HOME>/.fp-repl_history', undef, 100, undef, undef, 1, 1, undef, 1, 'less', 'l', 's', 'a', 'X', bless( \*Symbol::GEN0, 'Chj::IO::Pipe' ), bless( \*Symbol::GEN1, 'Chj::IO::Pipe' )], 'FP::Repl::Repl'), undef];
+,
  $filterHOME;




# The various scope positions (argsn, args, :0, :e, $x):

# (A) from subrepl
t '
do {my $z=123; sub { my ($x)=@_; repl }}->(99)
$FP::Repl::Repl::argsn
$FP::Repl::Repl::args
,0
,e
$x
',
  q+
main> do {my $z=123; sub { my ($x)=@_; repl }}->(99)
main 1> $FP::Repl::Repl::argsn
$VAR1 = [bless(['<HOME>/.fp-repl_history', undef, 100, undef, undef, 1, 1, undef, 1, 'less', 'l', 's', 'a', 'X'], 'FP::Repl::Repl'), undef];
main 1> $FP::Repl::Repl::args
$VAR1 = [99];
main 1> ,0
FP::Repl::Repl::run(
  bless(['<HOME>/.fp-repl_history', undef, 100, undef, undef, 1, 1, undef, 1, 'less', 'l', 's', 'a', 'X'], 'FP::Repl::Repl'),
  undef
) called at (eval 0) line 1
main 1> ,e
$x = 99;
$z = undef;
main 1> $x
$VAR1 = 99;
main 1> 
$VAR1 = '';
+,
  $filterHOME;


# (B) from FP::Repl::Trap
t '
do {my $z=123; sub { my ($x)=@_; die "fun" }}->(99)
$FP::Repl::Repl::argsn
$FP::Repl::Repl::args
,0
,e
$x
',
  q+
main> do {my $z=123; sub { my ($x)=@_; die "fun" }}->(99)
Exception: fun at (eval 0) line 1.
main 1> $FP::Repl::Repl::argsn
$VAR1 = ['fun at (eval 0) line 1.
'];
main 1> $FP::Repl::Repl::args
$VAR1 = [99];
main 1> ,0
FP::Repl::WithRepl::__ANON__(
  'fun at (eval 0) line 1.
  '
) called at (eval 0) line 1
main 1> ,e
$x = 99;
$z = undef;
main 1> $x
$VAR1 = 99;
main 1> 
fun at (eval 0) line 1.
+,
  $filterHOME;


done_testing;
