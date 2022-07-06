#
# Copyright (c) 2021-2022 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FP::JSON

=head1 SYNOPSIS

    use FP::JSON qw(to_json);

    my $settings = {
        output_format => "JSON", # or "Mint"
        auto_numbers  => 1,
        auto_integers => 0,
        # converter => sub ($obj) { ... convert to accepted data .. },
        # pretty => 1, # extra re-parsing step at the end
    };

    use FP::List;
    is to_json([10, list(20,30), {40=> "foo", bar=> 50}], $settings),
       '[
    10,
    [
    20,
    30
    ],
    {
    _40: "foo",
    bar: 50
    }
    ]';

    $settings->{pretty} = 1;
    is to_json([10, list(20,30), {40=> "foo", bar=> 50}], $settings),
       '[
      10,
      [
        20,
        30
       ],
       {
         "40": "foo",
         "bar": 50
       }
    ]';

=head1 DESCRIPTION

Currently just provides `to_json` to turn some kinds of data into a
JSON or Mint language string. This module will need some work for more
serious use.

This somewhat consciously is not implemented as a class--nonetheless,
the $settings argument to `to_json` is basically $self. Still, isn't
it neat how few changes one needs to do from procedural code this way
(Ok, all 3 functions now take the settings, though), and there's no
need to use a constructor, just bare "data", which is quite en vogue
(again) today (e.g. in Clojure, Elixir).

=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut

package FP::JSON;
use strict;
use warnings;
use warnings FATAL => 'uninitialized';
use experimental 'signatures';
use Exporter "import";

our @EXPORT      = qw();
our @EXPORT_OK   = qw(to_json);
our %EXPORT_TAGS = (all => [@EXPORT, @EXPORT_OK]);

use JSON ();
use Scalar::Util qw(looks_like_number);
use Scalar::Util qw(blessed);
use FP::PureArray qw(purearray array_to_purearray);
use Chj::TEST;
use FP::Show;

sub fieldname_to_json($str) {
    '"' . $str . '"'    # XXXX
}

sub fieldname_to_mint($str) {
    my $s = lcfirst($str);
    $s =~ s/^\s+//;
    $s =~ s/\s+\z//;
    $s =~ s/[^\w\d_]/_/sg;    # XX would mint support e.g. "-" ?
    if ($s =~ m/^\d/) {
        $s = "_$s";           # prepend an underscore if fieldname starts with a
                              # digit; XX needed?
    }
}

TEST { fieldname_to_mint "Quadrat 'o'Hara" } 'quadrat__o_Hara';

our $output_formats = {
    JSON =>
        { hashmap_pair_op => ": ", fieldname_convert => \&fieldname_to_json, },
    Mint =>
        { hashmap_pair_op => " = ", fieldname_convert => \&fieldname_to_mint, },
};

my $json = JSON->new->allow_nonref;

sub scalar_to_json ($val, $settings) {
    if ($settings->{auto_numbers} and looks_like_number $val) {

        # XX *assumes* that mint has the same number syntax as Perl
        $val =~ s/\.0*\z// if $settings->{auto_integers};
        $val
    } else {

        # XX mint may *not* use all of the same syntax as JSON. For
        # now assume it does:
        $json->encode($val)
    }
}

TEST {
    my $s = { auto_numbers => 0, auto_integers => 0 };
    scalar_to_json "152.00", $s
}
"\"152.00\"";
TEST {
    my $s = { auto_numbers => 1, auto_integers => 0 };
    scalar_to_json "152.00", $s
}
"152.00";
TEST {
    my $s = { auto_numbers => 1, auto_integers => 1 };
    scalar_to_json "152.00", $s
}
"152";
TEST { scalar_to_json "foo bar", {} } "\"foo bar\"";

#run_tests __PACKAGE__

sub hashmap_to_json ($hashmap, $settings) {
    my $output_format     = $output_formats->{ $settings->{output_format} };
    my $fieldname_convert = $output_format->{fieldname_convert};
    my $hashmap_pair_op   = $output_format->{hashmap_pair_op};
    "{\n" . purearray(sort keys %$hashmap)->map(
        sub ($title) {
            my $value = $hashmap->{$title};
            $fieldname_convert->($title)
                . $hashmap_pair_op
                . _to_json($value, $settings)
        }
    )->strings_join(",\n")
        . "\n}"
}

sub sequence_to_json ($l, $settings) {
    "[\n"
        . $l->map(sub($v) { _to_json($v, $settings) })->strings_join(",\n")
        . "\n]"
}

sub _to_json ($value, $settings) {
    if (defined(my $class = blessed $value)) {
        if ($value->isa("FP::Abstract::Sequence")) {
            return sequence_to_json($value->purearray, $settings)
        } else {
            if (defined(my $c = $settings->{converter})) {
                return _to_json($c->($value), $settings)    # XX tail
            } else {
                die "to_json: don't know how to map this: " . show($value)
            }
        }
    } elsif (my $r = ref($value)) {
        if ($r eq "ARRAY") {
            return sequence_to_json(array_to_purearray($value), $settings)
        } elsif ($r eq "HASH") {
            return hashmap_to_json($value, $settings)
        }
    } else {
        return scalar_to_json($value, $settings)
    }
    die "bug"
}

sub to_json ($value, $settings) {
    if ($settings->{pretty}) {

        # Our non-pretty variant is sorted, thus enable canonical
        # here, too.
        my $json = JSON->new->allow_nonref->pretty->canonical;
        $json->encode($json->decode(_to_json($value, $settings)))
    } else {
        _to_json($value, $settings)
    }
}

1
