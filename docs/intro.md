Check the [functional-perl website](http://functional-perl.org/) for
properly formatted versions of these documents.

---

# Introduction to using the functional-perl modules

Unlike the other documentation materials (as listed in [[README]]),
this tries to give a nice introduction to using the modules and
programs that this project offers. (The files in the
[intro/](../intro/) directory are more on the fundamental side, also
they are a bit older and possibly could use some updating (todo).)

If you've got questions, please tell, either on the [[mailing_list]],
or join [the IRC channel](//mailing_list.md).


<with_toc>


## Starting up: the REPL

Functional programming languages usually come with a read-eval-print
loop (REPL). A REPL reads a statement or expression, evaluates it and
prints its result. The better ones come with debugging features, like
being able to inspect the context (stack) from where they were
called. Functional Perl is no exception.

(NOTE: the author didn't know about the `reply` repl and maybe others
when finishing the work on this; he originally started `FP::Repl` in
2004. It might be worth merging the efforts.)

There are three ways to run the functional-perl REPL:

 - Run it from somewhere in your program by using `use FP::Repl;` and
   calling `repl;`.
 - Register the repl to be run upon encountering uncaught exceptions
   by adding `use Chj::Trapl;` somewhere to your code.
 - Run the [bin/repl](../bin/repl) script, which takes the `-M` option
   like perl itself to load modules of your choice. Or
   [bin/repl+](../bin/repl+) which calls the repl with the most
   interesting modules preloaded.

You need to install `Term::ReadLine::Gnu` and `PadWalker` to use the
repl. Once you've done that, from the shell run:

    $ cd functional-perl
    $ bin/repl+
    repl> 

The string left of the ">" indicates the current namespace, "repl" in
this case. Let's try:

    repl> 1+2
    $VAR1 = 3;

You can refer to the given $VAR1 etc. variables in subsequent entries:

    repl> $VAR1*2
    $VAR1 = 6;
    repl> $VAR1*2
    $VAR1 = 12;
    repl> $VAR1*2, $VAR1+1
    $VAR1 = 24;
    $VAR2 = 13;

If you happen to produce an error at run time of the code that you
enter, you will be in a sub-repl, indicated by the level number `1`
here:

    repl> foo()
    Exception: Undefined subroutine &repl::foo called at (eval 143) line 1.
    repl 1> 

In that case, you can return to the parent repl by pressing ctl-d. It
will then show (XX: currently it also shows the exception again; work
is under way to improve this):

    repl> 

(In case you really don't like this nesting feature, you can omit the
`-t` flag to the `repl` script (adapt the `repl+` wrapper script).)


## Lists the functional way

One of the most basic features of functional programming are singly
linked lists. Those can be extended and shrunk in a purely functional
way, i.e. without changing existing list references. Lists can be
created using the `list` function from `FP::List`, which is preloaded
in repl+:

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
agree. The repl can do better, just tell it so with a repl meta
command:

    repl> :s
    repl> cons 3, null
    $VAR1 = list(3);

To see a list of all repl commands enter `:?`. You can also use the
comma `,` instead of the colon if you prefer. The repl remembers these
settings across repl runs (they are stored in ~/.perl-repl_settings).

So, yes, `cons 3, null` is equivalent to `cons 3, list()` which is
equivalent to `list(3)`, and the :s representation shows perl code
that would construct the given result using existing constructor
functions. (How the repl knows how to print data structures is via the
`show` function in the `FP::Show` module.)

As you've already seen above, linked lists are objects, and they come
with a broad set of useful methods, for example:

    repl> list(2,3,4)->map(sub { $_[0] * $_[0] })
    $VAR1 = list(4, 9, 16);
    repl> list(2,3,4)->filter(sub { $_[0] % 2 })
    $VAR1 = list(3);

You may be asking why `filter` is not called `grep`; the answer is
that "filter" is the commonly used name for this in functional
programming languages.

Here's a function/method that does not have a pendant as a Perl
builtin, but is common to functional programming: 

    repl> list(2,3,4)->fold(sub { $_[0] + $_[1] }, 0)
    $VAR1 = 9;

Fold takes a subroutine and an initial value, then for each value in
the sequence calls the subroutine, passing it the value from the list
and the initial value, then uses the result of the subroutine instead
of the initial value for the next iteration. I.e. our examples adds up
all the values in the list.

Note how we create an anonymous subroutine to simply use the `+`
operator. We can't pass `+` directly, Perl does not have a way to pass
an operator as a subroutine (CODE ref) directly. To ease this pain,
Perl's operators are wrapped as functions (subroutines) in `FP::Ops`,
which is imported by `bin/repl+` already. The subroutine wrapping `+`
is called `add`.

    repl> add(1,2)
    $VAR1 = 3;

Thus we can write the following, equivalent to what we had above:

    repl> list(2,3,4)->fold(\&add, 0)
    $VAR1 = 9;

Or we can pass the glob entry instead of taking a reference--this is
simpler to type and looks better, in our opinion, and when the
subroutine is redefined the glob will call the new definition, which
is usually what you want, thus we're going to use this style from now
on:

    repl> list(2,3,4)->fold(*add, 0)
    $VAR1 = 9;

What if you would use `cons` instead of `+`? 

    repl> list(2,3,4)->fold(sub { cons $_[0], $_[1] }, null)
    $VAR1 = list(4, 3, 2);

The anonymous subroutine wrapper here is truly unnecessary, of course,
the following is getting rid of it:

    repl> list(2,3,4)->fold(*cons, null)
    $VAR1 = list(4, 3, 2);

As you can see, this prepended the value 2 to the empty list, then
prepended 3 to that, then prepended 4 to that. The result comes in
reverse order, i.e. this is an implementation of the list reversing
function (which is available as the method `reverse` already).

For the case when you need to process a list so that the original
ordering is preserved there's also `fold_right`, which reverses the
order of the call chain (it begins at the right of the list,
i.e. calling `cons(4, null)` first):

    repl> list(2,3,4)->fold_right(*cons, null)
    $VAR1 = list(2, 3, 4);

i.e. this simply copies the list, which is actually pointless: lists
are a purely functional data structure, i.e. they do not offer a way
to mutate parts destructively (unless if going evil and forgoing
object accessors, which is discouraged), hence this possible use of
copying is irrelevant. Of course there are other operations where the
ordering is relevant, for example division (`/` is wrapped as `div` by
`FP::Ops`):

    repl> list(10,20)->fold(*div, 1)
    $VAR1 = '2';
    repl> list(10,20)->fold_right(*div, 1)
    $VAR1 = '0.5';

(For another easy to try example, experiment with the `array` function
from `FP::Array`, which is a wrapper for `[@_]`. It too is already
imported by `repl+`.)

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

`shift` is not a (pure) function, but what would be called a
procedure: a pure function does not "harm" its arguments, instead the
only effect it has on the world visible to your program is returning a
value. `shift` violates this principle (thus the naming "procedure"
which indicates that it does achieve things by proceeding through a
recipe of issuing side effects) and hence $a, which points to the same
in-memory data structure, is also modified. You'd have to first create
a full copy of the array so that when you modify it with shift the
original stays unmodified:

    repl> $a= [3,4,5]
    $VAR1 = [3, 4, 5];
    repl> $b=[@$a]
    $VAR1 = [3, 4, 5];
    repl> shift @$b
    $VAR1 = 3;
    repl> $a
    $VAR1 = [3, 4, 5];

This works, and it can be hidden in pure functions, in fact
functional-perl provides them already (part of `FP::Array` and
imported by `repl+`):

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

If one of the following modules, which modify the Perl syntax, is
loaded, then the repl automatically makes them available to the
entered code.  Also, [bin/repl+](../bin/repl+) automatically tries to
load them if present on the system: `Function::Parameters`,
`Method::Signatures`, `Sub::Call::Tail`. Since Function::Parameters
simplifies writing functions a lot and works better in some ways than
Method::Signatures, we're going to use it from now on. If you don't
have it installed, do that now and then restart the repl+ (first exit
it by typing ctl-d, or :q -- note that currently :q prevents it from
saving the history (todo)). Now you can type the nicer:

    repl> list(3,4,5)->map(fun($x){ $x*$x })
    $VAR1 = list(9, 16, 25);

Another module which might make life better in the repl is
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


## More about cons

`cons` is a function that tries to call the cons *method* on its
second argument, and failing that, builds an `FP::List::Pair`. This
means that these expressions are equivalent:

    repl> cons 2, cons 3, null
    $VAR1 = list(2, 3);
    repl> null->cons(3)->cons(2)
    $VAR1 = list(2, 3);

but the cons *function* can also be used to build pairs holding
non-lists as their rest value: those are called "improper lists".

<small>(Todo: "function" is ambiguous: do I mean "purely functional
callable", or do I mean "non-method subroutine"? Those are
orthogonal. Find better terminology.)</small>

    repl> cons 2, 3
    $VAR1 = improper_list(2, 3);
    repl> cons 1, cons 2, 3
    $VAR1 = improper_list(1, 2, 3);

The `improper_list` function creates such a linked list that contains
its last argument directly as the rest value in the last cell. If
you're still unsure what this means, try turning to `:d` mode to see
the list's cells:

    repl> :d improper_list(1, 2, 3)
    $VAR1 = bless( [
                     1,
                     bless( [
                              2,
                              3
                            ], 'FP::List::Pair' )
                   ], 'FP::List::Pair' );

versus

    repl> :d list(1, 2, 3)
    $VAR1 = bless( [
                     1,
                     bless( [
                              2,
                              bless( [
                                       3,
                                       bless( [], 'FP::List::Null' )
                                     ], 'FP::List::Pair' )
                            ], 'FP::List::Pair' )
                   ], 'FP::List::Pair' );

`FP::List` is our only sequence data structure that allows this. We'll
see later (streams) why it is a feature and not a bug.

The functional-perl project provides other sequence data structures,
too. Here's one (turning `:s` back on):

    repl> :s cons 1, cons 2, strictnull
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

Perl, like most programming languages, is evaluating exressions and
statements eagerly: an expression used to set a variable is evaluated
before assigning its result to a variable and the variable assignment
happens before the code continues after its trailing semicolon, and
expressions in argument position of a subroutine or method call are
evaluated before the statements in the subroutine are evaluated. This
means for example that we get this behaviour:

    repl> fun inverse ($x) { 1 / $x }
    repl> fun or_square ($x,$y) { $x || $y * $y }
    repl> or_square 2, inverse 0
    Exception: Illegal division by zero at (eval 137) line 1.
    repl 1> 

Of course, `inverse` fails. But note that the result of `inverse` is
not even used in this case. If Perl would evaluate the `inverse 0`
expression lazily, there would be no failure. This can be changed by
using `lazy` from `FP::TransparentLazy` (`repl+` loads it already):

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
evaluation is kept locally, near the expression in question, and the
`lazy` keyword has to be used only once instead of at every call site.

Lazy terms are represented by a data structure called a *promise*. The
`:s` pretty-printing in the repl shows them like this:

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
being addressed here e.g. by overloading to an
exception). `FP::Lazy::Promise` objects need to be forced explicitely:

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
    repl> force $v
    evaluating at (eval 152) line 1.
    $VAR1 = '0.25';
    repl> $v
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

    repl> force $v
    $VAR1 = '0.25';

Let's switch back to the `:s` view mode:

    repl> :s $v
    $VAR1 = '0.25';

It shows evaluated promises as their value directly. This is useful
when dealing with bigger, lazily evaluated data structures.

    repl> our $l= list(3,2,1,0,-1)->map(*inverse)
    $VAR1 = list(lazy { "DUMMY" }, lazy { "DUMMY" }, lazy { "DUMMY" }, lazy { "DUMMY" }, lazy { "DUMMY" });

There's a function `F` which returns a deep copy of its argument with
all the promises forced:

    repl> F $l
    Exception: Illegal division by zero at (eval 137) line 1.
    repl 1> 

Yes, it will fail here; but we can still see how far it went, since
the promises in the original data structure are the same that are
being forced:

    repl> $l
    $VAR1 = list('0.333333333333333', '0.5', '1', lazy { "DUMMY" }, lazy { "DUMMY" });

For an example of using `F` that finishes, let's skip (drop) past the
element of the list that gives the error:

    repl> $l->drop(4)
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
things the high-level way too much while we don't know yet how to
build the lower levels.)

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
    repl> F $l->drop(4)
    $VAR1 = list('-1');
    repl> F $l
    Exception: Illegal division by zero at (eval 136) line 1.
    repl 1> (ctl-d)
    Illegal division by zero at (eval 136) line 1.
    repl> $l
    $VAR1 = list('0.333333333333333', '0.5', '1', lazy { "DUMMY" }, '-1');

