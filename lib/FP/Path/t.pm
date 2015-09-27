#
# Copyright (c) 2011-2015 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FP::Path::t

=head1 SYNOPSIS

=head1 DESCRIPTION

run by test suite

=cut


package FP::Path::t;
#@ISA="Exporter"; require Exporter;
#@EXPORT=qw();
#@EXPORT_OK=qw();
#%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict; use warnings FATAL => 'uninitialized';

use Chj::TEST;
use FP::Path;
use FP::Equals;


TEST{ FP::Path->new_from_string("a/b/C")
  ->add( FP::Path->new_from_string("d/e"), 0 )->string }
  'a/b/C/d/e';
TEST{ FP::Path->new_from_string("a/b/C")
  ->add( FP::Path->new_from_string("../d/e"), 0 )->string }
  'a/b/C/../d/e';
TEST{ FP::Path->new_from_string("a/b/C")
  ->add( FP::Path->new_from_string("../d/e"), 1 )->string }
  'a/b/d/e';
TEST{ FP::Path->new_from_string("a/b/C")
  ->add( FP::Path->new_from_string("/d/e"), 1 )->string }
  '/d/e';

my $p= FP::Path->new_from_string ("a/../b/C")->add
  (FP::Path->new_from_string("../d/../e"), 0);
TEST { $p->string } 'a/../b/C/../d/../e';
TEST { $p->xclean_dotdot->string } 'b/e';
TEST { $p->xclean_dotdot->equals($p) } '';
TEST { $p->xclean_dotdot->equals($p->xclean_dotdot) } 1;


TEST { FP::Path->new_from_string ("a/.././b/C")->add
  (FP::Path->new_from_string("../d/./../e"), 0)->string }
  'a/../b/C/../d/../e'; # 'add' does an implicit clean_dot; should it be
                        # implemented differently?

TEST { (new_from_string FP::Path "hello//world/you")->string }
  "hello/world/you";
TEST { (new_from_string FP::Path "/hello//world/you")->string }
  "/hello/world/you";
TEST { (new_from_string FP::Path "/hello//world/you/")->string }
  "/hello/world/you/";
TEST { (new_from_string FP::Path "/")->string }
  "/";
TEST { (new_from_string FP::Path ".")->string }
  ".";
TEST { (new_from_string FP::Path "./")->string }
  "./";
TEST { (new_from_string FP::Path "./")->clean_dot->string }
  "./";
TEST { (new_from_string FP::Path "./..")->string }
  "./..";
TEST { (new_from_string FP::Path "./..")->clean_dot->string }
  "..";

TEST { (new_from_string FP::Path "./foo/../bar/.//baz/.")->clean_dot->string }
  "foo/../bar/baz/";
TEST { (new_from_string FP::Path "")->clean_dot->string }
  # XX should this be an error?
  '.';

TEST { (new_from_string FP::Path ".")->string }
  ".";
TEST { (new_from_string FP::Path ".")->clean_dot->string }
  './';

TEST { (new_from_string FP::Path "/")->string }
  "/";
TEST { (new_from_string FP::Path "/")->clean_dot->string }
  "/";
TEST { (new_from_string FP::Path "/.")->clean_dot->string }
  "/";
TEST { (new_from_string FP::Path "/./")->clean_dot->string }
  "/";
TEST { (new_from_string FP::Path "/./")->string }
  "/./";
TEST { (new_from_string FP::Path "/.")->string }
  "/.";

TEST { (new_from_string FP::Path "/.")->contains_dotdot }
  "0";
TEST { (new_from_string FP::Path "foo/bar/../baz")->contains_dotdot }
  "1";
TEST { (new_from_string FP::Path "../baz")->contains_dotdot }
  "1";
TEST { (new_from_string FP::Path "baz/..")->contains_dotdot }
  "1";
TEST { (new_from_string FP::Path "baz/..")->clean_dot->contains_dotdot }
  "1";

