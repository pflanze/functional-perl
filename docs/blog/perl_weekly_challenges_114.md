Check the [functional-perl website](http://functional-perl.org/) for
properly formatted versions of these documents.

---

# The Perl Weekly Challenges, #114

<small><i>[Christian J.](mailto:ch@christianjaeger.ch), 30 May 2021</i></small>

I solved (most of) the first challenge earlier this week, but
something got inbetween at the end of the week so I can't do the
second challange or properly clean up and document the first
one. Here's what I can say quickly. I'll try to get back and do a
better write up later. Send me a note by mail (see link above) and
I'll send you a reply once I've done that.

Also check out my [first post](perl-weekly-challenges-113.md) about
the Perl Weekly Challenges, it explains various things about
`FunctionalPerl` that I won't go into again.

<with_toc>

## Task #1: Next Palindrome Number

The task description is
[here](https://perlweeklychallenge.org/blog/perl-weekly-challenge-114/#TASK1),
my solution is
[here (functional-perl repository)](../../examples/perl-weekly-challenges/114-1-Next_Palindrome_Number) and
[here (perlweeklychallenge repository)](https://github.com/manwar/perlweeklychallenge-club/blob/master/challenge-114/christian-jaeger/perl/ch-1.pl).

### Brute force solution

This is really easy to solve via brute force:

    sub is_palindrome($n) {
        "$n" eq string_reverse "$n"
    }

    sub next_palindrome_number__brute($n) {
        stream_iota($n + 1)->filter(\&is_palindrome)->first
    }

This just iterates through all the numbers from 1.., retains those
which are palindromes, and takes the first of those. Since this
executes lazily, it also stops once the first has been found.

The only question I ran into here was, how do I actually reverse a
string in Perl. Yes, `join('', reverse split //, $str)` does the
trick, but is that efficient enough not to worry about the
intermediate list generation? Or does the interpreter optimize this? I
haven't had the time to find out. Also, of course, plenty of
intermediate data structures are gonna be used when you use
`FunctionalPerl`, so I shouldn't be the one to ask here? But OTOH,
reverting the string is happening a lot here. So I wrote a quick
attempt at being more efficient (no time to benchmark...).

In any case, this isn't efficient, the larger `$n` is, the longer
until it finds a palindrome. We can do better.

### Efficient solution

I'll have to get back and take this apart for you, but the idea is
simply, that the left half of the result mirrors the right half, and
must be larger than `$n`, hence the left half of the result must be
either equal or 1 larger than the left half of `$n`.

The code is probably more convoluted than it could be. Again, haven't
found the time to give it proper attention.

Also, this triggered recursion warnings in two places in `FP::List`
and `FP::Lazy` (see Git history), and the first seems like pointing to
a bug with my libraries so I'll have to investigate. The code does use
memory ("leaks") while it shouldn't, due to this.

    sub complete_odd($left) {
        $left . string_reverse substr $left, 0, length($left) - 1
    }

    sub complete_even($left) {
        $left . string_reverse $left
    }

    TEST { complete_odd 991 } '99199';
    TEST { complete_even 991 } '991199';

    sub complete ($left, $is_oddlen, $n) {
        my $n2 = $is_oddlen ? complete_odd $left : complete_even $left;
        warn "complete($left, $is_oddlen, $n), n2=$n2" if $verbose;
        if ($n2 <= $n) {
            my $left2      = $left + 1;
            my $is_overrun = length($left2) > length($left);
            unless ($is_overrun) {
                complete($left2, $is_oddlen, $n)
            } else {
                if ($is_oddlen) {
                    complete(substr($left2, 0, length($left2) - 1), 0, $n)
                } else {
                    complete($left2, 1, $n)
                }
            }
        } else {
            $n2
        }
    }

    sub next_palindrome_number__optim($n) {
        my $str = "$n";          # yeah, not necessary, but I like to be explicit
        my $len = length $str;
        my $leftlen = int($len / 2 + 0.5);
        my $left    = substr $str, 0, $leftlen;
        complete $left, is_odd($len), $n
    }

</with_toc>

<p align="center"><big>⚘</big> &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;</p>

<em>If you'd like to comment, please see the instructions [here](index.md).</em>