There we are.


## Streams

In the two sections above we have seen a list holding unevaluated
terms (promises). So, each list pair (cons cell) held a lazy
(unevaluated) term in its value slot, and an eagerly evaluated term in
its rest slot (the rest of the list). (The list data structure,
i.e. the list cells excluding the actual values held in the list, is
also called the "spine".)

What if we made the rest slot contain a lazily evaluated term as well?
Well, let's simply try:

    repl> fun inverse ($x) { lazy { 1 / $x } }
    repl> fun ourlist ($i) { $i >= -1 ? cons inverse($i), lazy{ ourlist($i-1) } : null }
    repl> our $l= ourlist 3
    $VAR1 = improper_list(lazy { "DUMMY" }, lazy { "DUMMY" });

The 'improper_list' here is really just a single cons cell (pair)
holding lazy terms both in its value and rest slots, as we were asking
for. 

Will it evaluate to the correct values?

    repl> $l->first->force
    $VAR1 = '0.333333333333333';
    repl> $l->rest->force
    $VAR1 = improper_list(lazy { "DUMMY" }, lazy { "DUMMY" });

The rest element, when forced, is again a cell holding lazy terms, of
course. This time it's the cell holding:

    repl> $VAR1->first->force
    $VAR1 = '0.5';

Let's apply `F` to the whole thing: as mentioned above, it will force
all promises on its way, regardless whether they are in value or rest
slots:

    repl> F $l
    Exception: Illegal division by zero at (eval 136) line 1.
    repl 1> 
    Illegal division by zero at (eval 136) line 1.
    repl> F $l->drop(4)
    $VAR1 = list('-1');
    repl> $l
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

    repl> $l->drop(10)
    Exception: Illegal division by zero at (eval 136) line 1.

