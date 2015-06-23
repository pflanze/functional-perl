#
# Copyright 2015 by Christian Jaeger, ch at christianjaeger ch
# Published under the same terms as perl itself
#

=head1 NAME

FP::Weak - utilities to weaken references

=head1 SYNOPSIS

 use FP::Weak;

 sub stream_foo {
     my ($s)=@_;
     weaken $_[0];
     my $f; $f= sub { ... &$f ... };
     Weakened $f
 }

 my $x = do {
     my $s= somestream;
     stream_foo (Keep $s);
     $s->first
 };

=head1 DESCRIPTION

=over 4

=item weaken <location>

`Scalar::Util`'s `weaken`, unless one of the `with_..` development
utils are used (or `$FP::Weak::weaken` is changed).

=item Weakened <location>

Calls `weaken <location>` after copying the reference, then returns
the unweakened reference.

=item Keep <location>

Protect <location> from being weakened by accessing elements of `@_`.

=back

Optionally exported development utils:

=over 4

=item noweaken ($var), noWeakened ($var)

No-ops. The idea is to prefix the weakening ops with 'no' to disable
them.

=item warnweaken ($var), warnWeakened ($var)

Give a warning in addition to the weakening operation.

=item cluckweaken ($var), cluckWeakened ($var)

Give a warning with backtrace in addition to the weakening operation.

=item with_noweaken { code }, &with_noweaken ($proc)

=item with_warnweaken { code } (and same as above)

=item with_cluckweaken { code }

Within their dynamic scope, globally change `weaken` to one of the
alternatives

=item do_weaken (1|0|"yes"|"no"|"on"|"off"|"warn"|"cluck")

Turn weakening on and off (unscoped, 'persistently').

=back

=cut


package FP::Weak;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(weaken Weakened Keep);
@EXPORT_OK=qw(
		 do_weaken
		 noweaken noWeakened with_noweaken
		 warnweaken warnWeakened with_warnweaken
		 cluckweaken cluckWeakened with_cluckweaken
	    );
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict; use warnings FATAL => 'uninitialized';

use Scalar::Util ();

our $weaken= \&Scalar::Util::weaken;

sub weaken ($) {
    goto $weaken
}
# XX is there really no way (short of re-exporting everywhere with a
# Chj::ruse approach) to avoid the extra function call cost?


# protect a variable from being pruned by callees that prune their
# arguments
sub Keep ($) {
    my ($v)=@_;
    $v
}

# weaken a variable, but also provide a non-weakened reference to its
# value as result
sub Weakened ($) {
    my ($ref)= @_;
    weaken $_[0];
    $ref
}


sub noweaken ($) {
    # noop
}

sub noWeakened ($) {
    $_[0]
}

sub with_noweaken (&) { local $weaken= \&noweaken; &{$_[0]}() }


use Carp;

sub warnweaken ($) {
    carp "weaken ($_[0])";
    Scalar::Util::weaken ($_[0]);
}

sub warnWeakened ($) {
    carp "weaken ($_[0])";
    Weakened ($_[0]);
}

sub with_warnweaken (&) { local $weaken= \&warnweaken; &{$_[0]}() }


use Carp 'cluck';

sub cluckweaken ($) {
    cluck "weaken ($_[0])";
    Scalar::Util::weaken ($_[0]);
}

sub cluckWeakened ($) {
    cluck "weaken ($_[0])";
    Weakened ($_[0]);
}

sub with_cluckweaken (&) { local $weaken= \&cluckweaken; &{$_[0]}() }


sub do_weaken ($) {
    my ($v)=@_;
    my $w=
      $v ?
	(+{
	   1=> \&Scalar::Util::weaken,
	   "yes"=> \&Scalar::Util::weaken,
	   "no"=> \&noweaken,
	   "on"=> \&Scalar::Util::weaken,
	   "off"=> \&noweaken,
	   "noweaken"=> \&noweaken,
	   "warn"=> \&warnweaken,
	   "warnweaken"=> \&warnweaken,
	   "cluck"=> \&cluckweaken,
	   "cluckweaken"=> \&cluckweaken,
	  }->{$v} // die "do_weaken: unknown key '$v'")
	  : \&noweaken;
    $weaken= $w
}


1
