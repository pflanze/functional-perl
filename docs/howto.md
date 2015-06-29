(Check the [functional-perl website](http://functional-perl.org/) for
properly formatted versions of these documents.)

---

# How to write functional programs on Perl 5

Perl 5 was not designed to write programs in a functional style. Yes,
there are closures, and there are the `map` and `grep` builtins as
kind-of higher-order functions for the builtin 'lists', but that's
where it ends. Quite a bit (for example functional data structures
like linked lists) can be implemented as plain old Perl code
straightforwardly, or so it seems at first. But the somewhat bad news
is that some of the idioms of functional programming require special
attention on behalf of the programmer to get working reliably. The
good news is that, once you understand the shortcomings and
workarounds, it's possible, and after some practising it might become
second nature. Still perhaps it will be possible to change the perl
interpreter or write lowlevel modules to make some of the workarounds
unnecessary.

Note that most programming language implementations which were not
designed for functional programming have some of the same problems;
they may sometimes be the reason for implementors of functional
programming libraries to avoid certain functional idioms, for example
by building `map` etc. on top of iterators (an imperative idiom).
These may be good (and will be performant) workarounds, but that also
means that only these higher levels are functional, and there being a
boundary between the two worlds may mean that extensibility is not
pretty (they might be leaky abstractions). For example, it might not
be possible to define streams in a functional ("Haskell style") way
(like in [`examples/fibs`](../examples/fibs)).  In Perl it's possible,
and perhaps it will even become easier in the future.

(This project might still also (alternatively) use iterators for
sequences in the future; but they should be understood as an
optimization only (but then in Perl memory allocation is comparatively
cheap compared to running code, so iterators may well actually be
slower than linked lists). Alternative optimizations are possible, and
may be preferrable (e.g. the GHC Haskell compiler applies various
other optimizations to achieve performance without relying on manually
written iterator based code, such as compile time application of rules
to fuse list processing chains as well as using general
"deforestation" algorithms). Not having a static type system means
these can't be done before runtime or module initialization time.)


<with_toc>

## Values, syntactical matters

### References and mutation, "variables" versus "bindings"

Pure functions never mutate their arguments, which is why it is never
necessary to create copies of values before passing them into such
functions. Which means, in Perl terms, it is fine (and more efficient)
to always pass references (this is what implementations for functional
languages generally do, too). It probably won't be (much of) a benefit
to pass references to elementary values such as strings and numbers,
which is why the functional-perl project generally doesn't do so; but
it generally assumes that arrays are passed as references. The reason
for this is also so that functions can be properly generic: all sorts
of values should be passed the same way, syntactically: regardless
whether an argument is a subroutine (other function), array, hash,
string, number, object, if it is always stored in a scalar (as a
reference in the case of arrays and hashes) then the type doesn't
matter. Genericism is important for reusability / composability.

Another thing to realize is that, in a purely functional (part of a)
program, variables are never mutated. Fresh instances of variables are
*bound* (re-initialized) to new values, but never mutated
afterwards. This means there's no use thinking of variables as
containers that can change; the same (instance of a) container always
only ever gets one value. This is why functional languages tend to use
the term "binding" instead of "variable": it's just giving a value a
name, i.e. binding a name to it. So, instead of this code:

    my @a;
    push @a, 1;
    push @a, 2;
    # ...

which treats the variable @a as a mutable container, a functional
program instead does:

    my $a= [];
    {
        my $a= [@$a, 1];
        {
            my $a= [@$a, 2];
            # ...
        }
    }

where no variable is ever mutated, but just new instances are created
(which will usually happen in a (recursive) function call instead of
the above written-out tree), and in fact not even the array itself is
being mutated, but a new one is created each time; the latter is not
efficient for big arrays (the larger they get, the longer it takes to
copy the old one into the new one), which is where linked lists come
in as an alternative (discussed in other places in this project).

But, realize that we're talking about two different places (levels)
where mutations can happen: the variable itself, and the array data
structure. In `@a` the variable as the container and the array data
structure are "the same", but we can also write:

    my $a= [];
    push @$a, 1;
    push @$a, 2;

In this case, we mutate the array data structure, but not the variable
(or binding) `$a`. In impure functional languages like Scheme or
ML/Ocaml, the above is allowed and a common way of doing things
imperatively: not the variables are mutated, but the object that they
denote (similar to how you're doing things on objects in Perl; this
just makes arrays and hashes treated the same way as other objects).
(ML/Ocaml also provides boxes, for the case where one wants to mutate
a variable; it separates the binding from the box; versus Perl where
every binding is a box at the same time. By separating those concerns,
ML/Ocaml is explicit when the box semantics are to be used. The type
checker in ML/Ocaml will also verify that only boxes are mutated, it
won't allow mutation on normal bindings. We don't have that checker in
Perl, but we can still restrain ourselves to only use the binding
functionality. Scheme does offer `set!` to mutate bindings,
i.e. conflates binding and boxing the same way Perl does, but using
`set!` is generally discouraged. One can search Scheme code for the
"!" character in identifiers and find the exceptional, dangerous,
places where they are used. Sadly in Perl "=" is used both for the
initial binding, as well as for subsequent mutations, but it's still
syntactically visible which one it is (missing `my` (or `our`)
keyword).)

It is advisable to use this latter approach when working with impure
sub-parts in code that's otherwise functional, as it still treats all
data types uniformly when it comes to passing them on, and hence can
profit from the reusability that generic functions provide.

### Identifier namespaces

Most functional programming languages (and newer programming languages
in general) have only one namespace for runtime identifiers (many have
another one for types, but that's out of scope for us as we don't have
a compile time type system (other than the syntactical one that knows
about `@`, `%`, and `&` or sigil-less and perhaps `*`)).  Which means
that variables (bindings) for functions are not syntactically
different from variables (bindings) for other kinds of values. Common
lisp has two name spaces, functions and other values; Scheme did away
with that and uses one for both. Perl has not only these, but also the
arrays and hashes etc. Usually, this kind of "compile time typing" by
way of syntactical identifier differences is called namespaces. Common
lisp is a Lisp-2, Scheme a Lisp-1. Ocaml, Haskell, Python, Ruby,
JavaScript are all using 1 namespace (XX what about methods?).

Using 1 namespace is especially nice when writing functional programs,
so that one can pass variables as arguments exactly the same,
regardless of type (basically this is all the same as already
discussed in the section above).

It would be possible to really only use one namespace in Perl, too
(scalars), and write functions like so, even when they are global
(`array_map` can be found in `FP::Array`):

    our $square= sub {
        my ($a)=@_;
        $a * $a
    };

    my $inputs= [ 1,2,3 ];

    my $results= array_map $square, $inputs;

This is nicely uniform, but perhaps a tad impractical. Perl
programmers have gotten used to defining local functions with `my
$foo= sub ..`, but are used to using Perl's subroutine (CODE)
namespace for global functions; pushing people to use a single
namespace probably won't make sense.

But this means that the above becomes:

    sub square {
        my ($a)=@_;
        $a * $a
    }

    my $inputs= [ 1,2,3 ];

    my $results= array_map \&square, $inputs;

or

    my $results= array_map *square, $inputs;

or

    my @inputs= ( 1,2,3 );

    my $results= array_map \&square, \@inputs;

or then still

    my $results= array_map *square, \@inputs;


(Pick your favorite? Should this project give a recommendation?)


## Lazy evaluation

A useful feature that becomes possible with purely functional code is
lazy, or delayed, evaluation. A lazy expression is an expression that
is not evaluated when the code path reaches it, but instead yields a
"promise" value, which promises to evaluate the actual value of the
expression that it describes when it is needed. Unless a language
evaluates *all* expressions like this by default (like e.g. Haskell
does), the programmer needs to indicate lazy evaluation of an
expression explicitely. In a language that supports closures (like
Perl) simply wrapping the expression in question as a function that
doesn't take any arguments (`sub { ... }`) fulfills that role, but
there are two improvements that can be done: (1) it's useful to make a
promise distinguishable from subroutines to make the intent, error
checking and debugging easier; (2) usually one wants
evaluate-at-most-once semantics, i.e. if the value in a promise is
needed multiple times, the original expression should be evaluated
only once and then the result cached. Thanks to Perl's '&' subroutine
prototype implementing a `lazy { .. }` construct becomes
straightforward (just write a `sub lazy (&) { Promise->new($_[0]) }`.) 
This is offered in `FP::Lazy`. (It also provides promises that *don't*
cache their result, which might be handy as a small optimization for
code that doesn't request their value multiple times, and has the
advantage of not showing the memory retention difficulties described
below.)

The reason this is useful is that it can avoid evaluation cost if the
value is never actually needed, and that in the case when it *is*
needed the delay of its evaluation can allow to free up other
resources first. This enables the declaration of data structures in an
abstract, "stupid" way: the code declaring them does not need to
consider what's actually used by the program, it simply says "in case
the program needs this, it should be the value of this
expression". The declaration can hence describe a data structure
that's possibly (much) bigger than what's actually used, bigger than
the available memory or even infinitely big (for example a linked list
holding all natural numbers, 1..infinity). This makes the code
defining the data structure simpler and more reusable because it does
not encode the pattern of the particular need into it. If the data
structure that's lazily generated is a linked list, we call it a
stream (or *functional* stream to make clear we're not talking about
filehandles or similar), but the same benefits can apply to trees and
other data structures.

The reason that this only becomes possible with purely functional code
is that if the expression depends on the time when it is being
evaluated, the code declaring the result could not rely on that the
value that the user will get upon evaluation is actually what the
declaration intended. And for expressions that have side effects, the
time when these side effects are run depends on when the user of the
promise forces it, which, although deterministic, is quickly complex
to understand. Thus the only possibly useful sideeffects in lazy code
are `warn` statements (but even those may confuse you). Note the
section below about [debugging of lazy code](#Lazy_code).

Perl complicates the part about "freeing up other resources first"
before evaluating a promise that's referenced by the to-be-freed
resource; see [memory handling](#Memory_handling) below.

### Terminology

The used terms are rather unstandardized across programming languages.
A `promise` can mean subtly different things. Don't let that confuse
you. (Todo: comparison? with JavaScript etc., even CPAN modules?)

### Futures

Also a non-standardized term. What we mean here is the use of a form
(similar to the `lazy` form, e.g. `future { some costly $expression
}`) that runs the contained expression immediately, but in a separate
thread in parallel, and instead returns a "future" value. Forcing
(getting the value of) the "future" awaits the termination of its
evaluation (if not already done), then returns the evaluated result
(and stores it to return it again immediately when requested again).

The functional-perl libraries do not contain an implementation of this
(yet); there will be various ways how this could be implemented in
Perl, and there may be modules on CPAN already (todo: see what's
around and perhaps wrap it in a way consistent with the rest of
functional-perl).

### Comparison to generators

Generators (code that can produce a sequence by `yield`ing elements)
are en vogue in non-functional languages today. They also run code on
demand ('lazily') to produce data elements. How do they compare to
streams (lazy linked lists)?

* `yield` interrupts control flow; from the point of view
  of function application, it is magic, it's not part of what
  'straight' functions can do. The mechanism of their implementation
  is often not accessible; if it is (i.e. built as a library using
  only the host language), then first-class continuations are
  needed. Those have a bad reputation for being difficult to reason
  about. Even Schemers, the community where the concept originated,
  recommend to use them sparingly. In comparison, lazy evaluation is
  very straight-forward (and even in Scheme implementations with
  perfectly efficient first-class continuations, an implementation of
  lazy lists is faster than one of generators).

* One benefit (the only?) that generators have is that they don't need
  to introduce the concept of linked lists.

* The lazyness mechanism as described above is universal, it doesn't
  only apply to sequences, but works seamlessly for things like trees,
  or even individual (but expensive to calculate) values.


## Memory handling

The second area where Perl is inconvenient to get functional programs
working is for them to handle memory correctly. Functional programming
languages usually use tracing garbage collection, have compilers that
do live time analysis of variables, and optimize tail calls by default
(although some like Clojure don't do the latter), the sum of which
mostly resolves concerns about memory. Perl 5 currently offers none of
these three features. But it still does provide all the features to
handle these issues manually, and often the places where they are
needed are in lower level parts of programs, which are often shared as
libraries, and hence you might not need to use the tricks described
here often. You need to know about them though, lest you might end up
scratching your head for a long time.


### Reference cycles (and self-referential closures)

This is the classic issue with a system like Perl that uses reference
counting to determine when the last reference to a piece of data is
let go. Add a reference to the data structure to itself, and it will
never be freed. The leaked data structures are never reclaimed before
the exit of the process (or at least the perl interpreter) as they are
not reachable anymore (by normal programs).

The solution is to strategically weaken a reference in the cycle
(usually the cyclic reference that's put inside the structure itself),
using `Scalar::Utils`'s `weaken`. `FP::Weak` also has `Weakened` which
is often handy, and `Keep` to protect a reference from such weakening
attacks in case it's warranted.

The most frequent case using reference cycles in functional programs
are self-referential closures:

    sub foo {
        my ($start)=@_;
        my $x = calculate_x;
        my $rec; $rec= sub {
            my ($y)= @_;
            is_bar $y ? $y : cons $y, &$rec(barify_a_bit_with $y, $x)
        };
        &{Weakened $rec} ($start)
    }

Without the `Weakened` call, this would leak the closure at $rec. (In
principle, setting `$rec = undef; ` when the subroutine is done would
work, too, but the subroutine might lose control due to an unavoidable
exception like out of memory or a signal handler that calls `die`, in
which case it would still be leaked.)

Note that alternative, and often better, solutions for
self-referential closures exist: `FP::fix`, and `_SUB_` from `use
v5.16`. Also, sometimes (well, always when one is fine with passing
all the context explicitely) a local subroutine can be moved to the
toplevel and bound to normal subroutine package variables, which makes
it visible to itself by default.


### Variable life times

Lexical variables in the current implementation of the perl
interpreter live until the scope in which they are defined is
exited. Note explicitely that this means they may still reference
their data even at points of the code from which on they will never be
used anymore. Example:

    {
        my $s = ["Hello"];
        print $$s[0], "\n";
        main_event_loop(); # the array remains allocated till the event
                           # loop return, even though never (normally)
                           # accessible
    }

You may ask why you should care about a little data staying
around. The first answer is that the data might be big, but the more
important second answer in the context of functional programming is
that the data structure might be a hierarchical data structure like a
linked list that's passed on, and then appended to there (by way of
mutation, or in the case of lazy functional programming, by way of
mutation hidden in promises). The top (or head, first, in case of
linked lists) of the data structure might be released by the called
code as time goes on. But the variable in the calling scope will still
hold on to it, meaning, it will grow, possibly without
bounds. Example:

    {
        my $s= xfile_lines $path; # lazy linked list of lines
        print "# ".$s->first."\n";
        $s->for_each (sub { print "> ".$_[0]."\n" });
    }

Without further ado, this will retain all lines of the file at $path
in `$s` while the for_each forces in (and itself releases) line after
line.

This is a problem that many programming language implementations (that
are not written to support lazy evaluation) have. Luckily in the case
of Perl, it can be worked around, by assigning `undef` or better
weakening the variable from within the called method:

    sub for_each ($ $ ) {
        my ($s, $proc)=@_;
        weaken $_[0];
        ...
    }

`weaken` is a bit more friendly than `$_[0] = undef;` in that it
leaves the variable set if there's still another reference to the head
around.

With this trick (which is used in all of the relevant
functions/methods in `FP::Stream`), the above example actually *does*
release the head of the stream in a timely manner.

Now there may be situations where you actually really want to keep
`$s` alive. In such a case, you can protect its value from being
clobbered by passing it through the `Keep` function from `FP::Weak`:

    {
        my $s= xfile_lines $path; # lazy linked list of lines
        print "# ".$s->first."\n";
        Keep($s)->for_each (sub { print "> ".$_[0]."\n" });
        $s->for_each (sub { print "again: > ".$_[0]."\n" });
    }

Of course this *will* keep the whole file in memory! So perhaps you'd
really want to do the following:

    {
        my $s= xfile_lines $path; # lazy linked list of lines
        print "# ".$s->first."\n";
        $s->for_each (sub { print "> ".$_[0]."\n" });
        $s= xfile_lines $path; # reopen the file from the start
        $s->for_each (sub { print "again: > ".$_[0]."\n" });
    }

This is probably the ugliest part when programming functionally on
Perl.  Perhaps the interpreter could be changed (or a lowlevel module
written) so that lexical variables are automatically cleared upon
their last access (and something like @_=() is enough to clear it from
the perl calling stack, if not automatic). An argument against this is
inspection using debuggers or modules like `PadWalker`, so it will
have to be enabled explicitely (lexically scoped).


### Stack memory and tail calls

Another, closely related, place where the perl interpreter does not
release memory in a timely (enough for some programs) manner, are
subroutine calls in tail position. The tail position is the place of
the last expression or statement in a (subroutine) scope. There's no
need to remember the current context (other than, again, to aid
inspection for debugging), and hence the current context could be
released and the tail-called subroutine be made to return directly to
the parent context, but the interpreter doesn't do it.

    sub sum_map_to {
        my ($fn, $start, $end, $total)=@_;
        # this example only contains an expression in tail position
        # (ignoring the variable binding statement).
        $start < $end ?
            sum_map_to ($fn, $start + 1, $end, $total + &$fn($start))
          : $total
    }

This causes code using recursion to allocate stack memory proportional
to the number of recursive calls, even if the calls are all in tail
position. It keeps around a chain of return addresses, but also (due
to the issue described in the previous section) references to possibly
unused data.

See [`intro/tailcalls`](../intro/tailcalls) and
[`intro/more_tailcalls`](../intro/more_tailcalls) for solutions to
this problem.

(Perhaps a bytecode optimizer could be written that, given a pragma,
automatically turns calls in tail position into gotos.)

In simple cases like above, the code can also be changed to use Perl's
`while`, `for`, or `redo LABEL` constructs instead. The latter looks
closest to actual function calls, if that's something you'd like to
retain:

    sub sum_map_to {
    sum_map_to: {
        my ($fn, $start, $end, $total)=@_;
        # this example only contains an expression in tail position
        # (ignoring the variable binding statement).
        $start < $end ?
            do { @_= ($fn, $start + 1, $end, $total + &$fn($start));
                 redo sum_map_to }
          : $total
    }}

(Automatically turning such simple self tail calls into redo may
perhaps also be doable by way of a bytecode optimizer.)


### C stack memory and freeing of nested data structures

When Perl deallocates nested data structures, it uses space on the C
(not Perl language) stack for the recursion. When a structure to be
freed is nested deeply enough (like with long linked lists), this will
make the interpreter run out of stack space, which will be reported as
a segfault on most systems. There are two different possible remedies
for this:

  * increase system stack size by changing the corresponding
    resource limit (e.g. see `help ulimit` in Bash.)

  * being careful not to let go of a deeply nested structure at
    once. By using FP::Stream instead of FP::List for bigger lists and
    taking care that the head of the stream is not being retained,
    there will never be any long list in memory at any given time (it
    is being reclaimed piece after piece instead of all at once)


Note that the same workaround as used with streams (weakening entries
in `@_`) will help with incremental deallocation with non-lazy lists
as well, and hence avoid the need for a big C stack, and avoid the
cumulation of time needed to deallocate the list (bad for soft
real-time latency). But weakening of non-lazy lists will/would be more
painful to handle for users, as it's more common to reuse them than
their lazy cousins. Arguably it would really be best to make the
language handle lifetimes automatically (lexical variable analysis),
it would benefit both the lazy and non-lazy cases.

### See also

* A [post](https://news.ycombinator.com/item?id=8734719) about streams
  in Scheme mentioning the memory retention issues that even some
  Scheme implementations can have.


## Object oriented functional programming

Note that "functional" in the context of "functional programming" does
not mean "using function call syntax instead of method call syntax". A
subroutine that prints something to stdout or modifies some of its
arguments or variables outside its inner scope is not a *pure*
function, which is what "functional" in "functional programming"
implies. A pure function's *only* effect (as observable by a purely
functional program, i.e. ignoring the use of machine resources and
time) is its result value, and is dependent *only* on its arguments
and immutable values (values that are never modified during a program
run).

Even aside the above confusion, there seems to be a rather widespread
notion that object oriented and functional programming are at odds
with each other. This is only the case if "object oriented" implies a
style that mutates the object(s) or other side effects. So whether
there is a conflict depends on the definition of "object
orientation". The author of this text has never found a precise
definition.
[Wikipedia](https://en.wikipedia.org/wiki/Object_oriented_programming)
writes:

> *A distinguishing feature of objects is that an object's procedures
> can access and often modify the data fields of the object with which
> they are associated.*

It only says "often modify", not that modification is a required part
of the methodology.

If individual method implementations all follow the rules for a pure
function, then the method call only adds the dispatch on the object
type. The object can be thought of (and in Perl actually is) an
additional function argument and its type simply becomes part of the
algorithm, and the whole remains pure. Functional programming
languages often offer pattern matching that can be used to the same
effect, or other features that are even closer (e.g. Haskell's type
classes). Or to say it in a more pointed way: remove side effects from
your coding, and your produce is purely functional, totally regardless
of whether it is implementing classes and objects or not.

To build purely functional classes easily, have a look at
`FP::Struct`. Classes generated with it automatically inherit from
`FP::Pure` by default, so that `is_pure` from `FP::Predicates` will
return true (but currently it's your responsibility to not mutate the
objects by writing to their hash fields directly, or if you do so,
only in a manner that doesn't violate the purity as seen from the
outside (e.g. caching is OK if done correctly)). If you would prefer
to extend `Moose` for the same purposes, please
[tell](mailing_list.md).

Due to method calls using different syntax, they can't be directly
passed where a function reference is expected. The Perl builtin way to
pass them as a value is to pass the method name as a string, but that
requires the receiving code to expect a method name, not a
function. To require all places that do a function call to accomodate
for the case of being instead passed a string does not look like a
good idea (forgetting would be a bug, runtime overhead on every call
instead of just taking the reference). And although references to
individual method implementations *can* be taken (like
`\&Foo::Bar::baz`), that skips the type dispatch and will most likely
hurt you later on.

Instead, a wrapper subroutine needs to be passed that does the method
calls, like:

    $l->map( sub { my $s=shift; $s->baz } )

But thanks to the possibility of passing a method as a string, a
method-string-to-subroutine converter can easily be written such that
the above code becomes:

    $l->map( the_method "baz" )

The function `the_method` (which also takes optional arguments to be
passed along) is available from `FP::Ops`. (Why is it not in
`FP::Combinators`? Because (the argument is not a function, and) it
really fulfills the functionality of the `->` operator (together with
currying).)


## Pure functions versus I/O and other side-effects

(This section isn't specific to Perl, other than to describe the
limited safety checking. Also, if this is over your head right now,
skip this section and come back to it later; or come and ask us your
way through it, that may also help improve the text here.)

Other than program arguments and exit code, the only way for a process
to interact with the "world" (the rest of the operating system) is by
way of side effects, like read and write. Thus almost no program can
be completely purely functional.

So the quest is to make as much of the code purely functional as
feasible (in the interest of profiting from the benefits this provides
for reasoning, testing and composition), and reduce the part that
interacts with the world to code that basically just passes inputs and
outputs between the world and the purely functional parts. In essence,
it then assumes the task of ordering the interactions.

Some programming languages, like Haskell, make the separation between
those two programming styles explicit in the types and check the
correct separation at compile time. The pure part of the Haskell
language can't do side effects (it doesn't have any operator for
ordering (i.e. no ";")); for that, a separate part of the language is
responsible that *can* do side effects and has explicit ordering (it
has ">>", or the syntactic sugar ";").

Even with only runtime type checking, the same thing *could* be
implemented in Perl, assuming that the *builtin* ordering operator
(the semicolon) is never used (except as implementation of the new,
type-checked, sequencing operator). Disabling sequencing by way of ";"
could perhaps even be implemented as a lowlevel module (e.g. working
on the bytecode level). But then still all the built-in procedures
that do I/O (`print`, `<$fh>` etc.) would need to be overridden to
return wrappers that represent (type-checked) actions, too, to make
type checking possible. This might be fun to work out (or perhaps not
so much when having to deal with all the details), but is out of scope
right now.

But even without type-check based enforcement, the code can be
properly separated into pure and side-effecting parts, and (usually
just the pure part) described as such by documentation and
conventions. What we currently have:

* a convention that functions and methods with names ending in `_set`
  or `_update` are pure (as opposed to the usual way of *starting*
  names with `set_` etc.). See also [naming
  conventions](//design.md#Naming_conventions).

* a base class `FP::Pure` and a predicate `is_pure` (in
  `FP::Predicates`) that allow to indicate that a value is never
  modified.

* everything within the `FP::` namespace is purely functional, at
  least by default (and clearly documented otherwise) (todo: true,
  feasible? Move e.g. `FP::Weak` out? What about `FP::IOStream`?)

Note that not being checked gives you the freedom to decide what's
functional yourself (of course only as long as you're making up rules
that are consistent with all the other rules that govern your
program).

For example, you could decide that certain files don't change during a
program run, and hence can be treated as a constant input. With
`FP::IOStream` you can treat such files as a lazy list of lines or
characters that is only read on demand. (Haskell once offered the same
unsafe approach to read files, but has since moved to a more complex
solution where the type system can still *guarantee* purity, instead
of just assuming it to be the case. Whereas since we don't have an
automatic checker anyway, we don't need to cater to it.)

Also note that pure functions can still use side-effects for their
implementation as long as those are contained so that they are not
observable (for a friendly observer). It could for example use loop
constructs and variable mutation, or temporary data structures that
are mutated, or even write a cache to files in a predetermined (and
documented as 'untouchable') location. But make sure that the purity
doesn't break in exceptional situations, like when (temporarily)
running out of memory, or when exceptions are thrown from signal
handlers; just like the safe way to write files on unix is to write
them to a temporary location then doing a rename to guarantee
atomicity, you shouldn't leave unfinished state linger around when
interrupted or purity breaks.


## Debugging

### General

* Write small functions, test them from an embedded `use Chj::repl;
  repl;` (or `Chj::repl;` if already loaded elsewhere) placed in the
  module body. Write bigger functions by reusing smaller ones. Write
  test cases (using `Chj::TEST` to make it as easy as possible) for
  all of them so that when you need to adapt a function, you can
  refactor it to be parameterized (instead of doing copy-paste
  programming) without fear of breakage.

* You can still use "printf debugging" (plain old `warn` etc.) even
  in pure code.

* When you don't understand what's going on inside a function, place a
  `repl` call right into it and use `:e`, `:b` etc. (see `:?`) to
  inspect the context and experiment with local function calls.

* Add `use Chj::Backtrace;` to your program to see errors with stack
  traces.

* Disable tail call optimizations to see the history of function calls
  (TODO: implement a `Sub::Call::Tail` variant that ignores the tail
  call declarations or lets them be turned on/off at runtime?)


### Lazy code

Debugging lazy code is more challenging since the order of evaluation
appears pretty chaotic and at least unexpected. Hence, in addition to
the tips above:

* Try to get the code working without lazyness first (don't use `lazy`
  forms, use `FP::List` instead of `FP::Stream`). (TODO: write a
  `FP::noLazy` that ignores `lazy` forms or lets them be turned on/off
  at runtime?)

* If you're getting `undef` in some place (like a subtree in a `PXML`
  document missing (maybe triggering an undef warning in the
  serializer)) and you don't know where it happens, and think it's
  because of stream weakening, and just want to get the program
  working first without worrying about memory retention, then disable
  weakening using the offerings in `FP::Weak`.

## Tips and recommendations

* Both `Method::Signatures` and `Function::Parameters` offer
  easy subroutine and method argument
  declarations. `Function::Parameters` has the advantage that it's
  lexically scoped, whereas `Method::Signatures` seems to be tied to
  the namespace it was imported into. This means that in a file with
  `{ package Foo; ... }` style subnamespace parts, it's still enough
  to import `Function::Parameters` just once at the top of the file,
  whereas `Method::Signatures` needs to be imported into every
  package. (Also, it showed confusing error reports when one forgets.) 
  (Todo: did I check the newest version?)

  (Todo: see how argument assertments per predicate could be done.)


</with_toc>