Ok, to be able to skip over that, we'd have to go back to our second
definition of `inverse`. But anyway, we could also start at a safer
location:

    repl> our $l= ourlist -1
    $VAR1 = improper_list('-1', lazy { "DUMMY" });
    repl> $l->take(10)
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
    repl> $l->take(10)
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

Example:

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
bigger blocks. But in any case, you could do something like the
following without making the perl try to read infinitely much into
process memory:

    repl> our $l= fh_to_chunks xopen_read("/dev/zero"), 10
    $VAR1 = lazy { "DUMMY" };
    repl> $l->first
    $VAR1 = '^@^@^@^@^@^@^@^@^@^@';
    repl> $l->drop(1000)->first
    $VAR1 = '^@^@^@^@^@^@^@^@^@^@';

(Or replace /dev/zero with /dev/urandom.)

For more examples using lazy evaluation and streams, see
`FP::IOStream`, `FP::Text::CSV`, `FP::DBI`,
[functional_XML](../functional_XML/README.md) and the [example
scripts](../examples/).

The nice thing of this is that you can stop writing for or while loops
now, and you can build up a processing chain similar to how you can
write pipelines in the shell. You can write a function that takes a
stream and returns a processed stream, and pass that to another
function that does some other processing, and group those two
functions into one which you can then group together with other
grouped-up ones. Just like you can write shell scripts that use a
pipeline and then pipe up those scripts themselves as if they were
"atoms".

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
    repl> Keep($l)->drop(1000)->first
    $VAR1 = '<94> )&m^C<8C>ESC<AB>A';
    repl> Keep($l)->drop(1000)->first
    $VAR1 = '<94> )&m^C<8C>ESC<AB>A';

