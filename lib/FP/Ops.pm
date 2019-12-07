#
# Copyright (c) 2015-2019 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FP::Ops -- function wrappers around Perl ops

=head1 SYNOPSIS

    use FP::List; use FP::Stream; use FP::Lazy; use FP::Equal 'is_equal';
    use FP::Ops qw(add subt applying);

    # Lazy fibonacci sequence using \&add which can also be used as *add
    our $fibs; $fibs=
      cons 1, cons 1, lazy { stream_zip_with *add, Keep($fibs), rest $fibs };
    is_equal $fibs->take(10),
             list(1, 1, 2, 3, 5, 8, 13, 21, 34, 55);

    # For each list entry, call `subt` (subtract) with the values in the
    # given array or sequence.
    is_equal list([4], [4,2], list(4,2,-1))->map(applying *subt),
             list(-4, 2, 3);

=head1 DESCRIPTION

There's no way to take a code reference to Perl operators, hence a
subroutine wrapper is necessary to use them as first-class values
(like pass them as arguments to higher-order functions like
list_map / ->map). This module provides them.

Also similarly, `the_method("foo", @args)` returns a function that
does a "foo" method call on its argument, passing @args and then
whatever additional arguments the function receives.

`cut_method` is a variant of the_method which takes the object
as the first argument: `cut_method($obj,"foo",@args)` returns a
function that does a "foo" method call on $obj, passing @args and then
whatever additional arguments the function receives.

Also, `binary_operator("foo")` returns a function that uses "foo" as
operator between 2 arguments. `unary_operator("foo")` returns a
function that uses "foo" as operator before its single
argument. CAREFUL: make sure the strings given as the first argument
to these are secured, as they are passed to eval and there is no
safety check!

=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut


package FP::Ops;
@ISA="Exporter"; require Exporter;
@EXPORT=qw();
@EXPORT_OK=(qw(
                 add
                 subt
                 mult
                 div
                 mod
                 expt
                 string_cmp
                 string_eq
                 string_eq
                 string_ne
                 string_lt
                 string_le
                 string_gt
                 string_ge
                 stringify
                 string_lc
                 string_uc
                 string_lcfirst
                 string_ucfirst
                 number_cmp
                 number_eq
                 number_ne
                 number_lt
                 number_le
                 number_gt
                 number_ge
                 the_method
                 cut_method
                 applying
                 applying_to
                 binary_operator
                 unary_operator
                 regex_match
             ),
            # Manual variants
            qw(
                  regex_substitute_coderef
                  regex_xsubstitute_coderef

                  regex_substitute_re
                  regex_xsubstitute_re
                  regex_substitute_re_globally
                  regex_xsubstitute_re_globally
             ),
            # The first 4 above overloaded into just two (globally
            # variants see below):
            qw(
                 regex_substitute
                 regex_xsubstitute
            ),
            # These are just aliases:
            'regex_substitute_globally', # regex_substitute_re_globally
            'regex_xsubstitute_globally', # regex_xsubstitute_re_globally
           );
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict; use warnings; use warnings FATAL => 'uninitialized';
use Chj::TEST;
use FP::Show;


sub add {
    my $t= 0;
    $t+= $_ for @_;
    $t
}

sub subt {
    @_==1 ? -$_[0] :
      @_ ? do {
          my $t= shift;
          $t-= $_ for @_;
          $t
      } :
      die "need at least 1 argument"
}

sub mult {
    my $t= 1;
    $t*= $_ for @_;
    $t
}

sub div {
    @_==1 ? (1 / $_[0]) :
      @_ ? do {
          my $t= shift;
          $t/= $_ for @_;
          $t
      } :
      die "need at least 1 argument"
}

sub mod {
    @_==2 or die "need 2 arguments";
    my ($a, $b)=@_;
    $a % $b
}

sub expt {
    @_==2 or die "need 2 arguments";
    my ($a, $b)=@_;
    $a ** $b
}

sub string_cmp ($ $) {
    @_==2 or die "need 2 arguments";
    $_[0] cmp $_[1]
}

