#
# Copyright 2013 by Christian Jaeger, ch at christianjaeger ch
# This is free software, offered under the terms of the MIT License.
# See the file COPYING that came bundled with this file.
#

=head1 NAME

Chj::Struct

=head1 SYNOPSIS

 use Chj::Struct Bar=> ["a","b"]=> ["Foo"];
 # creates a constructor new that takes positional arguments and
 # copies them to a hash with the keys "a" and "b". Also, sets
 # @Bar::ISA to ("Foo"). [ ] around "Foo" are optional.
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
    my $nonmethods= package_keys $package;
    *{"${package}::new"}= sub {
	my $class=shift;
	@_ <= @$fields
	  or croak "too many arguments to ${package}::new";
	my %s;
	for (my $i=0; $i< @_; $i++) {
	    $s{ $$fields[$i] }= $_[$i];
	}
	bless \%s, $class
    }
      if @$fields;
    my $end= sub {
	#warn "_END_ called for package '$package'";
	for my $field (@$fields) {
	    if (not $package->can($field)) {
		*{"${package}::$field"}= sub {
		    my $s=shift;
		    $$s{$field}
		};
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
}


1