There is hope that we might find a better way to deal with this
(implement variable life time analysis as a pragma/module), but no
promises here!


## Fresh lexicals and closures

Let's get a better understanding of functions, and first try the
following:

    repl> our ($f1,$f2)= do { our $a= 10; my $f1= sub { $a }; $a=11; my $f2= sub { $a }; ($f1,$f2) }
    $VAR1 = sub { "DUMMY" };
    $VAR2 = sub { "DUMMY" };
    repl> &$f1
    $VAR1 = 11;
    repl> &$f2
    $VAR1 = 11;

The two subroutines are both referring to the same instance of a
variable, and setting that variable to a new value also changes what
the first subroutine sees.

In this case, the reference to the variable is implemented by perl by
simply embedding the variable name in the code: the "our" variables
are package globals which only exist once with the same (fully
qualified) name in the whole program, hence it's enough to store that
name in the program code itself (i.e. only once over the program
lifetime).

Let's try a lexical variable instead (`my $a`):

    repl> our ($f1,$f2)= do { my $a= 10; my $f1= sub { $a }; $a=11; my $f2= sub { $a }; ($f1,$f2) }
    $VAR1 = sub { "DUMMY" };
    $VAR2 = sub { "DUMMY" };
    repl> &$f1
    $VAR1 = 11;

Still the same result: the two subroutines are still referring to the
same instance of a variable. Since `$a` only lives lexically in the do
block though, the subroutines now need to store a pointer reference to
it (the way this is implemented is by storing both a pointer to the
compiled code, and a pointer to the variable together in the CODE ref
data structure).

