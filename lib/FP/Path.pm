#
# Copyright (c) 2011-2019 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FP::Path

=head1 SYNOPSIS

    use FP::Equal;
    use FP::Path;

    my $p = FP::Path->new_from_string ("a/../b/C")
           ->add(FP::Path->new_from_string("../d/../e"), 0);
    is $p->string, 'a/../b/C/../d/../e';
    is $p->xclean->string, 'b/e';
    ok not equal($p->xclean, $p);
    ok equal($p->xclean, $p->xclean); # obviously, assuming purity

    # or use the (evil?) constructor function export feature:
    use FP::Path "path";
    is path("a/../b/C")->xclean->string, "b/C";

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

Implements: L<FP::Abstract::Show>, L<FP::Abstract::Pure>

L<FP::Path::t> for the test suite

=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut

package FP::Path;

use strict;
use warnings;
use warnings FATAL => 'uninitialized';

use FP::List ":all";
use Chj::constructorexporter;
use FP::Predicates qw(is_string is_boolean);
use FP::Show;
use FP::Equal;

sub perhaps_segment_error ($) {
    my ($segment) = @_;
    return "segments must be strings" unless is_string $segment;
    return "segments cannot be the empty string" unless length $segment;
    return "segment contains slash: " . show($segment) if $segment =~ m{/};
    ()
}

sub is_segment ($) { not perhaps_segment_error $_[0] }

sub check_segment ($) {
    if (my ($e) = perhaps_segment_error $_[0]) {
        die $e
    }
}

# Toggle typing, off for speed (checking FP::List costs O(length);
# better use FP::StrictList if really interested in strict typing!)
sub use_costly_typing () {0}
our $use_costly_typing = use_costly_typing;    # for access from FP::Path::t

sub typed ($$) {
    my ($pred, $name) = @_;
    if (use_costly_typing) { [$pred, $name] }
    else {
        $name
    }
}

use FP::Struct [
    typed(list_of(*is_segment), 'rsegments'),     # reversed list
    typed(*is_boolean,          'has_endslash')
    ,    # whether the path is forcibly specifying a
         # dir by using a slash at the end (forcing a
         # dir by ending in "." isn't setting this
         # flag)
    typed(*is_boolean, 'is_absolute'),    # bool
    ],
    'FP::Struct::Show',
    'FP::Abstract::Equal',
    'FP::Abstract::Pure';

*import = constructorexporter new_from_string => "path";

sub new_from_string {
    @_ == 2 or die "wrong number of arguments";
    my ($class, $str) = @_;
    my @p = split m{/+}, $str;
    shift @p if (@p and $p[0] eq "");
    $class->new(
        array_to_list_reverse(\@p),
        scalar $str =~ m{/$}s,
        scalar $str =~ m{^/}s
    )
}

sub FP_Equal_equal {
    @_ == 2 or die "wrong number of arguments";
    my ($a, $b) = @_;

    # no need to compare is_absolute, since it is being distinguished
    # anyway? Or better be safe than sorry?
    (           (!!$a->is_absolute eq !!$b->is_absolute)
            and (!!$a->has_endslash eq !!$b->has_endslash)
            and equal($a->rsegments, $b->rsegments))
}

sub segments {
    my $s = shift;
    $s->rsegments->reverse
}

sub string {
    my $s  = shift;
    my $rs = $s->rsegments;

    # check that no invalid segments have creeped in (by way of using
    # the "lowlevel" accessors like segments_set, or the new or new_
    # constructors directly; adding a type check to the segments field
    # would solve this, but is less efficient as it would have to walk
    # the list on every change instead of only stringification):
    $rs->for_each(*check_segment);

    # force "." for empty relative paths:
    my $rs1 = is_null($rs) && not($s->is_absolute) ? list(".") : $rs;

    # add end slash
    my $ss = ($s->has_endslash ? $rs1->cons("") : $rs1)->reverse;

    # add start slash
    ($s->is_absolute ? $ss->cons("") : $ss)->strings_join("/")
}