sub string_eq ($ $) {
    @_==2 or die "need 2 arguments";
    $_[0] eq $_[1]
}
sub string_ne ($ $) {
    @_==2 or die "need 2 arguments";
    $_[0] ne $_[1]
}
sub string_lt ($ $) {
    @_==2 or die "need 2 arguments";
    $_[0] lt $_[1]
}
sub string_le ($ $) {
    @_==2 or die "need 2 arguments";
    $_[0] le $_[1]
}
sub string_gt ($ $) {
    @_==2 or die "need 2 arguments";
    $_[0] gt $_[1]
}
sub string_ge ($ $) {
    @_==2 or die "need 2 arguments";
    $_[0] ge $_[1]
}

sub stringify ($) {
    "$_[0]"
}

sub string_lc ($) {
    @_==1 or die "need 1 argument";
    lc $_[0]
}
sub string_uc ($) {
    @_==1 or die "need 1 argument";
    uc $_[0]
}
sub string_lcfirst ($) {
    @_==1 or die "need 1 argument";
    lcfirst $_[0]
}
sub string_ucfirst ($) {
    @_==1 or die "need 1 argument";
    ucfirst $_[0]
}

sub number_cmp ($ $) {
    @_==2 or die "need 2 arguments";
    $_[0] <=> $_[1]
}

sub number_eq ($ $) {
    @_==2 or die "need 2 arguments";
    $_[0] == $_[1]
}
sub number_ne ($ $) {
    @_==2 or die "need 2 arguments";
    $_[0] != $_[1]
}
sub number_lt ($ $) {
    @_==2 or die "need 2 arguments";
    $_[0] < $_[1]
}
sub number_le ($ $) {
    @_==2 or die "need 2 arguments";
    $_[0] <= $_[1]
}
sub number_gt ($ $) {
    @_==2 or die "need 2 arguments";
    $_[0] > $_[1]
}
sub number_ge ($ $) {
    @_==2 or die "need 2 arguments";
    $_[0] >= $_[1]
}

sub the_method {
    @_ or die "wrong number of arguments";
    my ($method,@args)=@_;
    sub {
        my $self=shift;
        $self->$method(@args,@_)
          # any reason to put args before or after _ ? So far I only
          # have args, no _.
    }
}

sub cut_method {
    @_>=2 or die "wrong number of arguments";
    my ($object,$method,@args)=@_;
    sub {
        $object->$method(@args,@_)
    }
}

sub applying ($) {
    @_==1 or die "wrong number of arguments";
    my ($f)=@_;
    sub ($) {
        @_==1 or die "wrong number of arguments";
        my ($argv)=@_;
        @_= ref($argv) eq "ARRAY" ? @$argv : $argv->values;
        goto &$f
    }
}

sub applying_to {
    my @v=@_;
    sub ($) {
        @_==1 or die "wrong number of arguments";
        my ($f)=@_;
        @_=@v; goto &$f
    }
}

sub binary_operator ($) {
    @_==1 or die "need 1 argument";
    my ($code)=@_;
    eval 'sub ($$) { @_==2 or die "need 2 arguments"; $_[0] '.$code.' $_[1] }'
      || die "binary_operator: ".show($code).": $@";
    # XX security?
}

sub unary_operator ($) {
    @_==1 or die "need 1 argument";
    my ($code)=@_;
    eval 'sub ($) { @_==1 or die "need 1 argument"; '.$code.' $_[0] }'
      || die "unary_operator: ".show($code).": $@";
    # XX security?
}

TEST { my $lt= binary_operator "lt";
       [map { &$lt (@$_) }
        ([2,4], [4,2], [3,3], ["abc","bbc"], ["ab","ab"], ["bbc", "abc"])] }
  [1,'','', 1, '', ''];

TEST { my $neg= unary_operator "-";
       [map { &$neg ($_) }
        (3, -2.5, 0)] }
  [-3, 2.5, 0];