Now let's use a fresh lexical variable for the second value (11)
instead:

    repl> our ($f1,$f2)= do { my $a= 10; my $f1= sub { $a }; { my $a=11; my $f2= sub { $a }; ($f1,$f2) }}
    $VAR1 = sub { "DUMMY" };
    $VAR2 = sub { "DUMMY" };
    repl> &$f1
    $VAR1 = 10;
    repl> &$f2
    $VAR1 = 11;

This way we didn't change what `$f1`, including its indirect
references, refers to. Thus `$f1` remained a pure function here: it
follows the rule that pure functions *only* depend on the values they
receive as their arguments, and don't do *anything* visibly to the
rest of the program other than giving a result value. Just as with the
lists above, this is a good property to have, as it makes a value (be
it a function, or another value like a list) reliable. A pure function
or purely functional value does not carry a risk of giving different
behaviour at different times.

So, in conclusion, the safe and purely functional way is to only ever
use fresh variable instances, i.e. initialize them when introduced and
never modifying them afterwards. You might find this odd, a variable
is supposed to vary, no? But notice that each function call (even of
the same function) opens a new scope, and the variables introduced in
it are hence fresh instances every time it is called:

    repl> fun f ($x) { fun ($y) { [$x,$y] }}
    repl> our $f1= f(12); our $f2= f(14); &$f1("f1")
    $VAR1 = [12, 'f1'];
    repl> &$f2("f2")
    $VAR1 = [14, 'f2'];

You can see that a new instance of `$x` is introduced for every call
to `f`.

You may be thinking that there's no way around mutating variables:
loops can't introduce new variable instances on every loop iteration:
you'd have to put the variable declaration inside the loop and then it
would lose its value across the loop iteration. Well--it's true that
you can't do that with the loop syntax that Perl offers (`for`,
`while`). But you are not forced to use those. Iteration just means to
process work step by step, i.e.  do a step of work, check whether the
work is finished, and if it isn't, get the next piece of work and
start over. You can easily formulate this with a function that takes
the relevant pieces of information (remainder of the work, accumulated
result), checks to see if the work is done and if it isn't, calls
itself with the remainder and new result.

    repl> fun build ($i,$l) { if ($i > 0) { build($i-1, cons fun () { $i }, $l) } else { $l }}
    repl> build(3, null)
    $VAR1 = list(sub { "DUMMY" }, sub { "DUMMY" }, sub { "DUMMY" });

This uses a new instance of `$i` in each iteration, as you can see
from this:

    repl> $VAR1->map(fun ($v) { &$v() })
    $VAR1 = list(1, 2, 3);

There's one potential problem with this, though, which is that perl
allocates a new frame on the call stack for every nested call to
`build`, which means it needs memory proportional to the number of
iterations. But perl also offers a solution for this:

    repl> fun build ($i,$l) { if ($i > 0) { @_=($i-1, cons fun () { $i }, $l); goto &build } else { $l }}

Sorry for the one-line formatting here, our examples are starting to
get a big long for the repl, here is the same with line breaks:

    fun build ($i,$l) {
        if ($i > 0) {
            @_=($i-1, cons fun () { $i }, $l); 
            goto &build
        } else {
            $l 
        }
    }

That still looks pretty ugly, though. But there's also a solution for
*that*: if you install `Sub::Call::Tail` (`repl+` automatically loads
it on start), then you can instead simply prepend the `tail` keyword
to the recursive function call to achieve the same:

    repl> fun build ($i,$l) { if ($i > 0) { tail build($i-1, cons fun () { $i }, $l) } else { $l }}

i.e.

    fun build ($i,$l) {
        if ($i > 0) {
            tail build($i-1, cons fun () { $i }, $l)
        } else {
            $l 
        }
    }


What `tail` (or the written-out `goto` variant above) means is "this
function call is the last operation in the current program flow of
this function (it is in tail position); don't allocate a new stack
frame for it". (It might be useful to try to write a perl module that
automatically does the tail call recognition in its scope.)


## The REPL revisited

Our examples are starting to grow big enough that they don't fit in
one line anymore. Let's start a file. Quit the repl, then:

    $ cp examples/{template,introexample}
    $ $EDITOR examples/introexample 

You'll want to un-comment the "use Function::Parameters" line, and
remove the commented "add your own code" part, and put the following
there:

    fun hello ($n) {
        repl;
        print "$n worlds\n";
    }

Now, when you run it:

$ examples/introexample 
main> 

you get to a repl prompt, this time showing "main" as the
namespace. This comes from the "repl" call at the end of the script
(that you left in if you followed the instructions above closely). You
can now call the `hello` sub from there:

    main> hello 5
    main 1> 

