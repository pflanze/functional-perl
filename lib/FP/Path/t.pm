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

use strict; use warnings FATAL => 'uninitialized';

use Chj::TEST;
use FP::Path "path";
use FP::Equals;


TEST{ path("a/b/C")
  ->add( path("d/e"), 0 )->string }
  'a/b/C/d/e';
TEST{ path("a/b/C")
  ->add( path("../d/e"), 0 )->string }
  'a/b/C/../d/e';
TEST{ path("a/b/C")
  ->add( path("../d/e"), 1 )->string }
  'a/b/d/e';
TEST{ path("a/b/C")
  ->add( path("/d/e"), 1 )->string }
  '/d/e';

my $p= path ("a/../b/C")->add
  (path("../d/../e"), 0);
TEST { $p->string } 'a/../b/C/../d/../e';
TEST { $p->xclean->string } 'b/e';
TEST { $p->xclean->equals($p) } '';
TEST { $p->xclean->equals($p->xclean) } 1;


TEST { path ("a/.././b/C")->add
  (path("../d/./../e"), 0)->string }
  'a/../b/C/../d/../e'; # 'add' does an implicit clean_dot; should it be
                        # implemented differently?

TEST { (path "hello//world/you")->string }
  "hello/world/you";
TEST { (path "/hello//world/you")->string }
  "/hello/world/you";
TEST { (path "/hello//world/you/")->string }
  "/hello/world/you/";
TEST { (path "/")->string }
  "/";
TEST { (path ".")->string }
  ".";
TEST { (path "./")->string }
  "./";
TEST { (path "./")->clean_dot->string }
  "./";
TEST { (path "./..")->string }
  "./..";
TEST { (path "./..")->clean_dot->string }
  "..";

TEST { (path "./foo/../bar/.//baz/.")->clean_dot->string }
  "foo/../bar/baz/";
TEST { (path "")->clean_dot->string }
  # XX should this be an error?
  '.';

TEST { (path ".")->string }
  ".";
TEST { (path ".")->clean_dot->string }
  './';

TEST { (path "/")->string }
  "/";
TEST { (path "/")->clean_dot->string }
  "/";
TEST { (path "/.")->clean_dot->string }
  "/";
TEST { (path "/./")->clean_dot->string }
  "/";
TEST { (path "/./")->string }
  "/./";
TEST { (path "/.")->string }
  "/.";

TEST { (path "/.")->contains_dotdot }
  "0";
TEST { (path "foo/bar/../baz")->contains_dotdot }
  "1";
TEST { (path "../baz")->contains_dotdot }
  "1";
TEST { (path "baz/..")->contains_dotdot }
  "1";
TEST { (path "baz/..")->clean_dot->contains_dotdot }
  "1";

