#
# Copyright (c) 2006-2014 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

Chj::Package::OfPath

=head1 SYNOPSIS

=head1 DESCRIPTION

(Taken from chj-bin's perl_path2namespace.)


=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut


package Chj::Package::OfPath;
@ISA="Exporter"; require Exporter;
@EXPORT_OK=qw(
              package_of_path
              package_of_path_or_package
             );

use strict; use warnings; use warnings FATAL => 'uninitialized';
use Cwd 'abs_path';
use Chj::singlequote;

our $DEBUG=0;

sub package_of_path {
    my ($path)=@_;
    $path=~ s{^\./}{};
    my $class= $path;
    $class=~ s/\.pm$//;
    $class=~ s|/|::|sg;
    if ($path=~ m{^/}) {
        # absolute
    } else {
        my $p= abs_path $path
          or die "abs_path '$path': $!";
        $path= $p;
    }
    warn "path=".singlequote($path) if $DEBUG;

    open my $in, "<", $path
      or die "could not open '$path': $!";

    local $/;
    my $content= <$in>;
    close $in
      or die "closing '$path': $!";
  CHECK: {
        while ($content=~ m{\bpackage +([\w:]+)}g) {
            my $namespace= $1;
            if ($class=~ m/\Q$namespace\E$/) {
                warn "cutting '$class' down to '$namespace'\n" if $DEBUG;
                $class= $namespace;
                last CHECK;
            }
        }
        die "could not find any package definition in '$path' ".
          "matching its path";
    }
    $class
}

sub package_of_path_or_package {
    my ($path_or_package)=@_;
    if ($path_or_package=~ m{(\S+\.pm)}) {
        package_of_path($1)
    } elsif ($path_or_package=~ m{^(\w+\:\:)*\w+\z}s) {
        $path_or_package
    } elsif ($path_or_package=~ m{^(\w+/)*\w+\z}s) {
        $path_or_package=~ s|/|::|sg;
        $path_or_package
    } else {
        die "doesn't look sane: ".singlequote($path_or_package)
    }
}

1