Now you're at the sub-repl, indicated by the level "1". This time it's
not because of an exception but because you called the repl
explicitely. Test this:

    main 1> hello 7
    main 2> 

and you're at a sub-sub-repl now. Press ctl-d to exit that one, you get:

    7 worlds
    $VAR1 = 1;
    main 1> 

and you are at the first sub-repl again. Remember, this is the one
from the call to `hello 5`. The repl offers a few tools that can be
useful here. To see a backtrace, enter `:b` (or `,b`, comma and colon
are equivalent):

    main 1> :b
    0        FP::Repl::Repl::run('FP::Repl::Repl=ARRAY(0x920b5f8)', undef) called at examples/introexample line 46
    1        main::hello('5') called at (eval 114) line 1
    ...

The stack also holds frames from the internal processing by the repl,
which is a tad ugly, but kinda unavoidable, stripped here
("..."). From the above you can see that hello 5 was called from eval
(part of the processing by the original repl), then a sub-repl was
called at line 46 of the example file.

Another useful tool is to inspect the lexical environment at the
current, or any other call frame. Enter `:e`, without a number it
shows the environment at the location of the current call.

    main 1> :e
    $n = 5;

Sure enough. Those lexicals are available from code you enter:

    main 1> $n+1
    $VAR1 = 6;

You can also modify them. The change is reflected in the calling
program, once you leave the repl to let it continue:

    main 1> $n=42
    $VAR1 = 42;
    main 1> (ctl-d)
    42 worlds
    $VAR1 = 1;
    main> 

And we're back in the toplevel repl.


## Local functions and recursion

While there's no strict need for it, it's often useful to define
subroutines within another subroutine. The benefits are: keeping the
definition closer to its use, and the ability to access lexicals local
to the outer subroutine (without having to pass them as
arguments). The fundamental disadvantage is that a local subroutine
can't be reused from elsewhere (directly), and it can't be tested
(directly). But there's also a catch with it in Perl that we'll see
shortly.

Let's adapt the example from "Writing a list-generating function":

    (.. existing imports...)
    use Chj::xperlfunc qw(xprintln);
    use FP::TransparentLazy;

    fun hello ($start, $end) {
        my $inverse= fun ($x) { lazy { 1 / $x } };

        my $ourlist; $ourlist= fun ($i) {
            $i < $end ? null
              : cons &$inverse($i), &$ourlist($i-1)
        };

        &$ourlist($start)->for_each(*xprintln);
    }

Note that this first declares `$ourlist`, then assigns it; this is so
that the expression that generates the value to be held by the
variable can see the variable, too (so that the function can call
itself). As always, assignments to a variable after introducing it is
dangerous: here it creates a cycle from the internal data structure
representing the subroutine to itself, preventing perl from
deallocating `$ourlist` after exiting the `hello` subroutine. One
solution is to add

    use FP::Weak;

to the imports and change the last line of `hello` into:

        Weakened($ourlist)->($start)->for_each(*xprintln);

Another solution, and the one preferred by the author of this text, is
to use `fix`, the fixpoint combinator, which is a function that takes
a function as its argument and returns a different function that when
called calls the original function with itself as the first
argument. That was a mouthful, let's see how it looks:

    use FP::fix;

    fun hello ($start, $end) {
        my $inverse= fun ($x) { lazy { 1 / $x } };

        my $ourlist= fix fun ($self, $i) {
            $i < $end ? null
              : cons &$inverse($i), &$self($i-1)
        };

        &$ourlist($start)->for_each(*xprintln);
    }

When `$ourlist` is called, it calls the nameless function that is the
argument to `fix`, and passes it `$ourlist` (or an equivalent thereof)
and `$start`; our function can then call "itself" through `$self` and
still only needs to pass the "real" argument (the new value for
`$i`). In real world use you would usually rename `$self` to
`$ourlist`, too; they are given different names here just for
illustration.

Do you think that's hard to understand or use? I suggest you play with
it a bit and see whether it grows on you. BTW, a nice property of fix
is that the outer `$ourlist` variable can actually avoided in cases
such as this one--the result from fix can be called immediately:

        fix (fun ($self, $i) {
            $i < $end ? null
              : cons &$inverse($i), &$self($i-1)
        })
          ->($start)->for_each(*xprintln);

Another idea for a syntactical improvement implemented via a module
would be a recursive variant of `my`, i.e. one where the expression to
the right sees the variable directly, and then applies the `fix` or
weakening transparently, but, like the other ideas mentioned above,
this will take some effort and may only be feasible if there is enough
interest (and hence some form of at least moral support).


## More on functions