TEST_EXCEPTION { path(".")->clean_dot->dirname }
  q{can't take dirname of empty path};
TEST { path("foo")->clean_dot->dirname->string }
  './';
TEST { path("foo/bar")->clean_dot->dirname->string }
  'foo/';
TEST { path("/bar")->clean_dot->dirname->string }
  '/';
TEST_EXCEPTION { path("")->dirname }
  q{can't take dirname of empty path};

TEST { path(".")->clean_dot->has_endslash }
  1;
TEST { path(".")->clean_dot->string }
  './';
#ok
TEST { path("")->clean_dot->has_endslash }
  0;
TEST { path("")->clean_dot->string }
  '.';
#h

TEST { path("/foo")->to_relative->string }
  'foo';
TEST { path("/")->to_relative->string }
  './';
TEST_EXCEPTION { path("")->to_relative->string }
  q{is already relative};
TEST { path("/foo/")->to_relative->string }
 'foo/';

use FP::Equal;

TEST { equal (path("/"),
	      path("//"),
	      path("///")) }
  1;


# invalid segments:

use FP::List;

TEST_EXCEPTION { path("/foo")->add_segment("") }
  "segments cannot be the empty string";
TEST_EXCEPTION { path("/foo")->add_segment("bar/") }
  'segment contains slash: \'bar/\'';
TEST_EXCEPTION { FP::Path->new(list("/foo"), 1, 1)->string }
  ($FP::Path::use_costly_typing ?
   'unacceptable value for field \'rsegments\': list(\'/foo\')'
   : 'segment contains slash: \'/foo\'');


# equals:

sub t_equals ($$) {
    my ($a,$b)=@_;
    equals (path($a),
	    path($b))
}

TEST { t_equals "/foo", "/foo" } 1;
TEST { t_equals "/foo", "foo" } '';
TEST { t_equals "/foo", "/foo/" } '';
TEST { t_equals "/foo", "/bar" } '';
TEST { t_equals "/", "/" } 1;
TEST { t_equals "/foo/..", "/" } '';
TEST { t_equals "/foo", "/foo/bar" } '';

# test booleanization (!!) in equals method
TEST { my $p= path("/foo");
       equals $p, $p->has_endslash_set(0) } 1;

sub t_str_clean ($) {
    my ($a)=@_;
    path($a)->clean_dot->xclean_dotdot;
}

sub t_equals_clean ($$) {
    my ($a,$b)=@_;
    equals (t_str_clean $a, t_str_clean $b);
}

TEST { t_equals_clean "/foo", "/foo" } 1;
TEST { t_equals_clean "/foo", "foo" } '';
TEST { t_equals_clean "/foo/bar/..", "/foo" } '';
TEST { t_equals_clean "/foo/bar/..", "/foo/" } 1;
TEST { t_equals_clean "/foo/..", "/" } 1;



# split and resplit:

sub path_split_first_segment {
    my ($str, $clean)= @_;
    my $p= path $str;
    if (my @v = ($clean ? $p->xclean : $p)->perhaps_split_first_segment) {
	[map {$_->string} @v]
    } else {
	"unsplittable"
    }
}

TEST { path_split_first_segment "/foo/bar" }
  ["/foo/", "bar"];
TEST { path_split_first_segment "/foo/bar/" }
  ["/foo/", "bar/"];
TEST { path_split_first_segment "/foo/" }
  ["/foo/", "./"];
TEST { path_split_first_segment "/foo" }
  ["/foo", "."];
TEST { path_split_first_segment "/" }
  "unsplittable";
TEST { path_split_first_segment "./foo/bar" }
  ["./", "foo/bar"]; # ok? what you get for not cleaning.
TEST { path_split_first_segment "foo/bar" }
  ["foo/", "bar"];
TEST { path_split_first_segment "foo/" }
  ["foo/", "./"];
TEST { path_split_first_segment "foo" }
  ["foo", "."];
# (BTW isn't it stupid that ./ and . do both exist? Ok, some kinds of
# paths might treat "." as non-directory filename? But then it would
# fail anyway. XX)
TEST { path_split_first_segment "." }
  [".", "."]; # odd of course, but that's what you get for not cleaning?
TEST { path_split_first_segment ".", 1 }
  "unsplittable";


use FP::List qw(unfold);
use FP::Array qw(array_is_null array_map);
use FP::Ops qw(the_method);

sub tupleify ($) {
    my ($f)=@_;
    sub {
	@_==1 or die "wrong number of arguments";
	[ &$f (@{$_[0]}) ]
    }
}


sub all_splits {
    my ($str, $clean)= @_;
    my $p= path $str;
    my $p0= ($clean ? $p->xclean : $p);

    unfold (# ending predicate
	    *array_is_null,
	    # mapping function
	    sub { array_map the_method ("string"), $_[0] },
	    # stepping function
	    tupleify the_method ("perhaps_resplit_next_segment"),
	    # seed value
	    [ $p0->perhaps_split_first_segment ])
      ->array
}

TEST { all_splits "/foo/bar" }
  [[ '/foo/', 'bar' ],
   [ '/foo/bar', '.']];
TEST { all_splits "/foo/./bar" }
  [[ '/foo/', './bar' ],
   [ '/foo/./', 'bar' ],
   [ '/foo/./bar', '.']];
TEST { all_splits "/foo" }
  [[ '/foo', '.']];

# Note that the end cases above have a left part that does *not* have
# an end slash (it inherited the setting from the right part). Is this
# ok? The right side in this case is rather fake; and XX re-appending
# might fail in some algorithms! But what else would be better?

# It's unambiguous when the right hand argument has_end_slash==1:

TEST { all_splits "/foo/bar/" }
  [[ '/foo/', 'bar/' ],
   [ '/foo/bar/', './']];
TEST { all_splits "/foo/./bar/" }
  [[ '/foo/', './bar/' ],
   [ '/foo/./', 'bar/' ],
   [ '/foo/./bar/', './']];
TEST { all_splits "/foo/" }
  [[ '/foo/', './']];



# XX rules-based testing rules?:

# - if a path is absolute, the cleaned path is always absolute, too?

# previously: why?
# TEST { path("/..")->xclean_dotdot->string }
#   '/';
# TEST { path("/../..")->xclean_dotdot->string }
#   '..';
# TEST_EXCEPTION { path("..")->xclean_dotdot->string }
#   'can\'t take \'..\' of root directory';
# TEST_EXCEPTION { path("../..")->xclean_dotdot->string }
#   'can\'t take \'..\' of root directory';

TEST_EXCEPTION { path("..")->xclean_dotdot->string }
  'can\'t take \'..\' of root directory'; # ".."; ?
TEST_EXCEPTION { path("../..")->xclean_dotdot->string }
  'can\'t take \'..\' of root directory'; # "../.."; ?
TEST_EXCEPTION { path("/..")->xclean_dotdot->string }
  'can\'t take \'..\' of root directory';
TEST_EXCEPTION { path("/../..")->xclean_dotdot->string }
  'can\'t take \'..\' of root directory';

TEST_EXCEPTION {path("../foo")->xclean->string }
  "can't take '..' of root directory";
# should .. be allowed at the beginning? But then all of the above are
# ok, too, just translate into a number of ../ at the beginning. ->
# XX See scm libs re chroot / leaving root.


# - does cleaning a path that ends in /. leve it with has_endslash
# set?

TEST { path ("foo/.") -> has_endslash } '';
TEST { path ("foo/.") -> xclean -> has_endslash } 1;
TEST { path ("/.") -> has_endslash } '';
TEST { path ("/.") -> xclean -> has_endslash } 1;

TEST { path ("foo/..") -> has_endslash } '';
TEST { path ("foo/..") -> xclean -> has_endslash } 1;

TEST { path ("foo/bar/..") -> has_endslash } '';
TEST { path ("foo/bar/..") -> xclean -> has_endslash } 1;



1
