#
# Copyright (c) 2019-2021 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FunctionalPerl::Htmlgen::PerlTidy -- code formatting for Perl snippets

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SEE ALSO

This is a L<FunctionalPerl::Htmlgen::PXMLMapper>

=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut

package FunctionalPerl::Htmlgen::PerlTidy;

use strict;
use warnings;
use warnings FATAL => 'uninitialized';
use experimental "signatures";

use FP::Show;
use Perl::Tidy;
use FunctionalPerl::Htmlgen::Htmlparse ":all";
use FunctionalPerl::Htmlgen::Sourcelang;

sub tidyhtml {
    my ($source) = @_;
    my ($dest, $errorfile);
    my $error = Perl::Tidy::perltidy(
        argv        => '--html -ntoc',
        source      => \$source,
        destination => \$dest,
        errorfile   => \$errorfile
    );
    if ($error) {
        warn "perltidy error: " . show($error) . " (" . show($errorfile) . ")";
        ()
    } else {
        htmlparse $dest, "pre"
    }
}

use FP::Struct [] => "FunctionalPerl::Htmlgen::PXMLMapper";

sub match_element_names($self) { [qw(code)] }

sub map_element ($self, $e, $uplist) {

    # warn "hm: "
    #     . show($e->name)
    #     . ", uplist= "
    #     . show($uplist->map(the_method "name"));
    if (not $uplist->is_null and $uplist->first->lcname eq "pre") {
        my $txt = $e->text;
        if (sourcelang($txt) eq "Perl") {
            my $pre = tidyhtml $txt;

            #use FP::Repl;repl;
            $pre->body
        } else {

            # do not handle this element, leave up to pointer_eq to
            # detect that
            $e
        }
    } else {

        # do not handle this element, leave up to pointer_eq to detect
        # that
        $e
    }
}

_END_    # _END__ for dev