Pure functions (and methods) are good blocks for modular programming,
i.e. they are a good approach to make small reusable pieces that
combine easily: their simple API makes them easily
understandable. Their reliability (no side effects, hence no
surprises) makes them easily reusable. It helps being aware of a few
functional "patterns" for good reusability:

### Higher-order functions

Those are functions that take other functions as an argument. Examples
are many sequence processing functions (or methods), like some of
those which we have already seen: `map`, `fold`, `fold_right`,
`filter`. The function they take as an argument may be one that
handles a single value, and they "augment" it to work on all values in
a sequence. Or the function argument may change the way that the
higher-order function works.

In 'Writing a list-generating function' we have written a function
`ourlist` that builds a list while calling `inverse` on every `$i` it
goes through. Let's turn that into a reusable function by making it
higher-order:

    repl> fun inverse ($x) { lazy { 1 / $x } }
    repl> fun ourlist ($f, $from, $to) { $from >= $to ? cons &$f($from), ourlist($f, $from - 1, $to) : null }
    repl> F ourlist (*inverse, 4, 1)
    $VAR1 = list('0.25', '0.333333333333333', '0.5', '1');

It would now better be renamed, perhaps to something like
`downwards_iota_map`. But we could also split up the function into
downwards_iota and map parts if we're using lazy evaluation, then we
could use those separately. In fact both are already available in
functional-perl:

    repl> F stream_step_range(-1, 4, 1)->map(*inverse)
    $VAR1 = list('0.25', '0.333333333333333', '0.5', '1');

(The naming of these more exotic functions like `stream_step_range` is
still open to changes: hints about how other languages/libraries name
those are very welcome.)

A secial kind of higher-order functions is combinators.

### Combinators

