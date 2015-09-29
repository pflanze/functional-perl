#
# Copyright (c) 2011-2015 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FP::Path

=head1 SYNOPSIS

 use FP::Path;
 my $p= FP::Path->new_from_string ("a/../b/C")->add
  (FP::Path->new_from_string("../d/../e"), 0);
 $p->string # 'a/../b/C/../d/../e'
 $p->xclean->string # 'b/e'
 $p->xclean->equals($p) # ''
 $p->xclean->equals($p->xclean) # 1

 # or use the (evil?) constructor function export feature:
 use FP::Path "path";
 path("a/../b/C")->xclean->string # "b/C"

=head1 DESCRIPTION

Not really sure why I'm creating something from scratch here? It might
be cleaner:

This doesn't do I/O (access the file system, ask the system for the
hostname, etc.), and it doesn't resolve ".." unless when told to
(`perhaps_clean_dotdot` and derived methods (incl. `xclean` etc.)).

=head1 TODO

Port / merge with
https://github.com/pflanze/chj-schemelib/blob/master/cj-posixpath.scm
?

Provide `string_to_path` constructor function?

=head1 SEE ALSO

L<FP::Path::t> for the test suite

=cut


package FP::Path;

use strict;

use FP::List ":all";
use FP::Equals ();
use Chj::constructorexporter;

use FP::Struct
  [
   'rsegments', # reverse FP::List::List of str not containing slashes
   'has_endslash', # bool, whether the path is forcibly specifying a
                   # dir by using a slash at the end (forcing a dir by
                   # ending in "." isn't setting this flag)
   'is_absolute', # bool
  ];

*import= constructorexporter new_from_string=> "path";


sub new_from_string {
    @_==2 or die "wrong number of arguments";
    my ($class, $str)=@_;
    my @p= split m{/+}, $str;
    shift @p if (@p and $p[0] eq "");
    $class->new(array_to_list_reverse(\@p),
		scalar $str=~ m{/$}s,
		scalar $str=~ m{^/}s)
}

sub equals {
    @_==2 or die "wrong number of arguments";
    my ($a,$b)=@_;
    # no need to compare is_absolute, since it is being distinguished
    # anyway? Or better be safe than sorry?
    (FP::Equals::equals (!!$a->is_absolute, !!$b->is_absolute)
     and
     FP::Equals::equals (!!$a->has_endslash, !!$b->has_endslash)
     and
     FP::Equals::equals ($a->rsegments, $b->rsegments))
}

sub segments {
    my $s=shift;
    $s->rsegments->reverse
}

sub string {
    my $s=shift;
    my $rs= $s->rsegments;

    # force "." for empty relative paths:
    my $rs1= is_null ($rs) && not($s->is_absolute) ? list(".") : $rs;

    # add end slash
    my $ss= ($s->has_endslash ? $rs1->cons("") : $rs1)->reverse;

    # add start slash
    ($s->is_absolute ? $ss->cons("") : $ss)->strings_join("/")
}

# remove "." entries: (leave ".." in, because these cannot be resolved
# without reading the file system or knowing the usage)
sub clean_dot {
    my $s=shift;
    my $rseg= $s->rsegments;
    $s->rsegments_set ($rseg->filter(sub { not ($_[0] eq ".") }))
      ->has_endslash_set
	(
	 # set forced dir flag if the last segment was a ".", even
	 # if previously it didn't end in "/"
	 $$s{has_endslash}
	 or
	 do {
	     if (is_null $rseg) {
		 0
	     } else {
		 $rseg->car  eq "."
	     }
	 });
}

# XX is only valid to be applied to paths that have already been
# `clean_dot`ed !
sub perhaps_clean_dotdot {
    my $s=shift;
    # XX this might actually be more efficient when working on the reverse
    # order? But leaving old imperative algorithm for now.
    my @s;
    for my $seg ($s->rsegments->reverse_values) {
	if ($seg eq "..") {
	    if (@s) {
		my $v= pop @s;
		# XXX why was there no check here before?
		if (! length $v and ! @s) {
		    return ()
		}
	    } else {
#XXX why was it this way, and what should it be?
#		if ($s->is_absolute) {
#		    push @s, "..";
#		} else {
		    return ()
#		}
	    }
	} else {
	    push @s, $seg
	}
    }
    $s->rsegments_set (array_to_list_reverse \@s)
}
# (should have those functions without the Path wrapper? Maybe, maybe not.)


# XX is only valid to be applied to paths that have already been
# `clean_dot`ed !
sub xclean_dotdot {
    my $s=shift;
    if (my ($v)= $s->perhaps_clean_dotdot) {
	$v
    } else {
	die "can't take '..' of root directory"
    }
}


sub perhaps_clean {
    my $s=shift;
    $s->clean_dot->perhaps_clean_dotdot
}

sub xclean {
    my $s=shift;
    $s->clean_dot->xclean_dotdot
}


sub add_segment { # functionally. hm.
    my $s=shift;
    my ($segment)=@_;
    die "segment contains slash: '$segment'"
      if $segment=~ m{/};
    $s->rsegments_update
      (sub {
	   cons $segment, $_[0]
       })
	# no forced endslash anymore
	->has_endslash_set(0);
}

sub add {
    my $a=shift;
    @_==2 or die "wrong number of arguments";
    my ($b, $is_url)=@_; # when is_url is true, it cleans dit
    if ($b->is_absolute) {
	$b
    } else {
	my $c= $a->rsegments_set ($b->rsegments->append($a->rsegments))
	  ->clean_dot;
	$is_url ? $c->xclean_dotdot : $c
    }
}

sub dirname {
    my $s=shift;
    is_null $$s{rsegments}
      and die "can't take dirname of empty path";
    $s->rsegments_update(*cdr)
      ->has_endslash_set(1);
}

sub to_relative {
    my $s=shift;
    die "is already relative"
      unless $s->is_absolute;
    # keep has_endslash, # XX hm always? what about the dropping of first entry?
    $s->is_absolute_set(0);
}

sub contains_dotdot {
    my $s=shift;
    $s->rsegments->any(sub { $_[0] eq ".." })
}


# These are used as helpers for Chj::Path::Filesystem's touched_paths

sub perhaps_split_first_segment {
    @_==1 or die "wrong number of arguments";
    my ($p)= @_;
    perhaps_resplit_next_segment ($p->rsegments_set(null), $p)
}

# XX the reversing makes this O(n). Use a better list representation.

sub perhaps_resplit_next_segment {
    @_==2 or die "wrong number of arguments";
    my ($p0,$p1)= @_;
    my $ss= $p1->segments;
    if (is_pair $ss) {
	my $class= ref ($p0);
	my $remainder= $ss->rest->reverse;
	($class->new ($p0->rsegments->cons ($ss->first),
		      is_null($remainder) ? $p1->has_endslash : 1,
		      $p1->is_absolute),
	 $class->new ($remainder,
		      $p1->has_endslash,
		      ''))
    } else {
	()
    }
}




_END_

