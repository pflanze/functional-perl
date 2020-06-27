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

    use FP::Struct 'FPStructExample::Foo'=>
            ["name", # accept any value
             [maybe (\&is_array), "animals"], # accept arrays or undef
            ]
            # => "Baz", "Buzz" # optional superclasses
             ;

    # creates a constructor new that takes positional arguments and
    # copies them to a hash with the keys "name" and "animals". Also,
    # sets @Bar::ISA to ("Baz", "Buzz") if the '#' is removed. [ ] around
    # "Baz", "Buzz" are optional.  If an array is given as a field
    # declaration, then the first entry is a predicate that receives the
    # value in question, if it doesn't return true then an exception is
    # thrown.

    is( new FPStructExample::Foo ("Tim")->name, "Tim" );
    eval {
         new FPStructExample::Foo ("Tim", 0)
    };
    like $@, qr/^unacceptable value for field 'animals': 0 /;
    is (new FPStructExample::Foo (undef, ["Struppi"])->animals->[0], "Struppi");
    is (new_ FPStructExample::Foo (animals=> ["Struppi"])->animals->[0], "Struppi");


    # Usually preferred alternative: define the struct from within the
    # package:

    # a mixin package, if this weren't defined at the time of 'use
    # FP::Struct' below, it would try to load Hum.pm
    package FPStructExample::Hum {
        sub hum {
            my $s=shift;
            $s->name." hums ".$s->a." over ".$s->b
        }
    }
    package FPStructExample::Hah {
        use FP::Struct ["aa"];
        _END_
    }

    package FPStructExample::Bar2 {

      use Chj::TEST; # the TEST sub will be removed from the package upon
                     # _END_ (namespace cleaning)
      use FP::Struct ["a","b"]=> "FPStructExample::Foo",
                                 "FPStructExample::Hum",
                                 "FPStructExample::Hah";
      sub div {
         my $s=shift;
         $$s{a} / $$s{b}
      }
      TEST { FPStructExample::Bar2->new_(a=> 1, b=> 2)->div } 1/2;
      _END_ # generate accessors for methods of given name which don't
            # exist yet *in either Bar or any super class*. (Does that
            # make sense?)
    }

    my $bar= new FPStructExample::Bar2 ("Franz", ["Barney"], "some aa", 1,2);
    # same thing, but with sub instead of method call interface:
    my $baz= FPStructExample::Bar2::c::Bar2 ("Franz", ["Barney"], "some aa", 1,2);
    # or:
    import FPStructExample::Bar2::constructors;
    my $baz= Bar2 ("Franz", ["Barney"], "some aa", 1,2);

    is $bar->div, 1/2;

    is(Bar2_(a=>1,b=>2)->div, 1/2);
    is(FPStructExample::Bar2::c::Bar2_(a=>1, b=>2)->div, 1/2);
    is(new__ FPStructExample::Bar2({a=>1,b=>2})->div, 1/2);
    is(unsafe_new__ FPStructExample::Bar2({a=>1,b=>2})->div, 1/2);
    # NOTE: unsafe_new__ returns the argument hash after checking and
    # blessing it, it doesn't copy it! Be careful. `new__` does copy it.

    is $bar->b_set(3)->div, 1/3;

    use FP::Div 'inc';
    is $bar->b_update(\&inc)->div, 1/3;

    is $bar->hum, "Franz hums 1 over 2";

    is Chj::TEST::run_tests("FPStructExample::Bar2")->success, 1;
    is (FPStructExample::Bar2->can("TEST"), undef);
    # ^ it was removed by namespace cleaning

=for test ignore

=head1 DESCRIPTION

Create functional setters (i.e. setters that return a copy of the
object so as to leave the original unharmed), take predicate functions
(not magic strings) for dynamic type checking, simpler than
Class::Struct.

Also creates constructor methods: C<new> that takes positional
arguments, C<new_> which takes name=> value pairs, C<new__> which takes
a hash with name=> value pairs as a single argument, and
C<unsafe_new__> which does the same as C<new__> but reuses the given
hash (unsafe if the latter is modified later on).

Also creates constructor functions (i.e. subroutine instead of method
calling interface) C<Foo::Bar::c::Bar()> for positional and
C<Foo::Bar::c::Bar_()> for named arguments for package Foo::Bar. These
are also in C<Foo::Bar::constructors::> and can be imported using
(without arguments, it imports both):

    import Foo::Bar::constructors qw(Bar Bar_);

