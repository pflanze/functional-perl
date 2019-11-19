Check the [functional-perl website](http://functional-perl.org/) for
properly formatted versions of these documents.

---

# The design principles used in the functional-perl library

<with_toc>

## General

### Be properly functional first.

As already mentioned in the introduction on the [[howto]] page, the
modules are built using the functional paradigm from the ground up (as
much as makes sense; e.g. iterations in simple functions are often
written as loops instead of tail
recursion<small><sup>1</sup></small>). A sequences API to build
alternative implementations (like iterator based, or optimizing away
intermediate results) might be added in the future.

<small><sup>1</sup> But this is mainly done just because it's
(currently) faster, and since currently Perl does not offer
first-class continuations.  Avoiding loop syntax and using function
calls everwhere makes it possible to suspend and resume execution
arbitrarily in a language like Scheme, without mutation getting in the
way; but this doesn't apply to current Perl 5.</small>

### Try to limit dependencies if sensible.

E.g. avoiding the use of `Sub::Call::Tail`, `Method::Signatures`,
`MooseX::MultiMethods` or `autobox` in the core modules. (Some tests,
[examples](../examples/README.md) and [Htmlgen](../htmlgen/README.md)
use them.)

### Generally provide functionality both as functions and methods.

*NOTE: since this was written, the method call based style has become
 the primary way to provide functionality, and function based access
 is spotty now. TODO: rewrite this section.*

The sequence processing functions use the argument order conventions
from functional programming languages (Scheme, Ocaml, Haskell). The
methods move the sequence argument to the object position.

For example, both

    list_map *inc, list (1,3,4)

and

    list (1,3,4)->map (*inc)

result in the same choice of algorithm. The shorter method name is
possible thanks to the dispatch on the type of the object. Compare to:

    stream_map *inc, array_to_stream ([1,3,4])

or the corresponding

    array_to_stream ([1,3,4])->map (*inc)

which shows that there's no need to specify the kind of sequence
when using method syntax.

This actually needed an implementation trick: streams are just
lazily computed linked lists, hence the object on which the `map`
method is being called is just a generic promise. The promise could
return anything upon evaluation, not just a list pair. Thus it can't
be known what `map` implementation to call without evaluating the
promise. After evaluation, it's just a pair, though, at which point
it can't be known whether to call the `list_map` or `stream_map`
implementation. So how it works is that promises have a catch-all
(AUTOLOAD), which forces evaluation, and then looks for a method
with a `stream_` prefix first (which will find the `stream_map`
method in this example). If that fails, it will call the original
method name on the forced value.

So the way to make it work both for lazily and eagerly computed pairs
is to put both a `map` and a `stream_map` method into the
`FP::List::List` namespace (which is the parent class of
`FP::List::Pair` and `FP::List::Null`). When the pair was provided
lazily, the above implementation will dispatch to `stream_map`, which
normally makes sense since the user will want a lazy result from a
lazy input.

Note that this dispatch mechanism is only run for the first pair of
the list; afterwards, the code stays in either `list_map` or
`stream_map`(*). This means that prepending a value to a stream makes
the non-lazy map implementation be used:

    cons (0, array_to_stream [1,3,4])->map (*inc)

returns an eagerly evaluated list, not a stream. If that's not
what you want, you can still prefix the method name with `stream_`
yourself to force the lazy variant:

    cons (0, array_to_stream [1,3,4])->stream_map (*inc)

returns a stream.

(*) Question: should the dispatch really happen for each cell? Then
the eager part of a mixed list/stream would still be mapped eagerly,
and the lazy part lazily. (TODO: measure the overhead.)

NOTE: providing both functions and methods makes things more
complicated. The reason it was done so far is rather accidental, as
originally only functions were provided. Some functions like `car` and
`cons` are now wrappers that actually do method calls if they
can. `cons` still needs to remain a function because it doesn't
necessarily receive an object as its rest argument. TODO: figure out
whether to continue providing functions, perhaps reduce the offer to
those strictly needed and otherwise request the user to build them on
the fly using `the_method`? Or figure out a way to generate them for
whole packages easily. The second reason other than the need to use
`the_method` is that the functions can take arguments in the same
order as traditional functional programming languages (the object does
not need to come first, and with multiple objects it can be unclear
which to use as the one to dispatch on).

Idea: use `Class::Multimethods` or `Class::Multimethods::Pure` or
`MooseX::MultiMethods` to provide multimethods as alternative to
methods; this would allow to retain the traditional argument positions
and still use short names. (Perhaps look at Clojure as an example?)

### Use of `*foo` vs `\&foo`

Both of these work for passing a subroutine as a value, with the
following differences:

The code reference (`\&foo`):

 - is the same type of data as what the expression `sub { .. }`
   returns, and hence what's most often teached.

 - clearly only ever represents a subroutine, whereas `*foo` is
   ambiguous and can point to any type: the named package entries for
   subroutines, IO handles, scalars, arrays, hashes, plus any other
   kind of object by way of scalars.

 - serialization to bytes is problematic (can only be done using
   complex modules and only for a limited range of Perl code, and
   includes serializing the whole code of the subroutine)

 - can be used as a value in lexical variables as arguments to goto
   even without using a `&` prefix, as in `my $f=\&foo; goto $f`

The glob (`*foo`):

 - looks arguably visually cleaner, and may be easier to type

 - later redefinitions to the subroutine it points to are being
   reflected (as it points to the subroutine indirectly by name)

 - can be serialized easily (as it's just a *name*)

 - nicer for debugging, as one can directly see the subroutine package
   and name, not just an anonymous code ref

 - this code fails: `my $f=*foo; goto $f`. But this still works:
   `my $f=*foo; goto &$f`. (`Sub::Call::Tail`'s `tail` is fine.)

 - there are no builtin perl checks for the wrong type, i.e. passing
   `*foo` where an array reference is expected will silently access
   the `@foo` package variable, even if it was never declared (empty
   in this case), while passing `\&foo` would have the interpreter
   point out the error.

Quick benchmarking of subroutine calls of the two variants did not
detect a performance difference. For its benefits, this project has
decided to prefer the glob both in documentation and in cases where
the value is only handled by code maintained by the project. In cases
where it returns subroutines to users, at this time it prefers code
refs to avoid potential confusion and breakage. In any case, all code
provided by this project is able to handle globs where subroutines (or
any kind of callables, including overloaded objects) are expected.

`FP::Predicate`'s `is_procedure` accepts globs if they contain a value
in the CODE slot, i.e. it adapts its meaning to "*can* represent a
subroutine". (But Todo: should it return true for any other callable
(overloaded object) as well? (How can the latter be implemented, by
way of checking for a '(&' method?))


### Naming conventions

* Functions names are generally choosen to prefer "established"
  functional languages (like Scheme, Haskell, Ocaml, rather than
  JavaScript or even Clojure). The name `fold` is hence preferred over
  `reduce` (which has a slightly different interface in JavaScript and
  Clojure; well, no problem if you really want it with that interface,
  we could add it, too). Also all other languages call the filtering
  function `filter`, not `grep`, for example, and hence it's
  `list_filter` or the method name `filter` here. (Hopefully you'll be
  ok with that recognizing that the Perl builtin has a weird,
  "non-functional" interface anyway.)

* Function names *start* with the data type that they are made for;
  for example `array_map` versus `list_map`. (This follows the
  conventions in Scheme (and some other functional languages?).)
  Of course method (and multimethod) names don't need to, and
  shouldn't, carry the name of the data type. (The `stream_` prefix in
  method names already mentioned above is an exception: it's to
  explicitely choose, and also not really a type choice but an
  evaluation strategy choice.)

* Predicates (functions that check whether a value fulfills a type or
  other requirement (or in general return a boolean?)) start with
  `is_`; but if they only work for a particular data type, the put the
  `is` after the type name (something like `array_is_pure`).

* Data conversion functions are now named with `_to_` (previously with
  `2`), e.g. `array_to_list`. This follows the convention in Scheme
  (except `->` is used there instead of the `_to_`), but not that of
  Ocaml, where such functions are called e.g. `list_of_array`. Method
  names for the same omit both the source type name and the `_to_`
  (e.g. `->array`).

* The `maybe_` prefix is used for variables and functions which
  bind or return `undef` as indication for the absence of a value. The
  `perhaps_` prefix is used for functions which return `()` as
  indication for the absence of a value. `possibly_` is used for
  functions which might return an argument unchanged (i.e. not do
  anything). Also, functions always return exactly one value unless
  they have a `perhaps_` prefix or a name that indicates plural and
  there's a good reason that the values are not returned in an array
  or linked list instead; this is to reduce the risk of accidental
  argument misalignment in function calls that have function calls as
  subexpressions.

  See `FP::Optional` for more on this.

* Since handling arrays and hashes by reference is the normal way of
  working functionally (see
  [[howto#References_and_mutation,_"variables"_versus_"bindings"]] for
  why), naming things `array` and `hash` is preferred over `arrayref`
  and `hashref`. (`_ref` is used in names of functions/methods to
  access fields in data structures (e.g. a function that takes an
  array and an index and returns `$array->[$index]` would be called
  `array_ref`).)

* Functions that compose several other functions into one for
  efficiency are named from the names of the functions it could be
  composed of with "__" as separator:

        array_reverse (array_map ($f2, array_filter ($f1, $a)))

  becomes

        array_reverse__map__filter ($f2, $f1, $a)

  and

        $a->filter ($f1)->map ($f2)->reverse

  becomes

        $a->reverse__map__filter ($f2, $f1)

  (Todo: should the order in the method case be reversed? 
  (i.e. `$a->filter__map__reverse ($f1,$f2)`) A reason against it is
  that searching for the base function name will find both cases.)

* Functional setters (those which leave their arguments unmodified,
  i.e. for persistent data structures) *end* with `_set` instead of
  starting with `set_` as is common in the imperative world. (This is
  consistent with the Scheme naming conventions (first the type, then
  the field name, then the operation), and hints that it's different
  from imperative code.)

* Procedures and methods which are not safe, i.e. can lead to delayed
  failures instead of reporting an exception right away or lead to
  other violations of the intended behaviour, are prefixed with (or
  contain the string) "unsafe_". This allows to find their usage
  easily using grep or similar. Examples are functions that access
  array or hash fields in their arguments without verifying their
  type, or constructors that reuse a mutable data structure passed as
  argument and return it as ostensibly pure object.

### Error handling

Type safety is important and helpful for constructing correct
programs. For example `ref` methods that take an index do not accept
negative numbers (to mean "from the end"). (Offer a `circular_ref`
method instead.)

Early error reporting is useful because it makes debugging easier. For
example `ref` methods do not return `undef` for invalid indices,
instead they throw exceptions.

There's also the approach of using error *values*; `FP::Failure` is a
start (TODO: perhaps provide `FP::Result`, `FP::Maybe`). In general
though using exceptions is fine since native to Perl, and fast, not
planning to replace this.


## Purity

*NOTE: current Perl versions support immutability, and using it has
 been enabled in some of the modules; TODO: make this support
 complete, and rewrite this section.*

Perl does not have a compile time type checker to guarantee
(sub-)programs to be purely functional like e.g. Haskell does, but
programs could still enforce checks at run time.

The `FP` libraries do not currently enforce purity anywhere, it just
does not offer mutators (except for array or hash assignment to the
object fields). It helps the user writing pure programs, but does not
enforce it. This works well for projects written by single developers
or perhaps also small teams, where you know which subroutines and
methos are pure by way of remembering or naming convention, or where
checking is quick. But in bigger teams it might be useful to be able
to get guarantees by machine instead of just by trust. Thus it is an
aim of this project to try to provide for optional runtime enforcement
of purity (in the future).

### Use `FP::Abstract::Pure` as base class for (in principle) immutable objects

And let `is_pure` from `FP::Predicates` return true for all immutable
data types (even if they are not blessed references.) 
(`is_pure_object` will only return true for actual objects.)

The idea is to be able to assert easily that an algorithm can rely on
some piece of data not changing.

(Currently) the rule is that a data structure is considered immutable
if it doesn't provide an exported function, method, or tie interface
to mutate it. For example mistreating list pairs by mutating them by
way of relying on their implementation as arrays with two elements and
mutating the array slots does not make them a(n officially) mutable
object.

The libraries inheriting from `FP::Abstract::Pure` *should* try to disable such
mutations from Perl code; they might be useful in some situations for
debugging, though, so leaving open a back door that still allows for
mutation (like using a mutator that issues a warning when run, or a
global that allows to turn off mutability protection) may be a good
idea. In general, mutations that are purely debugging aids (like
attaching descriptive names to objects or similar) are excluded from
the rule.

Algorithms that want to use mutation, even if rarely (like creating a
circular linked list without going through a promise, or copying a
list without using stack space or reversing twice (but copying a pure
list doesn't make sense!)) must rely on mutable objects instead (like
mutable pairs (todo)).

Closures can't be treated as immutable in general since their
environment (lexicals visible to them) can be mutated. (Todo: provide
syntax (e.g. 'purefun' keyword) that blesses closures (if manually
deemed pure)? Note that should this ever be implemented, purity checks
shouldn't be added too often, as e.g. passing an impure function to
`map` is ok if the user knows what he is doing. But offering a
guaranteed pure variant of `map` that *does* restrict its function
argument to be pure might be useful. Instead of creating a mess of
variants, something smarter like a pragma should be implemented
though.)


## Lazyness

*NOTE: There is `FP::TransparentLazy` now. TODO: rewrite this
 section.*

Promises created with `FP::Lazy` are not automatically forced when
used by perl builtins (todo: should they?). Also, type predicates
usually don't force them either, the exception is currently `is_null`,
so that `FP::List` does not need to care about lazy code. (Perhaps
this should be changed? But it can't be fully transparent anyway since
e.g. `ref` will always return the promise namespace.)

OTOH, method calls on promises are always forcing the promise and are
then delegated to the value the promise returns.

Some functions like `car` and `cdr` (`first` and `rest`) are forcing
them, too (TODO: actually this is coded explicitely, but instead those
functions should probably simply be defined as `the_method ("car")`
etc., which would still force them, and be properly OO).

The current mix seems to work well, but details are still open for
change.


## Various / "Hacking"

* The project is now using spaces for indentation (no tabs).


</with_toc>

