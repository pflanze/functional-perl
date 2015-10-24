#
# Copyright (c) 2015 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FP::Show - give (nice) code representation for debugging purposes

=head1 SYNOPSIS

 use FP::Show; # exports 'show'
 use FP::List;

 sub foo {
     my ($l)=@_;
     die "not what we wanted: ".show ($l)
       unless ref ($l) eq "ARRAY";
 }

 foo list 100-1, "bottles";
   # -> dies with: not what we wanted: list(99, 'bottles')
 foo "list(99, 'bottles')" ;
   # -> dies with: not what we wanted: 'list(99, \'bottles\')'


=head1 DESCRIPTION

Unlike Data::Dumper, this allows classes to provide a 'FP_Show_show'
method that gets a function it can itself recursively call on
contained values, and that must return the string representation.

Data::Dumper *does* have a similar feature, $Data::Dumper::Freezer,
but it needs the object to be mutated, which is not what one will
want.

Why not use string overloading instead? Because '""' overloading is
returning 'plain' strings, not perl code (or so it seems, is there any
spec that defines exactly what it means?) Code couldn't know whether
to quote the result:

 sub foo2 {
     my ($l)=@_;
     die "not what we wanted: $l"
       unless ref ($l) eq "ARRAY";
 }

 foo2 list 100-1, "bottles";
   # would die with: not what we wanted: list(99, 'bottles')
 foo2 "list(99, 'bottles')" ;
   # would die with: not what we wanted: list(99, 'bottles')
 # so how would you tell which value foo2 really got in each case,
 # just from looking at the message?

 # also:
 foo2 +{a=> 1, b=>10};
   # would die with something like:
   #   not what we wanted: HASH(0xEADBEEF)
   # which isn't very informative

Embedding pointer values in the output also means that it can't be
used for automatic testing. (Even with a future implementation of
cut-offs, values returned by `show` will be good enough when what one
needs to do is compare against a short representation. Also, likely we
would implement the cut-off value as an optional parameter.)


=head1 TODO

- cycle detection

- cut-offs at configurable size?

- modify Data::Dumper to allow for custom formatting instead?

- should the 'FP_Show_show' methods simply be called 'show'? Or
  '(show' and provide help for their installation like overload.pm?
  (Gain consistency with FP::Equals.) Although, there is a reason not
  to do that: unlike `equals`, the `show` method would not be usable
  directly, as it follows a private API. Offer a mix-in that *does*
  offer a `show` method that works without giving further arguments?
  But then, like with equals, it's not safe in the general case where
  the object argument might not be an object or have the method. Users
  should really import and use the show and equals functions.

- should `show` try to never use multiple lines, or to do
  pretty-printing?

- should constructor names be fully qualified? Any other idea to avoid
  this verbosity but still be unambiguous?

- make it good enough to be used by Chj::repl by default for the
  printing.


=head1 SEE ALSO

L<FP::Equals>

=cut


package FP::Show;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(show);
@EXPORT_OK=qw();
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use Chj::TerseDumper qw(terseDumper);

sub keyshow ($) {
    my ($str)=@_;
    ($str=~ /^\w+$/s
     and
     # make sure it's not just an integer, as that would not be quoted
     # by perl and if big enough yield something different than the
     # string
     $str=~ /[a-zA-Z]/s
    ) ? $str : terseDumper($str)
}

our $primitive_show=
  +{
    ARRAY=> sub {
	my ($v,$show)=@_;
	"[".join(", ",
		 map { &$show ($_) } @$v)."]";
    },
    HASH=> sub {
	my ($v,$show)=@_;
	"+{".join(", ",
		 map { keyshow($_)." => ".&$show ($$v{$_}) }
		 keys %$v)."}";
    },
    REF=> sub { # references to references
	my ($v,$show)=@_;
	"\\(".&$show ($$v).")"
    },
    # *references* to globs; direct globs are compared in equals2 directly
    GLOB=> sub {
	my ($v,$show)=@_;
	terseDumper($v)
    },
    SCALAR=> sub {
	my ($v,$show)=@_;
	terseDumper($v)
    },
    CODE=> sub {
	my ($v,$show)=@_;
	# XX something better?
	terseDumper($v)
    },
    # Don't really have any sensible serialization for these either,
    # but at least prevent them from hitting Data::Dumper which issues
    # warnings and returns invalid syntax in XS mode and gives plain
    # exceptions in useperl mode:
    IO=> sub {
	my ($v,$show)=@_;
	my $fileno= fileno($v) // "UNKNOWN";
	"IO($fileno)"
    },
    LVALUE=> sub {
	my ($v,$show)=@_;
	"LVALUE(UNKNOWN)"
    },
   };

use Scalar::Util qw(reftype);

sub show ($) {
    my ($v)=@_;
    if (length ref($v)) {
	if (my $m= UNIVERSAL::can ($v, "FP_Show_show")) {
	    &$m ($v,*show)
	} elsif ($m= $$primitive_show{ref $v}) {
	    &$m ($v,*show)
	} elsif ($m= $$primitive_show{reftype $v}) {
	    # blessed basic type
	    "bless(" . &$m($v,*show) . ", " . show(ref($v)) . ")"
	} else {
	    terseDumper($v)
	}
    } else {
	terseDumper($v)
    }
}


1