# remove "." entries: (leave ".." in, because these cannot be resolved
# without reading the file system or knowing the usage)
sub clean_dot {
    my $s    = shift;
    my $rseg = $s->rsegments;
    $s->rsegments_set($rseg->filter(sub { not($_[0] eq ".") }))
        ->has_endslash_set(

        # set forced dir flag if the last segment was a ".", even
        # if previously it didn't end in "/"
        $$s{has_endslash} or do {
            if (is_null $rseg) {
                0
            } else {
                $rseg->first eq "."
            }
        }
        );
}

# This is only valid to be applied to paths that have already been
# `clean_dot`ed !
sub perhaps_clean_dotdot {
    my $s = shift;

    # XX this might actually be more efficient when working on the reverse
    # order? But leaving old imperative algorithm for now.
    my $rs             = $s->rsegments;
    my $ends_in_dotdot = is_pair($rs) && $rs->first eq "..";
    my @s;
    for my $seg ($rs->reverse_values) {
        if ($seg eq "..") {
            if (@s) {
                pop @s;
            } else {
                return ()
            }
        } else {
            push @s, $seg
        }
    }
    my $s1 = $s->rsegments_set(array_to_list_reverse \@s);
    $ends_in_dotdot ? $s1->has_endslash_set(1) : $s1
}

# (should have those functions without the Path wrapper? Maybe, maybe not.)

# This is only valid to be applied to paths that have already been
# `clean_dot`ed !
sub xclean_dotdot {
    my $s = shift;
    if (my ($v) = $s->perhaps_clean_dotdot) {
        $v
    } else {
        die "can't take '..' of root directory"
    }
}

sub perhaps_clean {
    my $s = shift;
    $s->clean_dot->perhaps_clean_dotdot
}

sub xclean {
    my $s = shift;
    $s->clean_dot->xclean_dotdot
}

sub add_segment {    # functionally. hm.
    my $s = shift;
    my ($segment) = @_;
    check_segment $segment;
    $s->rsegments_update(
        sub {
            cons $segment, $_[0]
        }
        )

        # no forced endslash anymore
        ->has_endslash_set(0);
}

sub add {
    my $a = shift;
    @_ == 2 or die "wrong number of arguments";
    my ($b, $is_url) = @_;    # when is_url is true, it cleans dit
    if ($b->is_absolute) {
        $b
    } else {
        my $c = $a->rsegments_set($b->rsegments->append($a->rsegments))
            ->clean_dot;
        $is_url ? $c->xclean_dotdot : $c
    }
}

sub dirname {
    my $s = shift;
    is_null $$s{rsegments} and die "can't take dirname of empty path";
    $s->rsegments_update(*rest)->has_endslash_set(1);
}

sub to_relative {
    my $s = shift;
    die "is already relative" unless $s->is_absolute;

    # keep has_endslash, # XX hm always? what about the dropping of first entry?
    $s->is_absolute_set(0);
}

sub contains_dotdot {
    my $s = shift;
    $s->rsegments->any(sub { $_[0] eq ".." })
}

# These are used as helpers for Chj::Path::Filesystem's touched_paths

# split a path into two parts, one with the first segment and one with
# the rest
sub perhaps_split_first_segment {
    @_ == 1 or die "wrong number of arguments";
    my ($p) = @_;
    perhaps_resplit_next_segment($p->rsegments_set(null), $p)
}

# re-split two paths so that the first gains another segment from the
# second
sub perhaps_resplit_next_segment {
    @_ == 2 or die "wrong number of arguments";
    my ($p0, $p1) = @_;

    # XX the reversing makes this O(n). Use a better list
    # representation.
    my $ss = $p1->segments;
    if (is_pair $ss) {
        my $class = ref($p0);
        my ($first, $rest) = $ss->first_and_rest;
        (
            $class->new(
                $p0->rsegments->cons($first),
                is_null($rest) ? $p1->has_endslash : 1,
                $p0->is_absolute
            ),
            $class->new($rest->reverse, $p1->has_endslash, '')
        )
    } else {
        ()
    }
}

_END_

