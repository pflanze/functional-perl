#
# Copyright (c) 2015-2019 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

Chj::CPAN::ModulePODUrl - get module POD url on metacpan

=head1 SYNOPSIS

    use Chj::CPAN::ModulePODUrl "perhaps_module_pod_url";

    is_equal [perhaps_module_pod_url "Test::More"],
             ['https://metacpan.org/pod/Test::More'];

    is_equal [perhaps_module_pod_url "SomeNonexisting::Module12345"],
             [];


=head1 DESCRIPTION


=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut

package Chj::CPAN::ModulePODUrl;
@ISA = "Exporter";
require Exporter;
@EXPORT      = qw(perhaps_module_pod_url);
@EXPORT_OK   = qw(if_get);
%EXPORT_TAGS = (all => [@EXPORT, @EXPORT_OK]);

use strict;
use warnings;
use warnings FATAL => 'uninitialized';

use LWP::UserAgent;
use FP::Show;

our $ua = LWP::UserAgent->new;    # reuse to speed up HTTPS handling?

#$ua->timeout($maybe_timeout);
#$ua->env_proxy;

sub if_get ($&&&) {

    # the handlers are getting a HTTP::Response object
    my ($url, $success, $res404, $error) = @_;

    my $response = $ua->get($url);

    do {
        if ($response->is_success) {
            $success
        }
        elsif ($response->code == 404) {
            $res404
        }
        else {
            # XX todo: handle redirects transparently?
            $error
        }
        }
        ->($response)
}

#sub if_module_pod_url ($&&&) {
#    my ($module_name,$then,$else,$error) = @_;

# better for caching (also perhaps in general): return error object?
# Or even just plain old die.

sub perhaps_module_pod_url {
    my ($module_name) = @_;

    my $url = "https://metacpan.org/pod/$module_name";

    if_get(
        $url,
        sub {
            my ($response) = @_;
            ($url)
        },
        sub {
            my ($response) = @_;
            ()
        },
        sub {
            my ($response) = @_;
            die $response->status_line
        }
    )
}

1
