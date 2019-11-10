#
# Copyright (c) 2013-2019 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FP::Struct - classes for functional perl

=head1 SYNOPSIS

 use FP::Predicates qw(is_array maybe);

 use FP::Struct Foo=>
         ["name",
          [maybe (\&is_array), "animals"]]
       # => "Baz", "Buzz" # optional superclasses
            ;

 # creates a constructor new that takes positional arguments and
 # copies them to a hash with the keys "name" and "animals". Also,
 # sets @Bar::ISA to ("Baz") if the '#' is removed. [ ] around "Baz"
 # are optional.  If an array is given as a field declaration, then
 # the first entry is a predicate that receives the value in question,
 # if it doesn't return true then an exception is thrown.

 new Foo ("Tim")->name # => "Tim"
 new Foo ("Tim", 0) # exception
 new Foo (undef, ["Struppi"])->animals->[0] # "Struppi"
 new_ Foo (animals=> ["Struppi"])->animals->[0] # "Struppi"


 # Usually preferred alternative: define the struct from within the
 # package:

 # a mixin package, if this weren't defined at the time of 'use
 # FP::Struct' below, it would try to load Hum.pm
 {
   package Hum;
   sub hum {
      my $s=shift;
      $s->name." hums ".$s->a." over ".$s->b
   }
 }
 {
   package Hah;
   use FP::Struct ["aa"];
   _END_
 }

 {
   package Bar;
   use Chj::TEST; # the TEST sub will be removed from the package upon
                  # _END_ (namespace cleaning)
   use FP::Struct ["a","b"]=> "Foo", "Hum", "Hah";
   sub div {
      my $s=shift;
      $$s{a} / $$s{b}
   }
   TEST { Bar->new_(a=> 1, b=> 2)->div } 1/2;
   _END_ # generate accessors for methods of given name which don't
         # exist yet *in either Bar or any super class*. (Does that
         # make sense?)
 }

 my $bar= new Bar ("Franz", ["Barney"], "some aa", 1,2);
 # same thing, but with sub instead of method call interface:
 my $baz= Bar::c::Bar ("Franz", ["Barney"], "some aa", 1,2);
 # or:
 import Bar::constructors;
 my $baz= Bar ("Franz", ["Barney"], "some aa", 1,2);

 $bar-> div # => 1/2

 new_ Bar (a=>1,b=>2)-> div # => 1/2
 Bar::c::Bar_ (a=>1, b=>2)->div # dito
 new__ Bar ({a=>1,b=>2})-> div # => 1/2
 unsafe_new__ Bar ({a=>1,b=>2})-> div # => 1/2
 # NOTE: unsafe_new__ returns the argument hash after checking and
 # blessing it, it doesn't copy it! Be careful. `new__` does copy it.

 $bar->b_set(3)->div # => 1/3

 use FP::Div 'inc';
 $bar->b_update(\&inc)->div # => 1/3

 $bar->hum # => "Franz hums 1 over 2"

=head1 DESCRIPTION

Create functional setters (i.e. setters that return a copy of the
object so as to leave the original unharmed), take predicate functions
(not magic strings) for dynamic type checking, simpler than
Class::Struct.

Also creates constructor methods: `new` that takes positional
arguments, `new_` which takes name=> value pairs, `new__` which takes
a hash with name=> value pairs as a single argument, and
`unsafe_new__` which does the same as `new__` but reuses the given
hash (unsafe if the latter is modified later on).

Also creates constructor functions (i.e. subroutine instead of method
calling interface) `Foo::Bar::c::Bar()` for positional and
`Foo::Bar::c::Bar_()` for named arguments for package Foo::Bar. These
are also in `Foo::Bar::constructors::` and can be imported using
(without arguments, it imports both):

    import Foo::Bar::constructors qw(Bar Bar_);

_END_ does namespace cleaning: any sub that was defined before the use
FP::Struct call is removed by the _END_ call (those that are not the
same sub ref anymore, i.e. have been redefined, are left
unchanged). This means that if the 'use FP::Struct' statement is put
after any other (procedure-importing) 'use' statement, but before the
definition of the methods, that the imported procedures can be used
from within the defined methods, but are not around afterwards,
i.e. they will not shadow super class methods. (Thanks to Matt S Trout
for pointing out the idea.) To avoid the namespace cleaning, write
_END__ instead of _END_.

See FP::Predicates for some useful predicates (others are in the
respective modules that define them, like `is_pair` in `FP::List`).

=head1 PURITY

