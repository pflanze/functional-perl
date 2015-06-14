#
# Copyright 2013-2015 by Christian Jaeger, ch at christianjaeger ch
# Published under the same terms as perl itself
#

=head1 NAME

Chj::NamespaceClean

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SEE ALSO

L<Chj::NamespaceCleanAbove>, L<FP::Struct>

=cut


package Chj::NamespaceClean;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(package_keys package_delete);
@EXPORT_OK=qw();
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict; use warnings FATAL => 'uninitialized';


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


1
