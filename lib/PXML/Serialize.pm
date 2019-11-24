#
# Copyright (c) 2013-2019 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

PXML::Serialize

=head1 SYNOPSIS

=head1 DESCRIPTION


=head1 SPECIAL VALUES

There are some special values that the serializer will evaluate
transparently:

=over 4

=item promises from FP::Lazy

are C<force>d

=item code references

are called with no arguments

=item objects

In body context, their `pxml_serialized_body_string` method (if
available) will be called, in attribute context,
`pxml_serialized_attribute_string`, in both cases the string is
inserted into the output without escaping (see `PXML::Preserialize`
for an example that uses this). Missing those, `string` will be called
if available and the result escaped, otherwise an exception is thrown.

=back

=head1 NOTE

This is alpha software! Read the package README.

=cut


package PXML::Serialize;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(pxml_xhtml_print);
@EXPORT_OK=qw(pxml_print
              pxml_print_fragment
              pxml_xhtml_print_fast
              pxml_print_fragment_fast
              putxmlfile
              puthtmlfile
              attribute_escape
              content_escape
            );
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict; use warnings; use warnings FATAL => 'uninitialized';

use Data::Dumper;
use PXML::Element;
use PXML qw(is_pxml_element is_pxmlflush);
use FP::Lazy;
use FP::List;
use FP::Stream;
use Chj::xperlfunc qw(xprint xprintln);
use FP::Weak 'weaken'; # instead of from Scalar::Util so that it can
                       # be turned off globally (and we depend on FP
                       # anyway)

sub is_somearray ($) {
    my $r= ref($_[0]);
    # XX mess, make this a proper dependency
    $r eq "ARRAY" or $r eq "PXML::Body"
}

sub is_empty_string ($) {
    defined $_[0] and !length ref $_[0] and $_[0] eq ""
}

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

sub pxmlforce ($);
sub pxmlforce ($) {
    my ($v)=@_;
    if (my $r= ref $v) {
        if ($r eq "CODE") {
            pxmlforce (&$r())
        } else {
            force $v
        }
    } else {
        $v
    }
}

sub object_force_escape ($$$$);
sub object_force_escape ($$$$) {
    my ($v, $string_method_for_context, $escape, $fh)=@_;
    if (my $m=
        UNIVERSAL::can($v, $string_method_for_context)) {
        # no escaping
        &$m($v, $fh)
    } elsif ($m=
           # XX should this instead simply stringify using
           # '"$v"'? That would not show up errors with
           # context. But it would be less interruptive
           # perhaps? Just issue a warning? Ideal would
           # probably be to do the '""', but give a warning
           # if it was Perl's default stringification. How to
           # do this?
           UNIVERSAL::can($v,"string")) {
        &$escape(&$m ($v))
    } else {
        die "unexpected type of reference that doesn't have a 'string' method: "
          .(perhaps_dump $v);
    }
}


# XXX hack, the code is really hopeless, should use ~same code as for
# body parts.
sub _attributeval_to_string {
    my ($v,$fh)= @_;
    my $ref= ref $v;
    (length ($ref) ?
     ($ref eq "ARRAY" ?
      join ("",
              map {
                  _attributeval_to_string ($_, $fh)
              } @$v)
      :
      is_pxmlflush($v) ?
      do { flush $fh or die $!; "" }
      :
      object_force_escape
      (pxmlforce($v),
       "pxml_serialized_attribute_string",
       *attribute_escape,
       $fh))
     :
     # fast path:
     attribute_escape $v)
}

