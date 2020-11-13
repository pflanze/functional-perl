#
# Copyright (c) 2015 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

Chj::constructorexporter

=head1 SYNOPSIS

    {
        package Foo;
        use Chj::constructorexporter;
        *import = constructorexporter new => "Foo", new_from_string => "foo";
        sub new { ... }
    }
    use Foo "foo", "foo"; # or ":all"; 'use Foo;' would not import anything
    foo("abc") # calls Foo->new_from_string("abc")
    Foo(1,2) # calls Foo->new(1,2)

    {
        package Bar;
        our @ISA = "Foo";
    }
    use Bar "foo"; # this exports a different "foo"!
    foo("def") # calls Bar->new("def")

    # to import both (avoiding conflict):
    use Foo qw(foo);
    use Bar qw(foo -prefix bar_); # imports 'bar_foo'
    # The position of the -prefix argument and its value within the
    # import list is irrelevant.

    # Note that the exported constructor functions cannot be reached by
    # full qualification: in this example Foo::foo is undefined (or it
    # might instead be an unrelated method definition)!


=head1 DESCRIPTION

This module might be evil: it helps writing OO modules that also
export functions. It only helps to export functions that are
constructors for the class in question, though, so its evilness might
be bounded.

Subclasses that inherit (don't override) the import method will export
constructors for the subclass those are imported from. That might be
sensible or pure evil, the creator of this module isn't sure yet. If
you don't like this, either override 'import' in the subclass, or ask
for this to be changed.

=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut

package Chj::constructorexporter;
use strict;
use warnings;
use warnings FATAL => 'uninitialized';
use Exporter "import";

our @EXPORT      = qw(constructorexporter);
our @EXPORT_OK   = qw();
our %EXPORT_TAGS = (all => [@EXPORT, @EXPORT_OK]);

sub constructorexporter {
    my %exportdecl = @_;
    sub {
        my $class = shift;

        my ($all) = grep { $_ eq ":all" } @_;
        my @rest = grep { $_ ne ":all" } @_;

        my $prefix = "";
        my @names;
        for (my $i = 0; $i < @rest; $i++) {
            my $v = $rest[$i];
            if ($v eq "-prefix") {
                $i++;
                $prefix = $rest[$i];
            } else {
                push @names, $v
            }
        }

        my $package = caller;

        my $exportdecl = +{
            map {
                my $methodname = $_;
                my $exportname = $exportdecl{$methodname};
                (
                    $exportname => sub {
                        $class->$methodname(@_)
                    }
                )
            } keys %exportdecl
        };

        my $exports = (
            $all ? $exportdecl : +{
                map {
                    $_ => $$exportdecl{$_} // die "$_ not exported by $class"
                } @names
            }
        );

        for my $name (keys %$exports) {
            no strict 'refs';
            *{ $package . "::" . $prefix . $name } = $$exports{$name}
        }
    }
}

1
