#
# Copyright (c) 2015 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FP::Show - turn any object to a string for debugging purposes

=head1 SYNOPSIS

 use FP::Show; # exports 'show'
 use FP::List;

 my $l= list 100-1, "bottles";
 die "not what we wanted: ".show ($l);
   # -> dies with "not what we wanted: list(99, 'bottles')"

=head1 DESCRIPTION

Unlike Data::Dumper, this allows classes to provide a 'FP_Show_show'
method that gets a function it can itself recursively call on
contained values, and that must return the string representation.

Data::Dumper *does* have a similar feature, $Data::Dumper::Freezer,
but it needs the object to be mutated, which is not what one will
want.

=head1 TODO

- cycle detection

- cut-offs at configurable size?

- modify Data::Dumper to allow for custom formatting instead?

- should the 'FP_Show_show' methods simply be called 'show'? Or
  '(show' and provide help for their installation like overload.pm? 
  (Gain consistency with FP::Equals.)

- should `show` try to never use multiple lines, or to do
  pretty-printing?

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
    }
   };


sub show ($) {
    my ($v)=@_;
    if (my $m= UNIVERSAL::can ($v, "FP_Show_show")) {
	&$m ($v,*show)
    } elsif ($m= $$primitive_show{ref $v}) {
	&$m ($v,*show)
    } else {
	terseDumper($v)
    }
}


1
