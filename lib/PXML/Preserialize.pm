#
# Copyright (c) 2015-2019 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

PXML::Preserialize - faster PXML templating through preserialization

=head1 SYNOPSIS

    use PXML::Preserialize qw(pxmlfunc pxmlpre);
    use PXML::XHTML qw(A B);

    my $link_normal = sub {
        my ($href,$body)=@_;
        A {href=> $href}, $body
    };

    my $link_fast = pxmlfunc {
        my ($href,$body)=@_; # can take up to 10[?] arguments.
        A {href=> $href}, $body
    };

    # the `2` is the number of arguments
    my $link_fast2 = pxmlpre 2, $link_normal;

    # these expressions are all returning the same result, but the second
    # and third are (supposedly) evaluated faster than the first:
    is $link_normal->("http://foo", [B("Foo"), "Bar"])->string,
       '<a href="http://foo"><b>Foo</b>Bar</a>';
    is $link_fast->("http://foo", [B("Foo"), "Bar"])->string,
       '<a href="http://foo"><b>Foo</b>Bar</a>';
    is $link_fast2->("http://foo", [B("Foo"), "Bar"])->string,
       '<a href="http://foo"><b>Foo</b>Bar</a>';


=head1 DESCRIPTION

=for test ignore

PXML represents every XML/HTML element as an individual Perl object,
and both building up a PXML tree and serializing it is somewhat
costly.

And even if only a few strings change in a (sub)tree, a new tree
instance needs to be created and serialized for every set of those
strings.

This overhead can be eliminated by pre-serializing the segments of the
tree that don't change.

This module offers C<pxmlpre>, a function that takes a user supplied
function which maps some number of arguments to a PXML tree with those
arguments inserted, and returns a function that maps those same
arguments to an array with preserialized fragments and the (escaped)
argument values so that the PXML serialization functions don't have
any work to do except for printing the fragments and values.

With the example from the synopsis:

 &$link_normal("foo","bar")

returns a PXML element with name "a", a hash C<{href=> "foo"}> as
attributes, and "bar" as the body. C<<->string>> walks over the element
and hash and body and turns all parts into the proper XML syntax.

 &$link_fast2("foo","bar")

returns

 bless [ $fragment1, "foo", $fragment2, "$bar", $fragment3 ], "PXML::Body"

where $fragment1 is the string '<a href="' blessed to
C<PXML::Preserialize::Serialized>, which has a
C<pxml_serialized_body_string> method that returns the unmodified
string, which the serializer finds and calls (this is the currently
implemented way to add fragments to a PXML data structure and have the
serializer output them unescaped).

The fragments are built by running the user-supplied function with
trial arguments and then serializing the resulting tree, breaking up
the serialized string where the arguments are found, then returning a
closure that returns an array with both the constant pieces and new
arguments.

=head1 RESTRICTIONS

The user-supplied functions need to heed the following restrictions:

=over 4

=item * be pure

=item * must not contain branching (if/else etc.)

The arguments are not allowed to influence the structure of the
returned PXML tree, only the contents at the ever same spots.

=item * must insert the arguments into the result unmodified

The arguments, if they are used at all, must be inserted into the tree
unmodified. Even appending or prepending strings is not allowed (use a
wrapper array to put values before/after instead). To guard against
such errors, the argument values that are passed during the
preserialization step throw an error if they are stringified etc.

=back

Also, the values returned by C<pxmlpre>'d functions can not be
processed with e.g. functions in L<PXML::Util>, or at least those won't
find the elements in the parts that have been pre-serialized.

=head1 SEE ALSO

L<PXML>

=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut

package PXML::Preserialize;
use strict;
use warnings;
use warnings FATAL => 'uninitialized';
use Exporter "import";

our @EXPORT      = qw(pxmlpre pxmlfunc);
our @EXPORT_OK   = qw();
our %EXPORT_TAGS = (all => [@EXPORT, @EXPORT_OK]);


{

    package PXML::Preserialize::Serialized;

    sub new {
        my ($class, $str) = @_;
        bless \($str), $class
    }

    sub pxml_serialized_body_string {
        my $s = shift;
        $$s
    }
}

{

    package PXML::Preserialize::Argument;
    use FP::Struct ["effecter", "n"], 'FP::Struct::Show', 'FP::Abstract::Pure';

    # Prevent erroneous usage:
    use overload (
        '""' => 'err',
        '0+' => 'err',

        #'+' => 'err',
        fallback => 1    # necessary not to have to provide + etc.
    );

    sub err {
        die "tried to access a " . __PACKAGE__ . " object"
    }

    # Called when used correctly:
    sub pxml_serialized_body_string {
        my $self = shift;
        my ($fh) = @_;
        flush $fh or die $!;
        $self->effecter->(0, $self->n);
        ""
    }

    sub pxml_serialized_attribute_string {
        my $self = shift;
        my ($fh) = @_;
        flush $fh or die $!;
        $self->effecter->(1, $self->n);
        ""
    }
    _END_
}

use PXML::Serialize qw(pxml_print_fragment_fast attribute_escape);
use PXML qw(pxmlbody pxmlflush);
use FP::Div qw(max);

# passes $fn $nargs arguments that it will use during serialization to
# cut apart the serialized representation.
sub _pxmlpre ($$) {
    my ($nargs, $fn) = @_;

    my @items;
    my $buf   = "";
    my $lasti = 0;

    my $effecter = sub {
        my ($is_attribute, $n) = @_;

        # let $buf grow unimpeded (setting it to "" here seems to mess
        # up perl: string is regrown to previous size, but shows
        # what's probably uninitialized memory, heh!)
        push @items, PXML::Preserialize::Serialized->new(substr $buf, $lasti)
            if $lasti < length $buf;
        push @items, [$is_attribute, $n];
        $lasti = length $buf;
    };

    my @args = map { PXML::Preserialize::Argument->new($effecter, $_) }
        0 .. $nargs - 1;

    my $res = &$fn(@args);

    open my $out, ">", \$buf or die $!;

    pxml_print_fragment_fast($res, $out);

    close $out or die $!;
    push @items, PXML::Preserialize::Serialized->new(substr $buf, $lasti)
        if $lasti < length $buf;

    \@items
}

sub build {
    my ($nargs, $items) = @_;

    # return interpreter(?), not compilate (to avoid eval (overhead?))
    sub {
        @_ == $nargs or die "expecting $nargs argument(s), got " . @_;
        pxmlbody(
            map {
                ref($_) eq "ARRAY"
                    ? do {
                    my ($is_attribute, $i) = @$_;
                    $is_attribute
                        ? PXML::Preserialize::Serialized
                        ->new(attribute_escape($_[$i]))

                        # otherwise let the default escaper in the
                        # serializer do it (this *should* always be in
                        # body context, XXX danger?)
                        : $_[$i];
                    }
                    : $_;
            } @$items
        )
    }
}

sub pxmlpre ($$) {
    my ($nargs, $fn) = @_;
    build($nargs, _pxmlpre($nargs, $fn))
}

our $maxargs = 10;

sub pxmlfunc (&) {
    my ($fn) = @_;
    my $items = _pxmlpre($maxargs, $fn);
    my $nargs
        = (max(map { $$_[1] } grep { ref($_) eq "ARRAY" } @$items) // -1) + 1;
    build $nargs, $items
}

1