> *A combinator is a higher-order function that uses only function
> application and earlier defined combinators to define a result from
> its arguments.*
> ([Wikipedia](https://en.wikipedia.org/wiki/Combinator))

There are already a number of such functions defined in
`FP::Combinators`. The two most commonly used ones are `flip`, which
takes a function expecting 2 arguments and returns a function
expecting them in reverse order, and `compose`, which takes two (or
more) functions, and returns a function that nests them (i.e. calls
each original function in turn (from the right to left) on the
original arguments, or the result(s) from the previous call). See how
flip behaves:

    repl> *div= fun($x,$y) { $x / $y }; *rdiv= flip *div
    Subroutine repl::div redefined at (eval 136) line 1.
    $VAR1 = *repl::rdiv;
    repl> div 1,2
    $VAR1 = '0.5';
    repl> rdiv 2,1
    $VAR1 = '0.5';

The "subroutine redefined" warning above is because `div` was already
defined (equivalently) in `FP::Ops`. This module provides subroutine
wrappers around Perl operators, so that they can be easily passed as
arguments to other functions like `flip` or the `map` methods.

    repl> fun inverse ($x) { lazy { 1 / $x } }
    repl> *add_then_invert= compose *inverse, *add
    $VAR1 = *repl::add_then_invert;
    repl> add_then_invert 1,2
    $VAR1 = lazy { "DUMMY" };
    repl> F $VAR1
    $VAR1 = '0.333333333333333';

i.e. `compose *inverse, *add` is equivalent to:

    fun ($x,$y) { inverse (add $x, $y) }


## Testing

One of the nice benefits of pure functions and methods, and the
associated programming style that favours to write small functions
(since they can be more easily reused) is that those are easily
testable. This can of course be done using any testing module (like
`Test::More`). The functional-perl project also provides a module,
`Chj::TEST`, that obviates the need to put tests into separate files:
the tests can be added right after a function declaration, which is a
bit easier to write, and may help document the code (both can be read
together). Unlike `is` from `Test::More` which in principle is
symmetric in the treatment of the gotten and expected values, its
`TEST` procedure expects a code block as its first argument, plus the
expected result as the second (although you can also use `GIVES` and a
block if computation of the result is expensive, see `Chj::TEST`
docs). The code block is not evaluated when the `TEST` form is
evaluated, but stored away and only run when `Chj::TEST`'s `run_tests`
procedure is run. Concerns about using up process memory to store
tests that will usually not be run before the process exits seem
largely unfounded (RAM usage grew by a few percents at most in the
heaviest tested modules (todo: find tests again?)), but `Chj::TEST`
can also be instructed to drop the tests at module load time by
setting the TEST environment variable to 0 or ''.

You can use it without leaving the repl:

    repl> fun inverse ($x) { lazy { 1 / $x } }
    repl> TEST { F inverse 2 } 0.5;
    $VAR1 = 1;
    repl> run_tests "repl"
    === running tests in package 'repl'
    running test 1..ok
    ===
    => 1 success(es), 0 failure(s)
    $VAR1 = 0;


## Objects

Function versus method dispatch and functional purity are orthogonal
concepts: purely functional programming does not preclude using object
methods (i.e. dynamic dispatch); it only precludes those from doing
observable side effects (including to the object itself).

Perl does not offer pattern matching natively (but there is CPAN!),
which is a popular way to do runtime dispatch in functional
programming languages. Instead, it makes sense to continue using
objects and method dispatch, but adapt the style to be purely
functional as far as feasible.

Like we can have a list data structure that allows modification by
calculating a new list and leaving the old unharmed, we can do the
same with objects. Since most classes have few fields, it seems to
make most sense to continue using hashtables to store them, but make
flat copies (clones) of the object before modifying them.

The functional-perl project provides a class generator, `FP::Struct`,
that creates object setters from the given field definitions which do
this cloning approach underneath. This module is probably the most
experimental and perhaps contentious part discussed so far. Why not
extend `Moose` (or `Moo`?) to do the same? This author simply felt
like experimenting with a new, rather simple approach would allow to
try out things faster and might give new ideas. He also likes some of
the advantages of the taken approach: passing field definitions as
array allows to build up the array programmatically easily. And using
optional predicate functions to check types looked like a simple and
good match.

Update the examples/introexample script with the following:

    package Shape {
        use FP::Struct [];
        _END_
    }

    package Point {
        # for illustration, we don't check types here
        use FP::Struct ["x","y"],
          "Shape";

        _END_ # defines accessors that have not been defined explicitely
    }

    package Rectangle {
        # Let's type-check here.
        # Subroutines imported here will be cleaned away by _END_
        use FP::Predicates qw(instance_of);

        use FP::Struct [[instance_of("Point"), "topleft"],
                        [instance_of("Point"), "bottomright"]],
          "Shape";

        method area () {
            ($self->bottomright->x - $self->topleft->x)
              *
            ($self->bottomright->y - $self->topleft->y)
        }

        _END_
    }

    use FP::Ops ":all"; # imports `the_method`

Then run it and try:

    main> our $s1= Rectangle->new(Point->new(2,3), Point->new(5,4));
    $VAR1 = bless(+{topleft => bless(+{y => 3, x => 2}, 'Point'), bottomright => bless(+{y => 4, x => 5}, 'Point')}, 'Rectangle');
    main> our $s2= $s1->bottomright_update(fun($p) { $p->y_set(10) })
    $VAR1 = bless(+{topleft => bless(+{y => 3, x => 2}, 'Point'), bottomright => bless(+{y => 10, x => 5}, 'Point')}, 'Rectangle');
    main> list($s1,$s2)->map(the_method "area")
    $VAR1 = list(3, 21);

As you can see, we have created `$s2` without mutating `$s1`.

The `..update` method passes the old value to the given function and
replaces it with what the function returns. The `..set` methods use
the given value directly. Those methods are generated automatically by
FP::Struct.

The `the_method` function "turns" a method call into a function call:
just like we would say `*area` if it were an imported function, we say
`the_method "area"` to indicate that this method name should be called
on the value that is passed by map as the (first and only) argument.

If you'd like to get nicer pretty-printing, simply add:

        method FP_Show_show ($show) {
            "Point(".&$show($self->x).", ".&$show($self->y).")"
        }

to the Point package and

        method FP_Show_show ($show) {
            "Rectangle(".&$show($self->topleft).", ".&$show($self->bottomright).")"
        }

to the Rectangle package, then:

    main> our $s1= Rectangle->new(Point->new(2,3), Point->new(5,4));
    $VAR1 = Rectangle(Point(2, 3), Point(5, 4));
    main> our $s2= $s1->bottomright_update(the_method "y_set", 10)
    $VAR1 = Rectangle(Point(2, 3), Point(5, 10));

To get the constructor functions whose existence these implicate:

    main> import Point::constructors; import Rectangle::constructors; 
    $VAR1 = '';
    main> Rectangle(Point(2, 3), Point(5, 4))
    $VAR1 = Rectangle(Point(2, 3), Point(5, 4));

Instead of adding the `FP_Show_show` methods, you could also have just
added `FP::Show::Base::FP_Struct` as a base class:

    package Shape {
        use FP::Struct [], 'FP::Show::Base::FP_Struct';
        _END_
    }

Sorry for telling you about this late. ;)

</with_toc>