FP::Struct uses `FP::Abstract::Pure` as default base class (i.e. when no other
base class is given). This means objects from classes based on
FP::Struct are automatically treated as pure by `is_pure` from
`FP::Predicates`.

To hold this promise true, your code must not mutate any object fields
except when it's impossible for the outside world to detect
(e.g. using a hash key to hold a cached result is fine as long as you
also override all the functional setters for fields that are used for
the calculation of the cached value to clean the cache (TODO: provide
option to turn off generation of setters, and/or provide hook (for
cloning?)).)

=head1 ALSO SEE

<FP::Show::Base::FP_Struct>

=cut


package FP::Struct;

use strict; use warnings; use warnings FATAL => 'uninitialized';
use Carp;
use Chj::NamespaceClean;
use FP::Show qw(show);
use FP::Interfaces qw(require_package
                      package_check_possible_interface);


sub all_fields {
    my ($isa)=@_;
    (
     map {
	 my ($package)=$_;
	 no strict 'refs';
	 if (my $fields= \@{"${package}::__Struct__fields"}) {
	     (
	      all_fields (\@{"${package}::ISA"}),
	      @$fields
	     )
	 } else {
	     () # don't even look at parent classes in that case, is
                # that reasonable?
	 }
     } @$isa
    )
}

sub field_maybe_predicate ($) {
    my ($s)=@_;
    (ref $s) ? $$s[0] : undef
}

sub field_name ($) {
    my ($s)=@_;
    (ref $s) ? $$s[1] : $s
}

sub field_maybe_predicate_and_name ($) {
    my ($s)=@_;
    (ref $s) ? @$s : (undef, $s)
}

sub field_has_predicate ($) {
    my ($s)=@_;
    ref $s
}


