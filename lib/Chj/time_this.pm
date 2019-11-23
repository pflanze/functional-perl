#
# Copyright (c) 2013-2015 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

Chj::time_this - benchmarking function that also returns the result(s)

=head1 SYNOPSIS

    use Chj::tim;
    my $res= time_this { somefunc(66) }; # prints timing to stderr
    # or
    my $res= time_this { somefunc(66) } "somefunc"; # included in message
    # or
    my $res= time_this { somefunc(66) }
                 msg=> "somefunc", n=> 10; # run thunk 10 times
    # or
    my $res= time_this { somefunc(66) } out=> \@t; # push to @t instead of stderr

=head1 DESCRIPTION


Currently does not divide the timings by the number of iterations.

Currently does not subtract the overhead of calling the thunk (as
Benchmark.pm does, but can't use it since it doesn't return values;
should we wrap and use assignment instead? But then timings are off
again.)

Also should probably follow the output format of Benchmark.pm

=head1 SEE ALSO

 L<Benchmark>

=head1 NOTE

This is alpha software! Read the package README.

=cut


package Chj::time_this;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(time_this);
@EXPORT_OK=qw();
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict; use warnings; use warnings FATAL => 'uninitialized';

my $fields= [qw(user system cuser csystem)];

sub time_this (&;@) {
    my ($thunk,@args)=@_;
    my $wantarray= wantarray;
    my $args={};
    my $maybe_msg= @args==1 ? $args[0] : do { $args= +{@args}; $$args{msg} };
    my $n= $$args{n} // 1;

    my $a= [times];
    my @res;
    for (1..$n) {
        @res= $wantarray ? &$thunk() : scalar &$thunk();
    }
    my $b= [times];

    my $d= [map { $$fields[$_]."=".($$b[$_] - $$a[$_]) } 0..$#$a ];
    my $forstr= defined($maybe_msg) ? " for $maybe_msg" : "";
    my $msgstr= "times$forstr: ".join(", ",@$d)."\n";
    if (my $out= $$args{out}) {
        if (ref ($out) eq "ARRAY") {
            push @$out, $msgstr
        } elsif (ref ($out) eq "SCALAR") {
            $$out= $msgstr
        } elsif (is_filehandle $out) {
            print $out $msgstr
        } else {
            warn "don't know how to output to '$out'";
        }
    } else {
        warn $msgstr;
    }
    $wantarray ? @res : $res[0]
}


1
