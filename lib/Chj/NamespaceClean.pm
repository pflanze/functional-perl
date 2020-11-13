#
# Copyright (c) 2013-2015 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

Chj::NamespaceClean

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SEE ALSO

L<Chj::NamespaceCleanAbove>, L<FP::Struct>

=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut

package Chj::NamespaceClean;
use strict;
use warnings;
use warnings FATAL => 'uninitialized';
use Exporter "import";

our @EXPORT      = qw(package_keys package_delete);
our @EXPORT_OK   = qw();
our %EXPORT_TAGS = (all => [@EXPORT, @EXPORT_OK]);

sub package_keys {
    my ($package) = @_;
    no strict 'refs';
    [
        map {
            if (my $c = *{"${package}::$_"}{CODE}) { [$_, $c] }
            else                                   { () }
        } keys %{ $package . "::" }
    ]
}

my @slotnames = qw(SCALAR HASH ARRAY IO);

sub package_delete {
    my ($package, $keys) = @_;

    #warn "package_delete '$package'";
    no strict 'refs';
    for (@$keys) {
        my ($key, $val) = @$_;
        no warnings 'once';
        my $val2 = *{"${package}::$key"}{CODE};

        # check val to be equal so that it will work with Chj::ruse
        if ($val2 and $val == $val2) {

            #warn "deleting ${package}::$key ($val)";
            my @v = map { *{"${package}::$key"}{$_} } @slotnames;
            delete ${ $package . "::" }{$key};
            for (@v) {
                *{"${package}::$key"} = $_ if defined $_
            }
        }
    }
}

# sub package_wipe {
#     my ($package) = @_;
#     package_delete $package, package_keys $package
# }

1
