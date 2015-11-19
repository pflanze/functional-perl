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

(NOTE: the author of the functional-perl repl didn't know about the
`reply` repl and maybe others when finishing the work on this; he
originally started Chj::repl more than a decade ago. It would probably
be best to merge the efforts: TODO.)

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
character less to type and looks nicer:

    repl> list(2,3,4)->fold(*cons, null)
    $VAR1 = list(4, 3, 2);

You can get the first element of a list using the `first` method, and
the rest of the list using the `rest` method. There's also a combined
`first_and_rest` method which is basically the inverse of the `cons`
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
`Eval::WithLexicals` (a former version of the code used
`Lexical::Persistence`). If you install it and then enter

    repl> :m

then it will carry over lexical variables from one entry to the next:

    repl> my $x=10
    $VAR1 = 10;
    repl> $x
    $VAR1 = 10;

This also enables `use strict "vars"` as well as
`Eval::WithLexicals`'s default prelude (`use strictures`) if
`strictures` is installed.  If you don't want the former, enter `:M`
instead (TODO: check that this is working).


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


## More about cons

`cons` is a function that tries to call the cons *method* on its
second argument, and failing that, builds an `FP::List::Pair`. This
means that these are equivalent:

    repl> cons 2, cons 3, null
    $VAR1 = list(2, 3);
    repl> null->cons(3)->cons(2)
    $VAR1 = list(2, 3);

but the cons *function* can also be used to build pairs holding
non-lists as their rest value: those are called "improper lists".

    repl> cons 2, 3
    $VAR1 = improper_list(2, 3);

`FP::List` is the only sequence data structure that allows this. We'll
see later (streams) why this is important.

(TODO: "function" is ambiguous: do I mean "purely functional
callable", or do I mean "non-method subroutine"? Those are
orthogonal. Find better terminology.)

The functional-perl project provides other sequence data structures,
too. Here's one:

    repl> cons 1, cons 2, strictnull
    $VAR1 = strictlist(1, 2);
    repl> is_strictlist $VAR1
    $VAR1 = 1;