sub import {
    my $_importpackage= shift;
    return unless @_;
    my ($package, $is_expandedvariant, $fields, @perhaps_isa);
    if (ref $_[0]) {
	($fields, @perhaps_isa)= @_;
	$package= caller;
	$is_expandedvariant= 1;
    } else {
	($package, $fields, @perhaps_isa)= @_;
	$is_expandedvariant= 0;
    }
    my @isa= (@perhaps_isa==1 and ref($perhaps_isa[0])) ?
      $perhaps_isa[0]
	: @perhaps_isa;

    @isa= "FP::Abstract::Pure" unless @isa;
    require_package $_ for @isa;
    no strict 'refs';
    *{"${package}::ISA"}= \@isa;

    my $allfields=[ all_fields (\@isa), @$fields ];
    # (^ ah, could store them in the package as well; but well, no
    # worries)
    my $allfields_name= [map {field_name $_} @$allfields];

    # get list of package entries *before* setting
    # accessors/constructors
    my $nonmethods= package_keys $package;

    my @package_parts= split /::/, $package;
    my $package_lastpart= $package_parts[-1];

    # constructor with positional parameters:
    my $allfields_i_with_predicate= do {
	my $i=-1;
	[ map {
	    $i++;
	    if (my $pred= field_maybe_predicate $_) {
		[$pred, field_name ($_), $i]
	    } else {
		()
	    }
	} @$allfields ]
    };
    *{"${package}::new"}= sub {
	my $class=shift;
	@_ <= @$allfields
	  or croak "too many arguments to ${package}::new";
	for (@$allfields_i_with_predicate) {
	    my ($pred,$name,$i)=@$_;
	    &$pred ($_[$i])
	      or die "unacceptable value for field '$name': ".show($_[$i]);
	}
	my %s;
	for (my $i=0; $i< @_; $i++) {
	    $s{ $$allfields_name[$i] }= $_[$i];
	}
	bless \%s, $class
    };
    # XX bah, almost copy-paste, because want to avoid sub call
    # overhead (inlining please finally?):
    *{"${package}::c::${package_lastpart}"}= my $constructor= sub {
	@_ <= @$allfields
	  or croak "too many arguments to ${package}::new";
	for (@$allfields_i_with_predicate) {
	    my ($pred,$name,$i)=@$_;
	    &$pred ($_[$i])
	      or die "unacceptable value for field '$name': ".show($_[$i]);
	}
	my %s;
	for (my $i=0; $i< @_; $i++) {
	    $s{ $$allfields_name[$i] }= $_[$i];
	}
	bless \%s, $package
    };


    # constructor with keyword/value parameters:
    my $allfields_h= +{ map { field_name($_)=> undef } @$allfields };
    my $allfields_with_predicate= [grep { field_maybe_predicate $_ } @$allfields];
    *{"${package}::new_"}= sub {
	my $class=shift;
	$class->unsafe_new__(+{@_})
    };
    # XX mostly-copy-pasting again (like above):
    *{"${package}::c::${package_lastpart}_"}= my $constructor_= sub {
	$package->unsafe_new__(+{@_})
    };

    # constructor with hash parameter:
    *{"${package}::new__"}= sub {
	my $class=shift;
	@_==1 or croak "wrong number of arguments to ${package}::new__";
	my ($h)=@_;
	$class->unsafe_new__(+{%$h})
    },
    *{"${package}::unsafe_new__"}= sub {
	# NOTE: reuses (blesses) the argument hash! careful!
	my $class=shift;
	@_==1 or croak "wrong number of arguments to ${package}::unsafe_new__";
	my ($s)=@_;
	scalar (keys %$s) <= (@$allfields * 2)
	  or croak "too many arguments to ${package}::new_";
	for (keys %$s) {
	    exists $$allfields_h{$_} or die "unknown field '$_'";
	}
	for (@$allfields_with_predicate) {
	    my ($pred,$name)=@$_;
	    &$pred ($$s{$name})
	      or die "unacceptable value for field '$name': ".show($$s{$name});
	}
	bless $s, $class
    };

    # constructor exports: -- XX why did I decide to not use ::c:: for this? historic?
    *{"${package}::constructors::${package_lastpart}"}= $constructor;
    *{"${package}::constructors::${package_lastpart}_"}= $constructor_;
    *{"${package}::constructors::ISA"}= ["Exporter"];
    my $exports= [$package_lastpart, "${package_lastpart}_"];
    *{"${package}::constructors::EXPORT"}= $exports;
    *{"${package}::constructors::EXPORT_OK"}= [];
    *{"${package}::constructors::EXPORT_TAGS"}= +{all=> $exports};

    my $end= sub {
	#warn "_END_ called for package '$package'";
	for my $_field (@$fields) {
	    my ($maybe_predicate,$name)=
	      field_maybe_predicate_and_name $_field;

	    # accessors
	    if (not $package->can($name)) {
		*{"${package}::$name"}= sub {
		    my $s=shift;
		    $$s{$name}
		};
	    }

	    # functional modifiers
	    my $add_modifier= sub {
		my ($modifierappendix,$modifier)= @_;
		my $modifiername= "$name$modifierappendix";
		unless ($package->can($modifiername)) {
		    *{"${package}::$modifiername"}= $modifier;
		}
	    };

	    &$add_modifier
	      ("_set",
	       $maybe_predicate ?
	       sub {
		   my $s=shift;
		   @_==1 or die "${name}_set: need 1 argument";
		   my $v=shift;
		   &$maybe_predicate($v)
		     or die "unacceptable value for field '$name': "
		       .show($v);
		   my $new= +{%$s};
		   $$new{$name}= $v;
		   bless $new, ref $s
	       }
	       :
	       sub {
		   my $s=shift;
		   @_==1 or die "${name}_set: need 1 argument";
		   my $new= +{%$s};
		   ($$new{$name})=@_;
		   bless $new, ref $s
	       });

	    &$add_modifier
	      ("_update",
	       $maybe_predicate ?
	       sub {
		   @_==2 or die "${name}_update: need 1 argument";
		   my ($s,$fn)=@_;
		   my $v= &$fn ($s->{$name});
		   &$maybe_predicate($v)
		     or die "unacceptable value for field '$name': "
		       .show($v);
		   my $new= +{%$s};
		   $$new{$name}= $v;
		   bless $new, ref $s
	       }
	       :
	       sub {
		   @_==2 or die "${name}_update: need 1 argument";
		   my ($s,$fn)=@_;
		   my $v= &$fn ($s->{$name});
		   my $new= +{%$s};
		   ($$new{$name})= $v;
		   bless $new, ref $s
	       });
	}
	1 # make module load succeed at the same time.
    };
    *{"${package}::_END__"}= $end;
    *{"${package}::_END_"}= sub {
	#warn "_END_ called for package '$package'";
	package_delete $package, $nonmethods;
	&$end;
    };

    unless ($is_expandedvariant) {
	# Not expecting the user to write methods, finalize
	# immediately.
	&$end()
    }

    *{"${package}::__Struct__fields"}= $fields;


    # Check any interfaces:
    package_check_possible_interface($package, $_)
      for @isa;
}


1
