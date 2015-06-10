#
# Copyright 2014-2015 by Christian Jaeger, ch at christianjaeger ch
# Published under the same terms as perl itself
#

=head1 NAME

FP::Predicates

=head1 SYNOPSIS

 package Foo;
 use FP::Predicates;

 *is_age= both *is_natural0, sub { $_[0] < 130 };
 # ^ wrap in BEGIN {  } to employ namespace cleaning;
 # or assign to a scalar instead (my $is_age), of course;
 # or use an inline expression (second line below)

 use FP::Struct [[*is_string, "name"], [*is_age, "age"]];

 # use FP::Struct [[*is_string, "name"],
 #                 [both (*is_natural0, less_than 130), "age"]];

 _END_

=head1 DESCRIPTION

Useful as predicates for FP::Struct field definitions.

These are simple functions expecting one value and returning a
boolean. They are composable with `maybe`, `complement`, `either`,
`all_of`/`both`, which are combinator functions.

This is a functional approach to achieve the same aim as
`Moose::Util::TypeConstraints`, which basically uses a syntactical
sublanguage instead (implemented as a mix of functions and string
interpretation). It was written because it's way simpler. The drawback
is that (currently) there's no way to get a nice message string from
them to say why a match fails. Perhaps it would be possible to do so
using more introspection? (That would be nice because message
generation would be fully automatic and hence consistent.) Or,
alternatively, modifying the predicate and combinator functions to
compose messages themselves when they fail (still mostly automatic),
e.g. using message objects that are false.

=cut


package FP::Predicates;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(
	      is_string
	      is_nonnullstring
	      is_natural0
	      is_natural
	      is_even is_odd
	      is_boolean01
	      is_boolean
	      is_hash
	      is_array
	      is_procedure
	      is_class_name
	      is_instance_of

	      is_filehandle

	      is_filename

	      less_than
	      greater_than
	      less_equal
	      greater_equal

	      maybe
	      true
	      false
	      complement
	      either
	      all_of both
	 );
@EXPORT_OK=qw();
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict; use warnings; use warnings FATAL => 'uninitialized';
use Scalar::Util 'reftype';
use Chj::TEST;


sub is_string ($) {
    not ref ($_[0]) # relax?
}

sub is_nonnullstring ($) {
    not ref ($_[0]) # relax?
      and length $_[0]
}

sub is_natural0 ($) {
    not ref ($_[0]) # relax?
      and $_[0]=~ /^\d+\z/
}

sub is_natural ($) {
    not ref ($_[0]) # relax?
      and $_[0]=~ /^\d+\z/ and $_[0]
}

sub is_even ($) {
    ($_[0] & 1) == 0
}

sub is_odd ($) {
    ($_[0] & 1)
}

TEST { [map { is_even $_ } -3..3] }
  ['',1,'',1,'',1,''];
TEST { [map { is_odd $_ } -3..3] }
  [1,0,1,0,1,0,1];
TEST { [map { is_even $_ } 3,3.1,4,4.1,-4.1] }
  # XX what should it give?
  ['','',1,1,1];


# no `is_` prefix as those are not the final predicates (they are not
# combinators either, as they take a number; well, they are curried
# forms of < and > etc.)

# names? (number versus string comparison) (wish Perl hat generics
# for those instead..)

sub less_than ($) {
    my ($x)=@_;
    sub ($) {
	$_[0] < $x
    }
}

sub greater_than ($) {
    my ($x)=@_;
    sub ($) {
	$_[0] > $x
    }
}

sub less_equal ($) {
    my ($x)=@_;
    sub ($) {
	$_[0] <= $x
    }
}

sub greater_equal ($) {
    my ($x)=@_;
    sub ($) {
	$_[0] >= $x
    }
}


# strictly 0 or 1
sub is_boolean01 ($) {
    not ref ($_[0]) # relax?
      and $_[0]=~ /^[01]\z/
}

# undef, 0, "", or 1
sub is_boolean ($) {
    not ref ($_[0]) # relax?
      and (! $_[0]
	   or
	   $_[0] eq "1");
}


sub is_hash ($) {
    defined $_[0] and ref ($_[0]) eq "HASH"
}

sub is_array ($) {
    defined $_[0] and ref ($_[0]) eq "ARRAY"
}

sub is_procedure ($) {
    defined $_[0] and ref ($_[0]) eq "CODE"
}


my $classpart_re= qr/\w+/;

sub is_class_name ($) {
    my ($v)= @_;
    not ref ($v) and $v=~ /^(?:${classpart_re}::)*$classpart_re\z/;
}

sub is_instance_of ($) {
    my ($cl)=@_;
    is_class_name $cl or die "need class name string, got: $cl";
    sub ($) {
	UNIVERSAL::isa ($_[0], $cl);
    }
}


sub is_filehandle ($) {
    my ($v)=@_;
    # NOTE: never returns true for strings, even though plain strings
    # naming globals containing filehandles in their IO slot will work
    # for IO, too! Let's just leave that depreciated and
    # 'non-working', ok?

    # NOTE 2: also this only returns true for *references* to globs,
    # not globs themselves (which could also be used as in
    # `(*STDOUT)->print( "Huh\n")`). Let's just leave bare globs as
    # buckets for any of the variable types perl has, and not assume
    # it's meant to be a filehandle, ok? (Or is that inconsistent with
    # treating `\*STDOUT` as filehandle? But there's no way around
    # this one, as that's what `open my $out, ..` gives, and we do
    # check that the IO slot is actually set in this case.)

    my $r= ref ($v);
    $r and
      $r eq "GLOB" ? (*{$v}{IO} ? 1 : '') # explicitely return ''
                                          # instead of undef
	: (reftype($v) eq "IO");
}

TEST {[ map { is_filehandle $_ }
	"STDOUT", undef,
	*STDOUT, *STDOUT{IO}, \*STDOUT,
	*SMK69GXDB, *SMK69GXDB{IO}, \*SMK69GXDB ]}
  ['', '',
   '', 1, 1,
   '', '', ''];


# should probably be in a filesystem lib instead?
sub is_filename ($) {
    my ($v)=@_;
    (is_nonnullstring ($v)
     and !($v=~ m|/|)
     and !($v eq ".")
     and !($v eq ".."))
}

sub maybe ($) {
    my ($pred)=@_;
    sub ($) {
	my ($v)=@_;
	defined $v ? &$pred ($v) : 1
    }
}


sub true {
    1
}

sub false {
    0
}

sub complement ($) {
    my ($f)=@_;
    sub {
	! &$f(@_)
    }
}

TEST {
    my $t= complement (\&is_natural);
    [map { &$t($_) } (-1,0,1,2,"foo")]
} [1,1,'','',1];


sub either {
    my (@fn)=@_;
    sub {
	for my $fn (@fn) {
	    my $v= &$fn;
	    return $v if $v;
	}
	0
    }
}

TEST {
    my $t= either \&is_natural, \&is_boolean;
    [map { &$t($_) } (-1,0,1,2,"foo")]
} [0,1,1,2,0];


sub all_of {
    my (@fn)=@_;
    sub {
	for my $fn (@fn) {
	    return undef unless &$fn;
	}
	1
    }
}

sub both ($$) {
    @_==2 or die "expecting 2 arguments";
    all_of (@_)
}


1