C<_END_> does namespace cleaning: any sub that was defined before the C<use
FP::Struct> call is removed by the C<_END_> call (those that are not the
same sub ref anymore, i.e. have been redefined, are left
unchanged). This means that if the C<use FP::Struct> statement is put
after any other (procedure-importing) 'use' statement, but before the
definition of the methods, that the imported procedures can be used
from within the defined methods, but are not around afterwards,
i.e. they will not shadow super class methods. (Thanks to Matt S Trout
for pointing out the idea.) To avoid the namespace cleaning, write
C<_END__> instead of C<_END_>.

See L<FP::Predicates> for some useful predicates (others are in the
respective modules that define them, like C<is_pair> in L<FP::List>).

=head1 PURITY

It is recommended to use L<FP::Abstract::Pure> as a base class. This
means objects from classes based on FP::Struct are automatically
treated as pure by C<is_pure> from L<FP::Predicates>.

If C<$FP::Struct::immutable> is true (default), then if
L<FP::Abstract::Pure> is inherited the objects are made immutable to
ensure purity.

=head1 ALSO SEE

L<FP::Abstract::Pure>, <FP::Struct::Show>, <FP::Struct::Equal>

=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut


# XX todo: solve mutable private fields (which would leave those
#    mutable, but still allow to inherit Pure). Deal with these thoughts:
# "To hold this promise true, your code must not mutate any object fields
# except when it's impossible for the outside world to detect
# (e.g. using a hash key to hold a cached result is fine as long as you
# also override all the functional setters for fields that are used for
# the calculation of the cached value to clean the cache (TODO: provide
# option to turn off generation of setters, and/or provide hook (for
# cloning?)).)"



package FP::Struct;

use strict; use warnings; use warnings FATAL => 'uninitialized';
use Carp;
use Chj::NamespaceClean;
use FP::Show qw(show);
use FP::Interface qw(require_package package_check_possible_interface);


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
    # returns nothing at all if a predicate was given but is undef
    my ($s)=@_;
    (ref $s) ? (defined($$s[0]) ? @$s : ()) : (undef, $s)
}

sub field_has_predicate ($) {
    my ($s)=@_;
    ref $s
}


our $immutable= 1; # only used if also is_pure

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

    require_package $_ for @isa;
    no strict 'refs';
    *{"${package}::ISA"}= \@isa;

    my $is_pure= UNIVERSAL::isa($package, "FP::Abstract::Pure");

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
            my $fieldname= $$allfields_name[$i];
            $s{$fieldname}= $_[$i];
            Internals::SvREADONLY $s{$fieldname}, 1
                if $is_pure && $immutable;
        }
        my $s= bless \%s, $class;
        Internals::SvREADONLY %$s, 1
            if $is_pure && $immutable;
        $s
    };
    *{"${package}::c::${package_lastpart}"}= my $constructor= sub {
        # XX bah, almost copy-paste, because want to avoid sub call
        # overhead (inlining please finally?):
        @_ <= @$allfields
          or croak "too many arguments to ${package}::new";
        for (@$allfields_i_with_predicate) {
            my ($pred,$name,$i)=@$_;
            &$pred ($_[$i])
              or die "unacceptable value for field '$name': ".show($_[$i]);
        }
        my %s;
        for (my $i=0; $i< @_; $i++) {
            my $fieldname= $$allfields_name[$i];
            $s{$fieldname}= $_[$i];
            Internals::SvREADONLY $s{$fieldname}, 1
                if $is_pure && $immutable;
        }
        my $s= bless \%s, $package;
        Internals::SvREADONLY %$s, 1
            if $is_pure && $immutable;
        $s
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
            Internals::SvREADONLY $$s{$_}, 1
                if $is_pure && $immutable;
        }
        for (@$allfields_with_predicate) {
            my ($pred,$name)=@$_;
            &$pred ($$s{$name})
              or die "unacceptable value for field '$name': ".show($$s{$name});
        }
        bless $s, $class;
        Internals::SvREADONLY %$s, 1
            if $is_pure && $immutable;
        $s
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
                field_maybe_predicate_and_name($_field)
                or croak "type predicate given but undef (this can happen "
                ."due to phasing, e.g. referring to a lexical variable "
                ."defined in the same file) for field "
                .(defined($$_field[1]) ? "'$$_field[1]'" : "undef");

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

        # Check any interfaces:
        package_check_possible_interface($package, $_)
          for @isa;

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

}


1
