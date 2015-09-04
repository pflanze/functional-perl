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

=head1 DESCRIPTION

Not really sure why I'm creating something from scratch here?

This doesn't do I/O (access the file system, ask the system for the
hostname, etc.), and it doesn't resolve ".." unless when told to
(`perhaps_clean_dotdot` method).

=cut


package FP::Path;

use strict;

use FP::List ":all";
use FP::Equals ();

use FP::Struct
  [
   'rsegments', # reverse FP::List::List of str not containing slashes
   'has_endslash', # bool, whether the path is forcibly specifying a
                   # dir by using a slash at the end (forcing a dir by
                   # ending in "." isn't setting this flag)
   'is_absolute', # bool
  ];


sub new_from_string {
    my $cl=shift;
    my ($str)=@_;
    my @p= split m{/+}, $str;
    # We want a split that drops superfluous empty strings at the end,
    # but not the start ('/' case). This is not it (and passing -1 to
    # split isn't it either), so we need to handle this case manually:
    @p= ('') if (!@p and $str=~ m{^/+$}s);
    $cl->new(array_to_list_reverse(\@p),
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

sub string_without_endslash {
    my $s=shift;
    $s->rsegments->strings_join_reverse("/")
}

sub string {
    my $s=shift;
    my $str= $s->string_without_endslash;
    if ($s->has_endslash) {
	if (length $str) {
	    $str."/"
	} else {
	    if ($s->is_absolute) {
		"/"
	    } else {
		# force using ".", XX hmm but yes no other way
		"./"
	    }
	}
    } else {
	if (length $str) {
	    $str
	} else {
	    # PS. if I would split ..,1, then I could do away with
	    # this test (and also some others), right?
	    if ($s->is_absolute) {
		"/"
	    } else {
		"."
	    }
	}
    }
}

# remove "." entries: (leave ".." in, because these cannot be resolved
# without reading the file system or knowing the usage)
sub clean {
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
# `clean`ed !
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
# `clean`ed !
sub xclean_dotdot {
    my $s=shift;
    if (my ($v)= $s->perhaps_clean_dotdot) {
	$v
    } else {
	die "can't take '..' of root directory"
    }
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
	  ->clean;
	$is_url ? $c->xclean_dotdot : $c
    }
}

sub dirname {
    my $s=shift;
    is_null $$s{rsegments}
      and die "can't take dirname of empty path";
    $s->rsegments_update(*cdr)
      ->has_endslash_set(0);
}

sub to_relative {
    my $s=shift;
    die "is already relative"
      unless $s->is_absolute;
    $s->rsegments_update(*drop_last)
      # keep has_endslash, # XX hm always? what about the dropping of first entry?
      # not absolute
      ->is_absolute_set(0);
}

sub contains_dotdot {
    my $s=shift;
    $s->rsegments->any(sub { $_[0] eq ".." })
}


_END_

