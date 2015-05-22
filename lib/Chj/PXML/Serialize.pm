#
# Copyright 2013 by Christian Jaeger, ch at christianjaeger ch
# Published under the same terms as perl itself
#

=head1 NAME

Chj::PXML::Serialize

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::PXML::Serialize;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(pxml_xhtml_print);
@EXPORT_OK=qw(pxml_print
	      pxml_print_fragment
	      pxml_xhtml_print_fast
	      pxml_print_fragment_fast
	      putxmlfile
	      puthtmlfile
	    );
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict; use warnings; use warnings FATAL => 'uninitialized';

use Data::Dumper;
use Chj::PXML;
use Chj::FP::Lazy;
use Chj::FP::List;
use Chj::FP::Stream;
use Chj::xIO;
use Scalar::Util 'weaken';

sub perhaps_dump {
    my ($v)=@_;
    if (ref ($v) eq "ARRAY" or ref($v) eq "HASH") {
	Dumper($v)
    } else {
	$v
    }
}

my %attribute_escape=
    ('&'=> '&amp;',
     '<'=> '&lt;',
     '>'=> '&gt;',
     '"'=> '&quot;');
sub attribute_escape {
    my ($str)=@_;
    return "" unless defined $str;
    # XX or should attributes with undefined value be dropped? (Or,
    # OTOH, should list processing be done?)
    $str=~ s/([&<>"])/$attribute_escape{$1}/sg;
    $str
}

my %content_escape=
    ('&'=> '&amp;',
     '<'=> '&lt;',
     '>'=> '&gt;');
sub content_escape {
    my ($str)=@_;
    $str=~ s/([&<>])/$content_escape{$1}/sg;
    $str
}

sub _pxml_print_fragment_fast {
    @_==4 or die;
    my ($v,$fh,$html5compat,$void_element_h)=@_;
    weaken $_[0]
      # necessary since we're also called with strings:
      if ref $_[0];
  LP: {
	## **NOTE**: this has seen some evil optimizations; before
	## working on the code, please undo them first by using git
	## revert.
	if (my $ref= ref $v) {
	    if ($ref eq "Chj::PXML" or $ref eq "Chj::PXML::PXHTML_") {
	      PXML:
		my $n= $v->name;
		print $fh "<$n" or die $!;
		if (my $attrs= $v->maybe_attributes) {
		    for my $k (sort keys %$attrs) {
			my $v= $$attrs{$k};
			# XX ugly, should have one place to evaluate
			# things (like promises, too!)
			if (ref($v) eq "CODE") {
			    $v= &$v();
			}
			print $fh " $k=\"", attribute_escape($v),"\""
			  or die $!;
		    }
		}
		my $body= $v->body;
		
		my $looksempty=
		  # fast path
		  (not @$body
		   or
		   (@$body==1 and
		    (# XX remove undef check here now, too? OK?
		     #not defined $$body[0]
		     #or
		     (ref($$body[0]) eq "ARRAY" and not @{$$body[0]})
		     or
		     $$body[0] eq "")));

		my $selfreferential;
		if ($html5compat) {
		    if ($$void_element_h{$n}) {
			if ($looksempty) {
			    $selfreferential=1;
			} else {
			    my $isempty=  # slow path
			      is_null(force(stream_mixed_flatten ($body)));
			    $selfreferential = $isempty;
			    warn "html5 compatible serialization requested "
			      ."but got void element '$v' that is not empty"
				if not $isempty;
			}
		    } else {
			$selfreferential=0;
		    }
		} else {
		    $selfreferential= $looksempty;
		}
		if ($selfreferential) {
		    print $fh "/>" or die $!;
		} else {
		    print $fh ">" or die $!;
		    no warnings "recursion"; # hu.
		    _pxml_print_fragment_fast ($body, $fh,
					       $html5compat, $void_element_h);
		    print $fh "</$n>" or die $!;
		}
	    } elsif ($ref eq "Pair") {
	      PAIR:
		#my $a;
		($a,$v)= $v->car_and_cdr;
		_pxml_print_fragment_fast ($a, $fh,
					   $html5compat, $void_element_h);
		#_pxml_print_fragment_fast (cdr $v, $fh);
		redo LP;
	    } elsif ($ref eq "Chj::FP::Lazy::Promise"
		     or
		     $ref eq "Chj::FP::Lazy::PromiseLight") {
	      PROMISE:
		#_pxml_print_fragment_fast (force($v), $fh,
		#                           $html5compat, $void_element_h);
		$v= force($v,1);
		redo LP;
	    } else {
		if ($ref eq "ARRAY") {
		    no warnings "recursion"; # hu.
		    for (@$v) {
			# XX use Keep around $_ to prevent mutation of tree?
			# nope, can't, will prevent streaming.
			_pxml_print_fragment_fast
			  ($_, $fh, $html5compat, $void_element_h);
		    }
		}
		# 'force' doesn't evaluate CODE (probably rightly so),
		# thus need to be explicit if we want 'late binding'
		# (e.g. reference to dynamic variables) during
		# serialization
		elsif ($ref eq "CODE") {
		    $v= &$v();
		    redo LP;
		} elsif (is_null $v) {
		    # end of linked list, nothing
		} else {
		    # slow fallback...  again, see above **NOTE** re
		    # evil.
		    goto PXML if (UNIVERSAL::isa($v, "Chj::PXML"));
		    goto PAIR if is_pair $v;
		    goto PROMISE if is_promise $v;
		    die "unexpected type of reference: ".(perhaps_dump $v);
		}
	    }
	} elsif (not defined $v) {
	    # (previously end of linked list marker) nothing; XX
	    # should this give exception (to point out any issue with
	    # deleted streams, the reason why I changed from using
	    # undef to null)? But exception won't show a good
	    # backtrace anyway at this point.
	    warn "warning: ignoring undef in PXML datastructure";
	} else {
	    #print $fh content_escape($v) or die $!;
	    $v=~ s/([&<>])/$content_escape{$1}/sg;
	    print $fh $v or die $!;
	}
    }
}

sub pxml_print_fragment_fast ($ $ );
sub pxml_print_fragment_fast ($ $ ) {
    my ($v,$fh)=@_;
    weaken $_[0] if ref $_[0]; # ref check perhaps unnecessary here
    my $no_element= sub {
	@_=($v,$fh,undef,undef);
	goto\&_pxml_print_fragment_fast;
    };
    my $with_first_element= sub {
	my ($firstel)=@_;
	weaken $_[0] if ref $_[0];
	my $html5compat= $firstel->
	  require_printing_nonvoid_elements_nonselfreferential;
	@_=($v,
	    $fh,
	    $html5compat,
	    ($html5compat and $firstel->void_element_h));
	goto \&_pxml_print_fragment_fast;
    };
    if (UNIVERSAL::isa($v, "Chj::PXHTML")) {
	@_=($v); goto $with_first_element;
    } else {
	if (ref $v) {
	    my $s= force(stream_mixed_flatten ($v));
	    if ($s) {
		@_= (car $s); goto $with_first_element;
	    } else {
		goto $no_element
	    }
	} else {
	    goto $no_element
	}
    }
}

sub pxml_xhtml_print_fast ($ $ ;$ ) {
    my ($v, $fh, $maybe_lang)= @_;
    weaken $_[0] if ref $_[0]; # ref check perhaps unnecessary here
    if (not UNIVERSAL::isa($v, "Chj::PXML")) {
	die "not an element: ".(perhaps_dump $v);
    }
    if (not "html" eq $v->name) {
	die "not an 'html' element: ".(perhaps_dump $v);
    }
    xprint $fh, "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n";
    xprint $fh, "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">\n";
    # add attributes to toplevel element
    my $v2= $v->maybe_attributes ? $v :
	$v->set_attributes
	(do {
	    my $lang= $maybe_lang
		or die "missing 'lang' attribute from html element and no lang option given";
	    +{
		xmlns=> "http://www.w3.org/1999/xhtml",
		"xml:lang"=> $lang,
		lang=> $lang
	    }
	 });
    @_=($v2, $fh); goto \&pxml_print_fragment_fast;
}

# for now,
sub pxml_xhtml_print ($ $ ;$ );
*pxml_xhtml_print = *pxml_xhtml_print_fast;


use Chj::xopen "xopen_write";

sub pxml_print ($ $ ) {
    my ($v, $fh)= @_;
    weaken $_[0] if ref $_[0]; # ref check perhaps unnecessary here
    xprintln($fh, q{<?xml version="1.0"?>});
    @_=($v, $fh); goto \&pxml_print_fragment_fast;
}

sub putxmlfile ($$) {
    my ($path,$xml)=@_;
    weaken $_[1] if ref $_[0]; # ref check perhaps unnecessary here
    my $f= xopen_write $path;
    binmode($f, ":utf8") or die;
    pxml_print($xml,$f);
    $f->xclose;
}

sub puthtmlfile ($$;$) {
    my ($path,$v,$maybe_lang)=@_;
    weaken $_[1] if ref $_[0]; # ref check perhaps unnecessary here
    #xmkdir_p dirname $path;
    my $out= xopen_write($path);
    binmode $out, ":utf8" or die;
    pxml_xhtml_print_fast($v, $out, $maybe_lang||"en");
    $out->xclose;
}


1
