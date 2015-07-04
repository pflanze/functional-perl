#
# Copyright 2015 by Christian Jaeger, ch at christianjaeger ch
# Published under the same terms as perl itself
#

=head1 NAME

Chj::CPAN::ModulePODUrl - get module POD url on metacpan

=head1 SYNOPSIS

 use Chj::CPAN::ModulePODUrl "perhaps_module_pod_url";
 use PXML::XHTML;
 my $element= CODE "Frob";
 if (my ($url)= perhaps_module_pod_url $element->text) {
     A {href=> $url}, $element
 } else {
     $element
 }

=head1 DESCRIPTION


=cut


package Chj::CPAN::ModulePODUrl;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(perhaps_module_pod_url);
@EXPORT_OK=qw(if_get);
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict; use warnings FATAL => 'uninitialized';

use LWP::UserAgent;

our $ua = LWP::UserAgent->new; # reuse to speed up HTTPS handling?
#$ua->timeout($maybe_timeout);
#$ua->env_proxy;

sub if_get ($&&&) {
    # the handlers are getting a HTTP::Response object
    my ($url,$success,$res404,$error)= @_;

    my $response = $ua->get($url);

    do {
	if ($response->is_success) {
	    $success
	} elsif ($response->code == 404) {
	    $res404
	} else {
	    # XX todo: handle redirects transparently?
	    $error
	}
    }->($response)
}

#sub if_module_pod_url ($&&&) {
#    my ($module_name,$then,$else,$error)= @_;

# better for caching (also perhaps in general): return error object? 
# Or even just plain old die.

sub perhaps_module_pod_url ($) {
    my ($module_name)= @_;

    my $url= "https://metacpan.org/pod/$module_name";

    if_get( $url,
	    sub {
		my ($response)=@_;
		($url)
	    },
	    sub {
		my ($response)=@_;
		()
	    },
	    sub {
		my ($response)=@_;
		die $response->status_line
	    })
}

1