sub _pxml_print_fragment_fast {
    @_==4 or die "wrong number of arguments";
    my ($v,$fh,$html5compat,$void_element_h)=@_;
    weaken $_[0]
      # necessary since we're also called with strings:
      if ref $_[0];
  LP: {
        ## **NOTE**: this has seen some evil optimizations; before
        ## working on the code, please undo them first by using git
        ## revert.
        if (my $ref= ref $v) {
            if ($ref eq "PXML::Element" or $ref eq "PXML::PXHTML_") {
              PXML:
                my $n= $v->name;
                print $fh "<$n" or die $!;
                if (my $attrs= $v->maybe_attributes) {
                    for my $k (sort keys %$attrs) {
                        print $fh " $k=\""
                          or die $!;
                        my $str= _attributeval_to_string $$attrs{$k}, $fh;
                        print $fh "$str\""
                          or die $!;
                    }
                }
                my $body= $v->body;
                
                my $looksempty=
                  # fast path
                  (not defined $body # XX allow undef or don't? Please
                                     # finally settle this!
                   or
                   (not ref $body and length($body)==0)
                   or
                   (is_somearray($body) and
                    (not @$body
                     or
                     (@$body==1 and
                      (# XX remove undef check here now, too? OK?--nope, necessary
                       not defined $$body[0]
                       or
                       (is_somearray($$body[0]) and not @{$$body[0]})
                       or
                       is_empty_string($$body[0]))))));

                my $selfreferential;
                if ($html5compat) {
                    if ($$void_element_h{$n}) {
                        if ($looksempty) {
                            $selfreferential=1;
                        } else {
                            my $isempty=  # slow path
                              is_null(stream_mixed_flatten ($body));
                            $selfreferential = $isempty;
                            warn "html5 compatible serialization requested "
                              ."but got void element '$n' that is not empty"
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
            } elsif (my $car_and_cdr= UNIVERSAL::can ($v, "car_and_cdr")) {
              PAIR:
                #my $a;
                ($a,$v)= &$car_and_cdr($v);
                _pxml_print_fragment_fast ($a, $fh,
                                           $html5compat, $void_element_h);
                #_pxml_print_fragment_fast (cdr $v, $fh);
                redo LP;
            } elsif (my $for_each= UNIVERSAL::can ($v, "for_each")) {
                # catches null, too. Well.
                &$for_each
                  ($v,
                   sub {
                       my ($a)=@_;
                       _pxml_print_fragment_fast ($a, $fh,
                                                  $html5compat, $void_element_h);
                   });
            } elsif (UNIVERSAL::isa($ref, "FP::Lazy::Promise")) {
              PROMISE:
                #_pxml_print_fragment_fast (force($v), $fh,
                #                           $html5compat, $void_element_h);
                $v= force($v,1); # XXX why nocache?
                redo LP;
            } else {
                if (is_somearray($v)) {
                    no warnings "recursion"; # hu.
                    for (@$v) {
                        # XXX use Keep around $_ to prevent mutation of tree?
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
                    # XX obsolete now, since UNIVERSAL::can ($v,
                    # "for_each") above will catch it already.
                } elsif (is_pxmlflush $v) {
                    flush $fh or die $!
                } else {
                    # slow fallback...  again, see above **NOTE** re
                    # evil.
                    $ref or die "BUG"; # we're in the if ref scope, right?
                    goto PXML if UNIVERSAL::isa($v, "PXML::Element");
                    goto PAIR if is_pair $v;
                    goto PROMISE if is_promise $v;

                    print $fh
                      object_force_escape
                        ($v,
                         "pxml_serialized_body_string",
                         *content_escape,
                         $fh)
                          or die $!;;
                }
            }
        } elsif (not defined $v) {
            # (previously end of linked list marker) nothing; XX
            # should this give exception (to point out any issue with
            # deleted streams, the reason why I changed from using
            # undef to null)? But exception won't show a good
            # backtrace anyway at this point.
            #warn "warning: ignoring undef in PXML datastructure";
            # XXX what to do about this?
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
    if (length (my $r= ref $v)) {
        if (UNIVERSAL::isa($v, "PXML::XHTML")) {
            @_=($v); goto &$with_first_element;
        } else {
            my $s= force(stream_mixed_flatten ($v)
                         ->filter(*is_pxml_element));
            if (is_null $s) {
                goto &$no_element
            } else {
                @_= (car $s); goto &$with_first_element;
            }
        }
    } else {
        goto &$no_element
    }
}

sub pxml_xhtml_print_fast ($ $ ;$ ) {
    my ($v, $fh, $maybe_lang)= @_;
    weaken $_[0] if ref $_[0]; # ref check perhaps unnecessary here
    if (not ref $v or not UNIVERSAL::isa($v, "PXML::Element")) {
        die "not an element: ".(perhaps_dump $v);
    }
    if (not "html" eq $v->name) {
        die "not an 'html' element: ".(perhaps_dump $v);
    }
    xprint ($fh, "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n");
    xprint ($fh, "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">\n");
    # add attributes to toplevel element
    my $v2= $v->maybe_attributes ? $v :
        $v->attributes_set
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
    pxml_print_fragment_fast($v, $fh);
}

sub putxmlfile ($$) {
    my ($path,$xml)=@_;
    weaken $_[1] if ref $_[0]; # ref check perhaps unnecessary here
    my $f= xopen_write $path;
    binmode($f, ":utf8") or die "binmode";
    # ^ XX should this use ":encoding(UTF-8)"? To validate in-memory
    # strings? Shouldn't we just check all *inputs*?
    pxml_print($xml,$f);
    $f->xclose;
}

sub PXML::Element::xmlfile {
    my ($v, $path)=@_;
    weaken $_[0];
    putxmlfile ($path, $v)
}

sub puthtmlfile ($$;$) {
    my ($path,$v,$maybe_lang)=@_;
    weaken $_[1] if ref $_[0]; # ref check perhaps unnecessary here
    #xmkdir_p dirname $path;
    my $out= xopen_write($path);
    binmode $out, ":utf8" or die "binmode";
    # ^ XX dito, see comment in putxmlfile
    pxml_xhtml_print_fast($v, $out, $maybe_lang||"en");
    $out->xclose;
}

sub PXML::Element::htmlfile {
    my ($v, $path, $maybe_lang)=@_;
    weaken $_[0];
    puthtmlfile ($path, $v, $maybe_lang)
}

1