TEST_EXCEPTION { FP::Path->new_from_string(".")->clean_dot->dirname }
  q{can't take dirname of empty path};
TEST { FP::Path->new_from_string("foo")->clean_dot->dirname->string }
  '.';
TEST { FP::Path->new_from_string("foo/bar")->clean_dot->dirname->string }
  'foo';
TEST_EXCEPTION { FP::Path->new_from_string("")->dirname }
  q{can't take dirname of empty path};

TEST { FP::Path->new_from_string(".")->clean_dot->has_endslash }
  1;
TEST { FP::Path->new_from_string(".")->clean_dot->string }
  './';
#ok
TEST { FP::Path->new_from_string("")->clean_dot->has_endslash }
  0;
TEST { FP::Path->new_from_string("")->clean_dot->string }
  '.';
#h

TEST { FP::Path->new_from_string("/foo")->to_relative->string }
  'foo';
TEST { FP::Path->new_from_string("/")->to_relative->string }
  './';
TEST_EXCEPTION { FP::Path->new_from_string("")->to_relative->string }
  q{is already relative};
TEST { FP::Path->new_from_string("/foo/")->to_relative->string }
 'foo/';

use FP::Equal;

TEST { equal (FP::Path->new_from_string("/"),
	      FP::Path->new_from_string("//"),
	      FP::Path->new_from_string("///")) }
  1;


# equals:

sub t_equals ($$) {
    my ($a,$b)=@_;
    equals (FP::Path->new_from_string($a),
	    FP::Path->new_from_string($b))
}

TEST { t_equals "/foo", "/foo" } 1;
TEST { t_equals "/foo", "foo" } '';
TEST { t_equals "/foo", "/foo/" } '';
TEST { t_equals "/foo", "/bar" } '';
TEST { t_equals "/", "/" } 1;
TEST { t_equals "/foo/..", "/" } '';
TEST { t_equals "/foo", "/foo/bar" } '';

# test booleanization (!!) in equals method
TEST { my $p= FP::Path->new_from_string("/foo");
       equals $p, $p->has_endslash_set(0) } 1;

sub t_str_clean ($) {
    my ($a)=@_;
    FP::Path->new_from_string($a)->clean_dot->xclean_dotdot;
}

sub t_equals_clean ($$) {
    my ($a,$b)=@_;
    equals (t_str_clean $a, t_str_clean $b);
}

TEST { t_equals_clean "/foo", "/foo" } 1;
TEST { t_equals_clean "/foo", "foo" } '';
TEST { t_equals_clean "/foo/bar/..", "/foo" } 1;
# hmm, because "/" has_endslash true (necessarily??), we get:
TEST { t_equals_clean "/foo/..", "/" } '';


# XX rules-based testing rules?:

# - if a path is absolute, the cleaned path is always absolute, too?

# previously: why?
# TEST { FP::Path->new_from_string("/..")->xclean_dotdot->string }
#   '/';
# TEST { FP::Path->new_from_string("/../..")->xclean_dotdot->string }
#   '..';
# TEST_EXCEPTION { FP::Path->new_from_string("..")->xclean_dotdot->string }
#   'can\'t take \'..\' of root directory';
# TEST_EXCEPTION { FP::Path->new_from_string("../..")->xclean_dotdot->string }
#   'can\'t take \'..\' of root directory';

TEST_EXCEPTION { FP::Path->new_from_string("..")->xclean_dotdot->string }
  'can\'t take \'..\' of root directory'; # ".."; ?
TEST_EXCEPTION { FP::Path->new_from_string("../..")->xclean_dotdot->string }
  'can\'t take \'..\' of root directory'; # "../.."; ?
TEST_EXCEPTION { FP::Path->new_from_string("/..")->xclean_dotdot->string }
  'can\'t take \'..\' of root directory';
TEST_EXCEPTION { FP::Path->new_from_string("/../..")->xclean_dotdot->string }
  'can\'t take \'..\' of root directory';



1