All functional-perl data structures come with a predicate function,
`is_strictlist` in this case, that returns true iff the argument is
what the predicate name stands for. You might be thinking that
`$VAR1->isa("FP::StrictList")` would be all that's required, but then
to avoid failing on non-objects you'd really need
`UNIVERSAL::isa($VAR1, "FP::StrictList")`, or since that returns true
for strings you'd *really* need `ref ($VAR1) and UNIVERSAL::isa($VAR1,
"FP::StrictList")` (or, since the "0" package would give false in the
first check, `length ref ($VAR1) and UNIVERSAL::isa($VAR1,
"FP::StrictList")`). Also, while that latter check would be right for
strictlists, a similar test would not be right for `FP::List` lists if
you want to know whether they are *proper* lists (i.e. precluding the
`cons 2, 3` case from above): for that you need to walk the list. The
`is_list` function from `FP::List` does that. Also, the predicates are
forcing evaluation of their argument if it's a promise (we'll come to
lazy evaluation soon.) That's why functional-perl data structures
come with predicate functions.

The advantages of the strictlists are that `is_strictlist` only needs
to check the first cell to know that it's a proper list. Also, each
cell carries the length of the list, thus `length` is O(1) as well,
unlike in the `FP::List` case where determining the length involves
walking the whole list. Usually those points don't matter, but
sometimes they do. The disadvantage of strictlists is that they can't
be evaluated lazily, a topic we'll look into in the next section.

## Lazy evaluation

Perl, like most traditional programming languages, is evaluating
exressions and statements eagerly: a statement occurring before a
semicolon is evaluated before the statement after it, and expressions
in argument position of a subroutine or method call are evaluated
before the statements in the subroutine are evaluated. This means for
example that we get this behaviour:

    repl> fun inverse ($x) { 1 / $x }
    repl> fun or_square ($x,$y) { $x || $y * $y }
    repl> or_square 2, inverse 0
    Exception: Illegal division by zero at (eval 137) line 1.
    repl 1> 

Of course, `inverse` fails. But note that the result of `inverse` is
not even used in this case. If Perl would evaluate the `inverse 0`
expression lazily, there would be no failure.

    repl> or_square 2, lazy { inverse 0 }
    $VAR1 = 2;

Only when `$y` is actually used, we get the exception:

    repl> or_square 0, lazy { inverse 0 }
    Exception: Illegal division by zero at (eval 139) line 1.
    repl 1> 

Alternatively we could redefine inverse to evaluate its body lazily:

    repl> fun inverse ($x) { lazy { 1 / $x } }
    Subroutine inverse redefined at (eval 143) line 1.
    repl> or_square 2, inverse 0
    $VAR1 = 2;
    repl> or_square 0, inverse 0
    Exception: Illegal division by zero at (eval 137) line 1.
    repl 1> 

This is usually better since the knowledge about the need for lazy
evaluation is kept locally here, and the `lazy` keyword has to be used
only once instead of at every call site.

Lazy terms are represented by a data structure we'll call a *promise*,
since that's what Scheme and some other languages have called them way
before JavaScript came and started using the term for something rather
different. The `:s` pretty-printing in the repl shows them like this:

    repl> inverse 2
    $VAR1 = lazy { "DUMMY" };
    repl> $VAR1 + 1
    $VAR1 = '1.5';

The `Data::Dumper` mode shows:

    repl> :d inverse 2
    $VAR1 = bless( [
                     sub { "DUMMY" },
                     undef
                   ], 'FP::TransparentLazy::Promise' );

`repl+` imports `lazy` from `FP::TransparentLazy`. There's also
`FP::Lazy`, which works the same way except it does not use overload
to force terms transparently:

    repl> use FP::Lazy; lazy { 1 / 0 }
    $VAR1 = bless( [
                     sub { "DUMMY" },
                     undef,
                     ''
                   ], 'FP::Lazy::Promise' );
    repl> $VAR1 + 1
    $VAR1 = 159389673;

The `159389673` value comes from adding 1 to the pointer address. Perl
can be pretty dangerous (this is a more general problem, thus it's not
being addressed here (by overloading to an
exception)). `FP::Lazy::Promise` objects need to be forced
explicitely:

    repl> lazy { 1 / 2 }->force + 1
    $VAR1 = '1.5';
    repl> lazy { 1 / 0 }->force + 1
    Exception: Illegal division by zero at (eval 146) line 1.
    repl 1> 

There's a `force` *function*, too, which will not die when its
argument is not a promise:

    repl> force 3
    $VAR1 = 3;
    repl> force lazy { 3 }
    $VAR1 = 3;

The reason that functional-perl offers `FP::Lazy` (and actually
prefers to use it throughout its other data structures) is that the
author fears that transparent laziness might make things more
difficult to understand or debug (also, forcing values explicitely
once and store the result would be faster than implicitely forcing
them by way of overload multiple times, thus being aware of the
promises could result in a speed benefit). Perhaps those worries are
unfounded and the future lies in just using transparent promises
everywhere.

To end this section, let's see what happens to promises when they are
evaluated:

    repl> our $v= do { my $x= 4; lazy { warn "evaluating"; 1 / $x } }
    $VAR1 = bless( [
                     sub { "DUMMY" },
                     undef,
                     ''
                   ], 'FP::Lazy::Promise' );
    repl> force our $v
    evaluating at (eval 152) line 1.
    $VAR1 = '0.25';
    repl> our $v
    $VAR1 = bless( [
                     undef,
                     '0.25',
                     ''
                   ], 'FP::Lazy::Promise' );

As you can see, before forcing the promise, it contains a subroutine
(closure) as the first field; after evaluation, the subroutine is
gone, and instead the result is stored in its second field. This is to
enforce that the lazy term is at most evaluated once. As you can see,
there's no "evaluating" warning when forcing it again:

    repl> force our $v
    $VAR1 = '0.25';

Let's switch back to the `:s` view mode:

    repl> :s our $v
    $VAR1 = '0.25';

It shows evaluated promises as their value directly. This is useful
when dealing with bigger, lazily evaluated data structures.

    repl> our $l= list(3,2,1,0,-1)->map(*inverse)
    $VAR1 = list(lazy { "DUMMY" }, lazy { "DUMMY" }, lazy { "DUMMY" }, lazy { "DUMMY" }, lazy { "DUMMY" });

There's a function `F` which returns a deep copy of its argument with
all the promises forced:

    repl> F our $l
    Exception: Illegal division by zero at (eval 137) line 1.
    repl 1> 

Yes, it will fail here; but we can still see how far it went, since
the promises in the original data structure are the same that are
being forced:

    repl> our $l
    $VAR1 = list('0.333333333333333', '0.5', '1', lazy { "DUMMY" }, lazy { "DUMMY" });

For an example of using `F` that finishes, let's skip (drop) past the
element of the list that gives the error:

    repl> our $l->drop(4)
    $VAR1 = list(lazy { "DUMMY" });
    repl> F $VAR1
    $VAR1 = list('-1');


## Writing a list-generating function

So far we have just created lists explicitely (using the `list` or
`strictlist` functions or nested calls to `cons`) and used list
functions/methods on them (like map, filter, fold). Sometimes there's
no pre-made function or method available for a task and you'll have to
write it yourself. Let's go through that process by creating the list
from the above section ('Lazy evaluation') programmatically. (This is
a somewhat bad example as this would be better achieved by combining a
series building function and map, but let's not worry about doing
things the high-level way too much when we don't know how to build the
lower levels.)

Let's also see how we can do this without doing a single mutation (all
variables are only ever assigned a single time, when they are
introduced, and no mutable data structure is used).

So we want to build a list that contains the `inverse` of the integer
values from 3 to -1 in sequence.

So, the first cell is going to hold `inverse(3)` as its value, and the
remainder of the list (i.e. holding `inverse(2)` etc.) as its
rest. Let's see how we can state this recursively:

    repl> fun inverse ($x) { lazy { 1 / $x } }
    repl> fun ourlist ($i) { cons inverse($i), ourlist($i-1) }

Well, we need a termination condition.

    repl> fun inverse ($x) { lazy { 1 / $x } }
    repl> fun ourlist ($i) { $i >= -1 ? cons inverse($i), ourlist($i-1) : null }
    repl> our $l= ourlist 3
    $VAR1 = list(lazy { "DUMMY" }, lazy { "DUMMY" }, lazy { "DUMMY" }, lazy { "DUMMY" }, lazy { "DUMMY" });
    repl> F our $l->drop(4)
    $VAR1 = list('-1');
    repl> F our $l
    Exception: Illegal division by zero at (eval 136) line 1.
    repl 1> (ctl-d)
    Illegal division by zero at (eval 136) line 1.
    repl> our $l
    $VAR1 = list('0.333333333333333', '0.5', '1', lazy { "DUMMY" }, '-1');

There we are.


## Streams

In the two sections above we have seen a list holding unevaluated
terms (promises). So, each list pair (cons cell) held a lazy
(unevaluated) term in its value slot, and an eagerly evaluated term in
its rest slot.

What if we made the rest slot contain a lazily evaluated term as well?
Well, let's simply try:

    repl> fun inverse ($x) { lazy { 1 / $x } }
    repl> fun ourlist ($i) { $i >= -1 ? cons inverse($i), lazy{ ourlist($i-1) } : null }
    repl> our $l= ourlist 3
    $VAR1 = improper_list(lazy { "DUMMY" }, lazy { "DUMMY" });

The 'improper_list' here is really just a single cons cell (pair)
holding lazy terms both in its value and rest slots, as we were asking
for. Is it correct?

    repl> our $l->first->force
    $VAR1 = '0.333333333333333';
    repl> our $l->rest->force
    $VAR1 = improper_list(lazy { "DUMMY" }, lazy { "DUMMY" });

The rest element, when forced, is again a cell holding lazy terms, of
course. This time it's the cell holding:

    repl> $VAR1->first->force
    $VAR1 = '0.5';

Let's apply `F` to the whole thing: as mentioned above, it will force
all promises on its way, regardless whether they are in value or rest
slots:

    repl> F our $l
    Exception: Illegal division by zero at (eval 136) line 1.
    repl 1> 
    Illegal division by zero at (eval 136) line 1.
    repl> F our $l->drop(4)
    $VAR1 = list('-1');
    repl> our $l
    $VAR1 = list('0.333333333333333', '0.5', '1', lazy { "DUMMY" }, '-1');

We're getting the same thing as before--unsurprisingly, since all we
changed was make the rest slot lazy, once we apply force (use the
force, Luke), the result will be the same. Having the rest slots
evaluate lazily is interesting, though: our list generation now might
survive with our original definition of `inverse`, if we're only
forcing the first few cells:

    repl> fun inverse ($x) { 1 / $x }
    repl> fun ourlist ($i) { $i >= -1 ? cons inverse($i), lazy{ ourlist($i-1) } : null }
    repl> our $l= ourlist 3
    $VAR1 = improper_list('0.333333333333333', lazy { "DUMMY" });

See how the first value is evaluated right away now; but we still
don't get a division by zero error since not even the spine of the
rest of the list is evaluated yet.

Feel free to do your forcing of the above to see how it behaves.

Another interesting observation we can make is that we don't really
need the termination condition anymore now:

    repl> fun ourlist ($i) { cons inverse($i), lazy{ ourlist($i-1) } }
    repl> our $l= ourlist 3
    $VAR1 = improper_list('0.333333333333333', lazy { "DUMMY" });

Since we'll be bombing out at 1/0 anyway before reaching 1/-1, the end
condition was pointless here anyway :).

But we have "invented" a new data structure here: lazy linked lists,
or functional streams as they are also called. The functional-perl
project provides functions/methods to work with these, too:

    repl> our $l->drop(10)
    Exception: Illegal division by zero at (eval 136) line 1.

Ok, to be able to skip over that, we'd have to go back to our second
definition of `inverse`. But anyway, we could also start at a safer
location:

    repl> our $l= ourlist -1
    $VAR1 = improper_list('-1', lazy { "DUMMY" });
    repl> our $l->take(10)
    $VAR1 = list('-1', '-0.5', '-0.333333333333333', '-0.25', '-0.2', '-0.166666666666667', '-0.142857142857143', '-0.125', '-0.111111111111111', '-0.1');

Note that `take` worked eagerly here. This is because the cell that it
was invoked on was a non-lazy value, thus an implementation of `take`
was selected that doesn't work lazily. Also, realize that our current
definition of `ourlist` always returns an already-evaluated cell; only
the cell's rest slot is lazy, the cell itself exists right away when
returning from `ourlist`. In general, it's a better idea to make the
first cell lazy as well, it's more consistent. It's easy enough, too:
simply move the lazy keyword to enclose the whole cell generation
instead only its rest slot (the rest slot will be lazy itself, too,
since recursing into ourlist will again return a lazy term):

    repl> fun ourlist ($i) { lazy { cons inverse($i), ourlist($i-1) } }
    Subroutine ourlist redefined at (eval 145) line 1.
    repl> our $l= ourlist -1
    $VAR1 = lazy { "DUMMY" };
    repl> our $l->take(10)
    $VAR1 = lazy { "DUMMY" };

Now the direct result of ourlist is lazy, too, and the take method
returned a lazy term, as well. Let's force it:

    repl> F $VAR1
    $VAR1 = list('-1', '-0.5', '-0.333333333333333', '-0.25', '-0.2', '-0.166666666666667', '-0.142857142857143', '-0.125', '-0.111111111111111', '-0.1');

This is, incidentally, basically how Haskell's evaluation strategy
works internally (putting aside compiler optimizations). You don't
have to write `lazy` keywords in Haskell since it's lazy by default
(but in fact you'd write eager keywords instead if you *don't* want a
term to be evaluated lazily), but internally it will amount to the
same evaluation (again, as long as the compiler doesn't change
things); Haskell implementors prefer to call the promises "thunks". In
some other languages like Ocaml or Scheme people work exactly like
described above. In yet other languages, like Clojure or Perl 6, the
lazy workings of sequences is more hidden, so you don't (usually) get
to write code creating individual cells with lazy terms like this (the
advantage is that different representations than lazily linked lists
can be used at runtime like iterators, perhaps at the cost of becoming
a leaky abstraction, like when re-forcing a stream from the
beginning).


## More streams

Streams can be used to represent file lines, directory items, socket
messages etc., if one gives in to the somewhat unsafe notion of
assuming that those files or directories are not modified while
reading them (lazily!). If that assumption doesn't hold up, then you
may end up being surprised that you're getting different values than
you were expecting when first opening the directory or
stream. Nonetheless, it's what people in Clojure and Perl 6 and surely
other languages with streams are doing all the time. (Haskell ditched
this approach a while ago for its unsafety, and instead now provides
alternatives that can't break the guarantees that its type system
gives.)

Example (Clojure calls xfile_lines `lineseq`): 

    repl> system("echo 'Hello\nWorld.\n' > ourtestfile.txt")
    $VAR1 = 0;
    repl> our $l= xfile_lines("ourtestfile.txt")
    $VAR1 = lazy { "DUMMY" };
    repl> $l->first
    $VAR1 = 'Hello
    ';
    repl> $l->rest
    $VAR1 = lazy { "DUMMY" };

At this point it might still not have read the second line from the
file; saying "might" since probably Perl buffers the input file in
bigger blocks. Anyway, you could do:

    repl> our $l= fh_to_chunks xopen_read("/dev/zero"), 10
    $VAR1 = lazy { "DUMMY" };
    repl> $l->first
    $VAR1 = '^@^@^@^@^@^@^@^@^@^@';
    repl> $l->drop(1000)->first
    $VAR1 = '^@^@^@^@^@^@^@^@^@^@';

(Or replace /dev/zero with /dev/urandom.)

The nice thing of this is that you can stop writing for or while loops
now, and you can build up a processing chain similar to how you can
write pipelines in the shell. You can write a function that takes a
stream and returns a processed stream, and pass that to another
function that does some other processing, and group those two
functions into one which you can then group together with other
grouped-up ones. Just like you can write shell scripts that use a
pipeline and then pipe up those scripts themselves as if they were
"atoms".

For more examples using lazy evaluation and streams, see
`FP::IOStream`, `FP::Text::CSV`, `FP::DBI`,
[functional_XML](../functional_XML/README.md) and the [example
scripts](../examples/).

There's a catch, though, currently: unlike programming language
implementations that have been written explicitely to deal with the
functional programming style, the Perl implementation does not release
variables and subroutine arguments as early as theoretically possible,
which means that when calling subroutines that are consuming streams
(like `drop`) the head of the stream would not be released while
walking it, which would mean that the program could run out of
memory. The functional-perl libraries go to some pains to work around
the issue by weakening the subroutine argument slots (in `@_`). More
concretely, this means that after calling `drop` in the example above,
`$l` has been weakened, and if there's no other strong reference
holding the head of the stream, then it becomes undef. This means when
you try to run the same expression again, you get:

    repl> $l->drop(1000)->first
    Exception: Can't call method "drop" on an undefined value at (eval 147) line 1.
    repl 1> 

You can prevent this manually by protecting `$l` using the `Keep` function:

    repl> our $l= fh_to_chunks xopen_read("/dev/urandom"), 10
    $VAR1 = lazy { "DUMMY" };
    repl> Keep(our $l)->drop(1000)->first
    $VAR1 = '<94> )&m^C<8C>ESC<AB>A';
    repl> Keep(our $l)->drop(1000)->first
    $VAR1 = '<94> )&m^C<8C>ESC<AB>A';

There is hope that we might find a better way to deal with this
(implement variable life time analysis as a pragma/module), but no
promises here!


## TODO

* `fix`
* iteration / TCO
* testing

</with_toc>
