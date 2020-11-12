use strict;
use warnings;
use warnings FATAL => 'uninitialized';
use PXML::XHTML ":all";

my $homeurl        = "http://functional-perl.org";
my $logo_from_base = "FP-logo.png";

sub {
    my ($path0) = @_;
    +{
        homeurl => $homeurl,
        logo    => DIV(
            { class => "header" },
            A(
                { href => "$homeurl", class => "header" },
                SPAN({ class => "logo2" }, "Functional "),
                IMG({
                    src    => path_diff($path0, $logo_from_base),
                    alt    => "Logo",
                    border => 0
                }),
                SPAN({ class => "logo2" }, " Perl")
            ),
            SPAN(
                { class => "logo2" },
                " $nbsp $nbsp $nbsp $nbsp $nbsp $nbsp $nbsp $nbsp $nbsp"
            )
        ),
    }
    }