sub regex_match ($) {
    @_==1 or die "wrong number of arguments";
    my ($re)= @_;
    sub {
        @_==1 or die "wrong number of arguments";
        my ($str)=@_;
        $str=~ /$re/
    }
}


sub make_regex_substitute_coderef {
    @_==1 or die "wrong number of arguments";
    my ($allow_failures)=@_;
    my $name= do {
        my $x= $allow_failures ? "x" : "";
        "regex_${x}substitute_coderef"
    };
    sub {
        my $coderef= shift;
        if (@_==0) {
            sub {
                @_==1 or die "expecting 1 argument, got ".@_;
                local $_= $_[0];
                &$coderef
                    or $allow_failures || die "no match";
                $_
            }
        } elsif (@_==1) {
            local $_= $_[0];
            &$coderef
                or $allow_failures || die "no match";
            $_
        } else {
            die "$name: expecting 1 or 2 arguments, got ".@_;
        }
    }
}

*regex_substitute_coderef= make_regex_substitute_coderef 1;
*regex_xsubstitute_coderef= make_regex_substitute_coderef 0;

sub make_regex_substitute_re {
    @_==2 or die "wrong number of arguments";
    my ($allow_failures, $globally)=@_;
    my $name= do {
        my $x= $allow_failures ? "x" : "";
        my $g= $globally ? "_globally" : "";
        "regex_${x}substitute_re$g"
    };
    sub {
        if (@_==2) {
            my ($re, $str_or_coderef)= @_;
            sub {
                @_==1 or die "expecting 1 argument, got ".@_;
                my ($str)= @_;
                ($globally ?
                 (UNIVERSAL::isa($str_or_coderef, "CODE") ?
                  $str=~ s/$re/&$str_or_coderef()/eg
                  : $str=~ s/$re/$str_or_coderef/g)
                 : (UNIVERSAL::isa($str_or_coderef, "CODE") ?
                    $str=~ s/$re/&$str_or_coderef()/e
                    : $str=~ s/$re/$str_or_coderef/))
                    or $allow_failures || die "$name: no match";
                $str
            }
        } elsif (@_==3) {
            my ($re, $str_or_coderef, $str)= @_;
            {
                # copy-paste of above
                ($globally ?
                 (UNIVERSAL::isa($str_or_coderef, "CODE") ?
                  $str=~ s/$re/&$str_or_coderef()/eg
                  : $str=~ s/$re/$str_or_coderef/g)
                 : (UNIVERSAL::isa($str_or_coderef, "CODE") ?
                    $str=~ s/$re/&$str_or_coderef()/e
                    : $str=~ s/$re/$str_or_coderef/))
                    or $allow_failures || die "$name: no match";
            }
            $str
        } else {
            die "$name: expecting 2 or 3 arguments, got ".@_;
        }
    }
}

*regex_substitute_re= make_regex_substitute_re 1, 0;
*regex_xsubstitute_re= make_regex_substitute_re 0, 0;
*regex_substitute_re_globally= make_regex_substitute_re 1, 1;
*regex_xsubstitute_re_globally= make_regex_substitute_re 0, 1;


sub make_regex_substitute {
    @_==1 or die "wrong number of arguments";
    my ($allow_failures)=@_;
    my $subst_coderef=
        make_regex_substitute_coderef($allow_failures);
    my $subst_re=
        make_regex_substitute_re($allow_failures, 0);
    my $name= $allow_failures ? "regex_substitute" : "regex_xsubstitute";
    sub {
        # overloading
        @_ >= 1 or die "$name: need at least 1 argument";
        goto $subst_coderef
            if UNIVERSAL::isa($_[0], "CODE");
        @_ >= 2 or die "$name: need at least 2 arguments".
            " if the first is not a coderef";
        goto $subst_re;
    }
}

*regex_substitute= make_regex_substitute 1;
*regex_xsubstitute= make_regex_substitute 0;
*regex_substitute_globally= *regex_substitute_re_globally;
*regex_xsubstitute_globally= *regex_xsubstitute_re_globally;


1
