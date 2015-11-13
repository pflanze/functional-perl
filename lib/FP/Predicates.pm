#
# Copyright (c) 2014-2015 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
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
`all_of`/`both`.

This is a functional approach to achieve the same aim as
`Moose::Util::TypeConstraints`, which basically uses a syntactical
sublanguage instead (implemented as a mix of functions and string
interpretation). It was written because it's way simpler. The drawback
is that (currently) there's no way to get a nice message string from
them to say why a match fails. Perhaps it would be possible to do so
using more introspection? (That would be nice because message
generation would be fully automatic and hence consistent.) Or,
alternatively, modifying the functions to compose messages themselves
when they fail (still mostly automatic), e.g. using message objects
that are false.

=cut


package FP::Predicates;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(
	      is_pure
	      is_pure_object
	      is_pure_class
	      is_string
	      is_nonnullstring
	      is_natural0
	      is_natural
	      is_even is_odd
	      is_boolean01
	      is_booleanyesno
	      is_boolean
	      is_hash
	      is_array
	      is_procedure
	      is_class_name
	      instance_of
	      is_instance_of
	      is_subclass_of

	      is_filehandle

	      is_filename
	      is_sequence

	      less_than
	      greater_than
	      less_equal
	      greater_equal
	      is_zero

	      maybe
	      is_defined
	      is_true
	      true
	      is_false
	      false
	      complement
	      either
	      all_of both
	 );
@EXPORT_OK=qw(
		 is_coderef
	    );
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict; use warnings; use warnings FATAL => 'uninitialized';
use Chj::TEST;
use FP::Pure;
use Chj::BuiltinTypePredicates 'is_filehandle';
# ^ should probably move more lowlevel predicates there


# XX check for read-only flags?

# is_pure returns true for non-references, going with the assumption
# that the caller created a copy of those anyway, in which case there
# is no reason for fear from mutations from scopes before it got
# control of the value:
sub is_pure ($) {
    length (ref $_[0]) ? UNIVERSAL::isa ($_[0], "FP::Pure")
      : 1
}

sub is_pure_object ($) {
    length ref $_[0] and UNIVERSAL::isa ($_[0], "FP::Pure")
}

sub is_pure_class ($) {
    is_class_name $_[0] and UNIVERSAL::isa ($_[0], "FP::Pure")
}

sub is_string ($) {
    my ($v)=@_;
    (defined $v
     and not ref $v) # relax?
}

sub is_nonnullstring ($) {
    my ($v)=@_;
    (defined $v
     and not ref $v # relax?
     and length $v)
}

sub is_natural0 ($) {
    my ($v)=@_;
    (defined $v
     and not ref $v # relax?
     and $v=~ /^\d+\z/)
}

sub is_natural ($) {
    my ($v)=@_;
    (defined $v
     and not ref $v # relax?
     and $v=~ /^\d+\z/ and $v)
}

# XX careful these do not check for number types first

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


# no `is_` prefix as those are not the final predicates (they are
# curried forms of < and > etc.):

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

sub is_zero ($) {
    $_[0] == 0
}


# strictly 0 or 1
sub is_boolean01 ($) {
    not ref ($_[0]) # relax?
      and $_[0]=~ /^[01]\z/
}

sub is_booleanyesno ($) {
    my ($v)=@_;
    not ref $v
      and $v eq "yes" or $v eq "no"
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


# Usually you should prefer `is_procedure` (see below) over this, as
# we like to pass globs as subroutine place holders, too.

sub is_coderef ($) {
    defined $_[0] and ref ($_[0]) eq "CODE"
}

# Should this be called `is_subroutine` or `is_sub` instead, to cater
# for the traditional naming in Perl? But then Perl itself is
# inconsistent, too, calling those code refs, which matches the
# is_coderef naming above.

sub is_procedure ($) {
    defined $_[0] and
      (ref ($_[0]) eq "CODE"
       or
       (ref \($_[0]) eq "GLOB" ? *{$_[0]}{CODE} ? 1 : '' : ''))
	# XX: also check for objects that overload '&'?
}

TEST { is_procedure [] } '';
TEST { is_procedure \&is_procedure } 1;
TEST { is_procedure *is_procedure } 1;
TEST { is_procedure *fifu } '';


my $classpart_re= qr/\w+/;

sub is_class_name ($) {
    my ($v)= @_;
    ! length ref ($v) and $v=~ /^(?:${classpart_re}::)*$classpart_re\z/;
}

sub instance_of ($) {
    my ($cl)=@_;
    is_class_name $cl or die "need class name string, got: $cl";
    sub ($) {
	length ref $_[0] ? UNIVERSAL::isa ($_[0], $cl) : ''
    }
}

sub is_instance_of ($$) {
    my ($v,$cl)=@_;
    # is_class_name $cl or die "need class name string, got: $cl";
    length ref $v ? UNIVERSAL::isa ($v, $cl) : ''
}

sub is_subclass_of ($$) {
    my ($v,$cl)=@_;
    # is_class_name $cl or die "need class name string, got: $cl";
    !length ref $v and UNIVERSAL::isa ($v, $cl);
}

TEST { my $v= "IO"; is_instance_of $v, "IO" } '';
TEST { my $v= bless [], "IO"; is_instance_of $v, "IO" } 1;
TEST { my $v= "IO"; is_subclass_of $v, "IO" } 1;
TEST { require Chj::IO::File;
       is_subclass_of "Chj::IO::File", "IO" } 1;


# is_filename in Chj::BuiltinTypePredicates

TEST {[ map { is_filehandle $_ }
	"STDOUT", undef,
	*STDOUT, *STDOUT{IO}, \*STDOUT,
	*SMK69GXDB, *SMK69GXDB{IO}, \*SMK69GXDB,
	bless (\*WOFWEOXVV, "ReallyNotIO"),
	do { open my $in, $0 or die $!;
	     #warn "HM".<$in>;  # works
	     bless $in, "MightActullyBeIO" }
      ]}
  ['', '',
   '', 1, 1,
   '', '', '',
   '',
   1
  ];


# should probably be in a filesystem lib instead?
sub is_filename ($) {
    my ($v)=@_;
    (is_nonnullstring ($v)
     and !($v=~ m|/|)
     and !($v eq ".")
     and !($v eq ".."))
}

# can't be in `FP::Sequence` since that package is for OO, well, what
# to do about it?
use FP::Lazy; # sigh dependency, too.
sub is_sequence ($);
sub is_sequence ($) {
    length ref $_[0] ?
      (UNIVERSAL::isa($_[0], "FP::Sequence")
       or
       # XX evil: inlined `is_promise`
       UNIVERSAL::isa($_[0], "FP::Lazy::Promise")
       && is_sequence (force $_[0]))
	: '';
}


sub maybe ($) {
    @_==1 or die "wrong number of arguments";
    my ($pred)=@_;
    sub ($) {
	my ($v)=@_;
	defined $v ? &$pred ($v) : 1
    }
}


# (this would also be a candidate for FP::Ops)
sub is_defined ($) {
    defined $_[0]
}

sub is_true ($) {
    !!$_[0]
}

# (this would also be a candidate as 'not' with a different name for
# FP::Ops)
sub is_false ($) {
    @_==1 or die "wrong number of arguments";
    !$_[0]
}

sub true {
    1
}

sub false {
    0
}

sub complement ($) {
    @_==1 or die "wrong number of arguments";
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
	    return '' unless &$fn;
	}
	1
    }
}

sub both ($$) {
    @_==2 or die "expecting 2 arguments";
    all_of (@_)
}


1
