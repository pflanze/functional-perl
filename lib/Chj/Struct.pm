#
# Copyright 2013 by Christian Jaeger, ch at christianjaeger ch
# This is free software, offered under the terms of the MIT License.
# See the file COPYING that came bundled with this file.
#

=head1 NAME

Chj::Struct

=head1 SYNOPSIS

 sub hashP {ref ($_[0]) eq "HASH"}

 use Chj::Struct Bar=> ["a", [\&hashP, "b"]]=> ["Foo"];
 # creates a constructor new that takes positional arguments and
 # copies them to a hash with the keys "a" and "b". Also, sets
 # @Bar::ISA to ("Foo"). [ ] around "Foo" are optional.
 # If a field is specified as an array then the first entry is a
 # predicate that receives the value in question, if it doesn't return
 # true then an exception is thrown.
 {
   package Bar;
   # instead of use Chj::Struct Bar.. above, could use this:
   # use Chj::Struct ["a","b"]=> ["Foo"];
   sub sum {
      my $s=shift;
      $$s{a} + $$s{b}
   }
   _END_ # generate accessors for methods of given name which don't
         # exist yet *in either Bar or any super class*. (Does that
         # make sense?)
 }
 new Bar (1,2)-> sum #=> 3
 new_ Bar (a=>1,b=>2)-> sum # dito

=head1 DESCRIPTION

Simpler than Class::Struct. Ok?

_END_ does namespace cleaning: any sub that was defined before the use
Chj::Struct call is removed by the _END_ call (those that are not the
same sub ref anymore, i.e. have been redefined, are left
unchanged). This means that if the 'use Chj::Struct' statement is put
after any other (procedure-importing) 'use' statement, but before the
definition of the methods, that the imported procedures can be used
from within the defined methods, but are not around afterwards,
i.e. they will not shadow super class methods. (Thanks to Matt S Trout
for pointing out the idea.) To avoid the namespace cleaning, write
_END__ instead of _END_.

See Chj::FP::Predicates for some useful predicates.

=cut


package Chj::Struct;

use strict;
use Carp;


sub package_keys {
    my ($package)=@_;
    no strict 'refs';
    [
     map {
	 if (my $c= *{"${package}::$_"}{CODE}) {
	     [$_, $c]
	 } else {
	     ()
	 }
     }
     keys %{$package."::"}
    ]
}

sub package_delete {
    my ($package,$keys)=@_;
    #warn "package_delete '$package'";
    no strict 'refs';
    for (@$keys) {
	my ($key,$val)= @$_;
	no warnings 'once';
	my $val2= *{"${package}::$key"}{CODE};
	# check val to be equal so that it will work with Chj::ruse
        if ($val2 and $val == $val2) {
	    #warn "deleting ${package}::$key ($val)";
	    delete ${$package."::"}{$key};
	}
    }
}

# sub package_wipe {
#     my ($package)=@_;
#     package_delete $package, package_keys $package
# }

sub require_package {
    my ($package)=@_;
    no strict 'refs';
    if (not keys %{$package."::"}) {
	$package=~ s|::|/|g;
	$package.=".pm";
	require $package
    }
}

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


sub Show ($) {
    my ($v)=@_;
    defined $v ? (ref $v ? $v : ($v=~ s/'/\\'/sg, "'$v'")) : "undef"
}


sub import {
    my $_importpackage= shift;
    return unless @_;
    my ($package, $fields, @isa);
    if (ref $_[0]) {
	($fields, @isa)= @_;
	$package= caller;
    } else {
	($package, $fields, @isa)= @_;
    }
    no strict 'refs';
    if (@isa) {
	require_package $_ for @isa;
	*{"${package}::ISA"}= (@isa==1 and ref($isa[0])) ? $isa[0] : \@isa;
    }
    my $allfields=[ all_fields (\@isa), @$fields ];
    # (^ ah, could store them in the package as well; but well, no
    # worries)
    my $allfields_name= [map {field_name $_} @$allfields];

    # get list of package entries *before* setting
    # accessors/constructors
    my $nonmethods= package_keys $package;

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
	      or die "unacceptable value for field '$name': ".Show($_[$i]);
	}
	my %s;
	for (my $i=0; $i< @_; $i++) {
	    $s{ $$allfields_name[$i] }= $_[$i];
	}
	bless \%s, $class
    };

    # constructor with keyword/value parameters:
    my $allfields_h= +{ map { field_name($_)=> undef } @$allfields };
    my $allfields_with_predicate= [grep { field_maybe_predicate $_ } @$allfields];
    *{"${package}::new_"}= sub {
	my $class=shift;
	@_ <= (@$allfields * 2)
	  or croak "too many arguments to ${package}::new_";
	my %s=@_;
	for (keys %s) {
	    exists $$allfields_h{$_} or die "unknown field '$_'";
	}
	for (@$allfields_with_predicate) {
	    my ($pred,$name)=@$_;
	    &$pred ($s{$name})
	      or die "unacceptable value for field '$name': ".Show($s{$name});
	}
	bless \%s, $class
    };

    my $end= sub {
	#warn "_END_ called for package '$package'";
	for my $_field (@$fields) {
	    my ($maybe_predicate,$name)= field_maybe_predicate_and_name $_field;
	    # accessors
	    if (not $package->can($name)) {
		*{"${package}::$name"}= sub {
		    my $s=shift;
		    $$s{$name}
		};
	    }
	    # functional setters
	    my $name_set= $name."_set";
	    if (not $package->can($name_set)) {
		*{"${package}::$name_set"}=
		  ($maybe_predicate ?
		   sub {
		       my $s=shift;
		       @_==1 or die "$name_set: need 1 argument";
		       my $v=shift;
		       &$maybe_predicate($v)
			 or die "unacceptable value for field '$name': ".Show($v);
		       my $new= +{%$s};
		       ($$new{$name})=@_;
		       bless $new, ref $s
		   }
		   :
		   sub {
		       my $s=shift;
		       @_==1 or die "$name_set: need 1 argument";
		       my $new= +{%$s};
		       ($$new{$name})=@_;
		       bless $new, ref $s
		   });
	    }
	}
	1 # make module load succeed at the same time.
    };
    *{"${package}::_END__"}= $end;
    *{"${package}::_END_"}= sub {
	#warn "_END_ called for package '$package'";
	package_delete $package, $nonmethods;
	&$end;
    };

    *{"${package}::__Struct__fields"}= $fields;
}


1
