Check the [functional-perl website](http://functional-perl.org/) for
properly formatted versions of these documents.

---

# Introduction to using the functional perl modules

Unlike the other documentation materials (as listed in [[README]]),
this tries to give a nice introduction to using the modules and
programs that this project offers. (The files in the
[intro/](../intro/) directory are more on the fundamental side, also
they are a bit older and possibly could use some updating (todo).)

<with_toc>

## Starting up: the REPL

Functional programming languages usually come with a read-eval-print
loop (REPL). A REPL reads a statement or expression, evaluates it and
prints its result. The better ones come with debugging features, like
being able to inspect the context (stack) from where they were
called. Functional perl is no exception on either account.

There are three ways to run the functional-perl REPL:

 - Run it from somewhere in your program by using `use Chj::repl;` and
   calling `repl;`.
 - Register the repl to be run upon encountering uncatched exceptions
   by adding `use Chj::Trapl;` somewhere to your code.
 - Run the [bin/repl](../bin/repl) script, which takes the `-M` option
   like perl itself to load modules of your choice. Or
   [bin/repl+](../bin/repl+) which calls the repl with the most
   interesting modules preloaded.

In this section we're going to use the latter. You need to install
`Term::ReadLine::Gnu` and `PadWalker` to use the repl. Once you've
done that, from the shell run:

    $ cd functional-perl
    $ bin/repl+
    repl> 

The string left of the ">" indicates the current namespace, "repl" in
this case. Let's try some math:

    repl> 1+2
    $VAR1 = 3;

You can refer to the given $VAR1 etc. variables in subsequent entries:

    repl> $VAR1*2
    $VAR1 = 6;
    repl> $VAR1*2
    $VAR1 = 12;
    repl> $VAR1*2,$VAR1+1
    $VAR1 = 24;
    $VAR2 = 13;

If you happen to produce an error at run time of the code that you
enter, you will be in a sub-repl (this happens since `bin/repl` also
loads `Chj::Trapl` (well, it uses `Chj::WithRepl` directly for the
same purpose)):

    repl> foo()
    Exception: Undefined subroutine &repl::foo called at (eval 143) line 1.
    repl 1> 

In that case, you can return to the parent repl by pressing ctl-d.


## Lists the functional way

One of the most basic features of functional programming are singly
linked lists. Those can be extended in a purely functional way,
i.e. without changing existing list references. Lists can be created
using the `list` function from `FP::List`, which is preloaded in
repl+:

    repl> list()
    $VAR1 = bless( [], 'FP::List::Null' );

The given answer is the object that represents the empty list. It is
unique across the system, i.e. a singleton:

    repl> use Scalar::Util qw(refaddr);  refaddr(list()) == refaddr(list())
    $VAR1 = 1;

The empty list can also be gotten from the `null` function:

    repl> null
    $VAR1 = bless( [], 'FP::List::Null' );

You can prepend new items to an existing list using the `cons`
function, which pairs up its two arguments:

    repl> cons 3, null
    $VAR1 = bless( [
		     3,
		     bless( [], 'FP::List::Null' )
		   ], 'FP::List::Pair' );

Now these `Data::Dumper` style printouts don't look very nice, you'll
agree. The repl can do better, just tell it so with a repl (meta)
command:

    repl> :s
    repl> cons 3, null
    $VAR1 = list(3);

To see a list of all repl commands enter `:?`. You can also use the
comma `,` instead of the colon if you prefer. The repl remembers these
settings across repl runs (they are stored in ~/.perl-repl_settings).

So, yes, `cons 3, null` is equivalent to `cons 3, list()` which is
equivalent to `list(3)`, and the :s representation uses perl code to
construct the given result using existing constructor functions. (How
the repl knows which perl function to show is by way of a
`FP_Show_show` method on the object in question, which is called
through the `show` function in the `FP::Show` module. The indirection
through the `show` function (versus calling the method directly) is
that `show` also works on inputs that are not objects or don't have an
`FP_Show_show` method.)

As you've already seen above, linked lists are objects, and they come
with a broad set of useful methods, for example:

    repl> list(2,3,4)->map(sub { $_[0] * $_[0] })
    $VAR1 = list(4, 9, 16);
    repl> list(2,3,4)->filter(sub { $_[0] % 2 })
    $VAR1 = list(3);

You may be asking why `filter` is not called `grep`; the answer is
that filter is the commonly used name for this in functional
programming languages.

Here's a function/method that does not have a pendant as a Perl
builtin, but is common to functional programming: 

    repl> list(2,3,4)->fold(sub { $_[0] + $_[1] }, 0)
    $VAR1 = 9;

Fold takes a subroutine and an initial value, then for each value in
the sequence calls the subroutine, passing it the value from the list
and the initial value, then uses the result of the subroutine instead
of the initial value for the next iteration.

What if you would use `cons` instead of `+`? 

    repl> list(2,3,4)->fold(sub { cons $_[0], $_[1] }, null)
    $VAR1 = list(4, 3, 2);

As you can see, it paired up (prepended) the value 2 with (to) the
empty list, then prepended 3 to that, then prepended 4 to that. The
result comes in reverse order. If that's not what you need, there's
also `fold_right`:

    repl> list(2,3,4)->fold_right(sub { cons $_[0], $_[1] }, null)
    $VAR1 = list(2, 3, 4);

Maybe you've already thought that writing the sub { } here is
pointless: all it does is pass on its arguments unmodified to
cons. Eliminating it:

    repl> list(2,3,4)->fold(\&cons, null)
    $VAR1 = list(4, 3, 2);

or you could also just pass the glob entry instead, which is a
character less to type and looks slightly nicer:

    repl> list(2,3,4)->fold(*cons, null)
    $VAR1 = list(4, 3, 2);

You can get the first element of a list using the `first` method, and
the rest of the list using the `rest` method. There's also a combined
`first_and_rest` method which is kind of the inverse of the `cons`
function:

    repl> list(2,3,4)->first
    $VAR1 = 2;
    repl> list(2,3,4)->rest
    $VAR1 = list(3, 4);
    repl> list(2,3,4)->first_and_rest
    $VAR1 = 2;
    $VAR2 = list(3, 4);

Let's see why linked lists are actually interesting. Here we are
assigning values to package variables (globals), by default the repl
does not 'use strict "vars"' thus we don't need to prefix them with
"our":

    repl> $a= list 3,4,5
    $VAR1 = list(3, 4, 5);
    repl> $b= $a->rest
    $VAR1 = list(4, 5);
    repl> $c= cons 2, $b
    $VAR1 = list(2, 4, 5);
    repl> $b
    $VAR1 = list(4, 5);
    repl> $a
    $VAR1 = list(3, 4, 5);

As you can see, $a and $b still contain the elements they were
originally assigned. Compare this with using arrays:

    repl> $a= [3,4,5]
    $VAR1 = [3, 4, 5];

Now to drop the first element, you could use shift, but:

    repl> $b=$a
    $VAR1 = [3, 4, 5];
    repl> shift @$b
    $VAR1 = 3;
    repl> $a
    $VAR1 = [4, 5];

`shift` is not a (pure) function, but a procedure: a pure function
does not "harm" its arguments, instead the only effect it has on the
world visible to your program is returning a value. `shift` violates
this principle (thus the name "procedure" which indicates that it does
achieve things by way of side effects) and hence $a, which points to
the same in-memory data structure, is also modified. You'd have to
first create a full copy of the array so that when you modify it with
shift the original stays unmodified:

    repl> $a= [3,4,5]
    $VAR1 = [3, 4, 5];
    repl> $b=[@$a]
    $VAR1 = [3, 4, 5];
    repl> shift @$b
    $VAR1 = 3;
    repl> $a
    $VAR1 = [3, 4, 5];

This works, and it can be hidden in pure functions, in fact
functional-perl provides them already:

    repl> $a= [3,4,5]
    $VAR1 = [3, 4, 5];
    repl> $b= array_rest $a
    $VAR1 = [4, 5];
    repl> $a
    $VAR1 = [3, 4, 5];

`array_rest` internally does the copy and shift thing. The problem
with this is that it doesn't scale, the longer your array, the longer
it takes to copy. That's why linked lists are interesting when you
want to work with pure functions. (There are also other data
structures that implement lists and are functional (aka "persistent")
and offer other features like accessing or removing the last element
efficiently or accessing random elements in O(log n) or even O(1)
instead of O(n) time, but they haven't been implemented in
functional-perl yet.)


## More REPL features

The repl automatically makes their special syntax available if one of
these modules is loaded, and [bin/repl+](../bin/repl+) automatically
tries to load them if present on the system: `Function::Parameters`,
`Method::Signatures`, `Sub::Call::Tail`. Since Function::Parameters
simplifies writing functions a lot and works better in some ways than
Method::Signatures, we're going to use it from now on. If you don't
have it installed, do that now and then restart the repl+ (first exit
it by typing ctl-d, or :q -- note that currently :q prevents it from
saving the history (todo)). Now you can type the nicer:

    repl> list(3,4,5)->map(fun($x){ $x*$x })
    $VAR1 = list(9, 16, 25);

Another module that might make life better in the repl is
`Lexical::Persistence`. If you install it and then enter

    repl> :m

then it will carry over lexical variables from one entry to the next:

    repl> my $x=10
    $VAR1 = 10;
    repl> $x
    $VAR1 = 10;

This also enables `use strict "vars"` (if you don't want that, enter
`:M` instead).


## Fresh lexicals and closures

Let's disable lexical persistence for a moment and try some closures:

    repl> :X
    repl> $a=10; $f1= sub { $a }
    $VAR1 = sub { "DUMMY" };
    repl> $a=11; $f2= sub { $a }
    $VAR1 = sub { "DUMMY" };
    repl> &$f1()
    $VAR1 = 11;

The two subroutines are referring to the same instance of a variable,
and setting that variable to a new value also changes what the first
subroutine sees. This, just like with the mutation of a shared array,
is not functional. (As an implementation detail of perl, these don't
even really capture the variable, i.e. these subroutines are not
closures.)

Enabling lexical persistence again:

    repl> :m
    repl> my $a=10; my $f1= sub { $a }
    $VAR1 = sub { "DUMMY" };
    repl> $a=11; my $f2= sub { $a }
    $VAR1 = sub { "DUMMY" };
    repl> &$f1()
    $VAR1 = 11;

Ah, we still assigned a new value to the old *instance* of `$a`! Still
not functional (even though in this case we *are* really creating
closures as per the perl implementation regime). Another attempt:

    repl> my $a=10; my $f1= sub { $a }
    $VAR1 = sub { "DUMMY" };
    repl> my $a=11; my $f2= sub { $a }
    $VAR1 = sub { "DUMMY" };
    repl> &$f1()
    $VAR1 = 11;

Oh, actually there's something fishy going on, with
`Lexical::Persistence`? TODO.

Let's do it again this way:

    repl> my $f1= do { my $a=10; sub { $a } }
    $VAR1 = sub { "DUMMY" };
    repl> my $f2= do { my $a=11; sub { $a } }
    $VAR1 = sub { "DUMMY" };
    repl> &$f1()
    $VAR1 = 11;

still no. Let's disable Lexical::Persistence.

    repl> :X
    repl> $f1= do { my $a=10; sub { $a } }
    $VAR1 = sub { "DUMMY" };
    repl> $f2= do { my $a=11; sub { $a } }
    $VAR1 = sub { "DUMMY" };
    repl> &$f1()
    $VAR1 = 10;

Yeah, now it works as it should.

Sorry about that, I hope you still got the idea: the safe and
functional way is to use fresh instances of lexical variables,
initializing them to a value and then leave them alone (not mutate
them).


    repl> :m
    repl> my ($f1,$f2)= (do { my $a=10; sub { $a } }, do { my $a=11; sub { $a } })
    $VAR1 = sub { "DUMMY" };
    $VAR2 = sub { "DUMMY" };
    repl> &$f1
    $VAR1 = 11;
    repl> &$f2
    $VAR1 = 11;

hmmm. but yes, really:

    repl> :X
    repl> ($f1,$f2)= (do { my $a=10; sub { $a } }, do { my $a=11; sub { $a } })
    $VAR1 = sub { "DUMMY" };
    $VAR2 = sub { "DUMMY" };
    repl> &$f1
    $VAR1 = 10;
    repl> &$f2
    $VAR1 = 11;

    repl> :m
    repl> our ($f1,$f2)= (do { my $a=10; sub { $a } }, do { my $a=11; sub { $a } })
    $VAR1 = sub { "DUMMY" };
    $VAR2 = sub { "DUMMY" };
    repl> our $f1; &$f1
    $VAR1 = 11;

    repl> $Lexical::Persistence::VERSION 
    $VAR1 = '1.020';


</with_toc>
