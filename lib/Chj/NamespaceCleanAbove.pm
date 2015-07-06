#
# Copyright 2015 by Christian Jaeger, copying@christianjaeger.ch
# Published under the same terms as perl itself
#

=head1 NAME

Chj::NamespaceCleanAbove

=head1 SYNOPSIS

 sub foo { }
 use Bar;
 use Chj::NamespaceCleanAbove; # imports `_END_`
 sub baz {
    bar foo
 }
 _END_; # deletes `foo` and everything imported by `Bar`, but still lets
        # `baz` access them.

=head1 DESCRIPTION

=head1 SEE ALSO

L<Chj::NamespaceClean>

=cut


package Chj::NamespaceCleanAbove;

use strict; use warnings FATAL => 'uninitialized';

use Chj::NamespaceClean;

sub import {
    my $_importpackage= shift;
    my $package= caller;
    my $keys= package_keys $package;
    no strict 'refs';
    *{"${package}::_END_"}= sub {
	package_delete $package, $keys;
	1 # make _END_ work as the last statement in a module
    };
}

1
