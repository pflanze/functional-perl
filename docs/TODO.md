Check the [functional-perl website](http://functional-perl.org/) for
properly formatted versions of these documents.

---

See also [[ideas]], [[htmlgen/TODO]], [[functional_XML/TODO]] and the
"todo" markers in text (website / .md) files. Also, the [[names]] page.

<with_toc>

## Work on the code

* There is a bug (warning) with unicode in one of the build files,
  track down and fix.

* Rename `is_null` to `is_empty`? I'm torn. `null` to `empty`?

* Should I or should I not move modules that implement functions to
  `FP::Lib::` or something? They are still about a type; but
  `FP::Array` may break it (will want to use `FP::Array` as the class,
  hence `FP::Lib::Array` for the functions?)

* Make generic functions (for sequences) that work with both objects
  (which implement the method of the same name) and non-objects that
  are of the same kind; e.g. `first([3, 4])` and `first(list 3, 4)`
  would both return `3`. (Will conflict for `map`, though.) Or
  instead, hack the interpreter to have core types be implicitly
  blessed into some base packages (like `ARRAY`), then install methods
  there?

* Change `FP::Array` to offer a base class for mutable (but still
  blessed) arrays (keeping `FP::PureArray` for immutable ones). Use
  `autobox` with it?

* Immutable and mutable blessed strings?

* Currently `purearray(3,4)->cons(2)->map(*inc)` is broken. Figure out
  which way to go, perhaps implement `FP::Vec` first? How does Clojure
  handle it again?

* In `t/pod_snippets`, remove entries from the ignore list and fix
  their pod snippets.
  
* Make `FP::Struct` immutable, unless requested by user (using similar
  approach like taken in `FP::List`); like wise for StrictList etc.;
  and them to `FP::Abstract::Pure`. Change `FP::Struct` to only
  implement purity if there are no mutable fields.

* Think through UNIVERSAL::isa and UNIVERSAL::can, use `Safe::Isa` if
  decide that have to, or otherwise appropriately (handling of
  promises, should it let methods shine through via can?)

* die vs. croak: die is nice since `Chj::Trapl` will go to the real
  location, how is the situation with croak? (Also, `Chj::Backtrace`?)
  In `Chj::Repl`, skip call frames within `Carp` and similar like
  `Chj::WithRepl` (maybe the same way calling code from `Carp`, or
  perhaps `Trace::Mask`)?

* Would it be possible to write either an XS module that allows to
  cancel an ongoing `die` from within a `$SIG{__DIE__}` handler, or
  one that allows to set up another hook for die (in all relevant
  cases like `die ..`, `1/0`, `use warnings FATAL => ..`).

* Idea: set slots to an object that reads like "value optimized away"
  (perhaps an object of class `FP::_ValueOptimizedAway_`) instead of
  to undef when letting go of values (OK, `weaken` uses undef of
  course; but possibly weaken won't be necessary anymore once lexical
  analysis exists and the interpreter can handle deletions at the call
  site)

* Add a `boolean_eq` function?

* Should there be a show protocol (FP::Abstract::Show)? Currently show
  falls back to data dumper anyway, so does anything implement it?
  Also, have a pretty printing show?

* Be consistent with exceptions, `array_drop [4], 3` should probably
  give one.

* Add tests (or move existing ones over?) across all sequences
  (i.e. add test suites for protocols)

* Rename FP::Abstract:: to FP::Protocol:: (and then probably also
  `FP::Interface` to `FP::Protocol`)? (Pro: "implement a protocol" or
  "using the foo protocol" sounds better than "implement an abstract
  class" or "following the foo abstract class"; con: protocol can be
  mistaken as a wire protocol. "Mixin" isn't the proper term
  especially since this term seems to be understood to not add to
  @ISA; "interface" means just the call interface (no method
  definitions in the interface), with no base functionality that is
  required to work.)

* Get `Sub::Call::Tail` working again, or replace it with something
  new (really just an OP tree transformation)?

* Get a prototype for lexical analysis (for automating the letting go
  of stream heads) in Scheme and produce Perl code to do the
  same. Then see how to implement it in the Perl interpreter (enabled
  with pragma).

* Implement a recursive let syntax, `my rec`?

* Implement a range abstraction/data type. Implement sequence
  protocol.

* Sequence optimization:
  `$foo->prep->map(..)->filter(..)->map(..)->list` to optimize away
  intermediate data structures. (See Clojure's transducers.)

* Reference count based optimization: mutate if there's only a single
  holder.

* Add an Error data type which auto-explodes in void context (or when
  unhandled)?

* Consistency check: any method/function that returns a maybe or
  perhaps type must be named appropriately, otherwise throw exceptions
  on errors. Or: Error data type above?

* Implement `FP::Vec`, a data structure with both efficient functional
  updates and efficient random access. RandomAccessSequence
  protocol. Then hash maps with the same properties. Red-Black
  trees. (Speed though, C?)

* Add ->[$i] to RandomAccessSequence protocol. Move ref and set over
  to RandomAccessSequence protocol?

* `Chj::Trapl`, `Chj::AutoTrapl`, tests: check `DEBUG` or `BACKTRACE`
  or similar env var(s) to make it possible to enable permanently in
  the code but stay really safe (never break the situation for any
  user). Write docs about it.

* For type checks in `FP::Struct` (perhaps move those out to separate
  module), as well as maybe protocol checks: have warning and die
  modes, selectable via env variable? Also, disable completely for
  speed via same mechanism (but that one would be compile time?)?

* `Chj::TEST` should compare via `FP::Equal`; resulting values like
  `list(1,2,3)` can then be used. OK not to handle values that do not
  implement the protocol?

* Should (most) prototype declarations really be removed? (Pro:
  equal(@_) doesn't work, any similar issues?; `is equal $a,$b, $c`
  doesn't work anyway; con: why provide a syntactically rich language
  if it's not to be used (but, where does it help?))

## Get rid of unnecessary home-grown code

These may better be replaced by more widely used code, roughly in the
order of most likely replacement (those replaced most easily or
usefully listed first).

- `Chj::xperlfunc`: maybe `use autodie`, although I'm somewhat wary of
  the fact that this way it's not directly visible anymore whether a
  call dies or not. Also, there are various utilities like xspawn,
  xxsystem etc. that need replacing, too.

- `Chj::xopen*`, `Chj::xtmpfile`, `Chj::xpipe`, `Chj::IO::*`

- should `Chj::TEST` stay or be made a lexical extension of other test
  modules?

- migrate `FP::Struct` functionality as Moose extensions or something?

- merge Chj::Repl with other repls/debuggers? Also,
  Chj::{Trapl,WithRepl,Backtrace}. They are still fertile grounds for
  experimentation, though, thus shouldn't merge things too soon.

- maybe `FP::Path` is not general or useful enough to keep

## Licensing

- should I move the licensing statements from the top of the files
  into the POD section of each file?

- should I specify a license for the text? A different one than the
  ones for the code? Who should be the copyright holder of the
  website, "the project"?


## Documentation and tests

- document the change in recent (blead) perl with regards to lexical
  capture and weak references (e.g. see `FP::DBI` commit 8862338..) in
  the howto

- more `intro/`, more `examples/`

- more tests:

  - more systematic stream leak testing.
    Idea: LEAK_TEST forms in `Chj::TEST` (see comment in `FP::Stream`)

  - tests for `Chj::TEST` itself

  - systematic testing of mixed FP::List / FP::PureArray
    etc. sequences. (etc.)


## Other people's code

- replace `FP::Lazy` with `Data::Thunk`? This would be cool from a
  transparency stand point, except that separate code by way of
  dynamic dispatch (method calls) *can't* be used anymore then, and
  thus the only code always needs to do the environment cleaning,
  which is bad from a usability perspective since users not working
  with lazy data will still have their variables (unexpectedly)
  deleted. Also, when a `Data::Thunk` thunk (promise) fails, it won't be
  run again and is instead silently casted to e.g. an integer in
  number context, which will be a usability neightmare.

  Also, what about `Params::Lazy`?

- `Sub::Call::Tail` depends on `B::Hooks::OP::Check::EntersubForCV`
  which doesn't work on current bleadperl. Get this fixed.

  Reimplement it on top of `Devel::CallChecker` or
  `Devel::CallParser`?

  (Would it be obsolete if automatic TCO is implemented?)

- replace Chj::IO::* with something else?

- work on getting perl issues fixed, see failing tests `t/perl-*`

- disable stringification and numerification lexically using "no
  stringification"? But it currently doesn't work with bleadperl
  anymore. -> Just suggest in docs?

- change `FP::Array` to use `autobox`? (But that's lexically scoped, how
  will that 'scale'? Or, what about blessing and then providing an
  overload for dumping? Not exist, right. What about writing an
  alternative Dump?)

- extend Data::Dumper (or alternative dumper(s)) to show a simpler
  syntax for linked lists, and streams (and perhaps more) (mostly for
  the repl, but also in general):

        FP::list(1,2,3)  # instead of bless [1, bless [2, bless ...],...

  (Show only evaluated part of streams (and the rest as a promise), or
  force evaluation of the first n items then cut off the same way as
  for lists?)


## Code structure

- fix the now horrible hand-optimized-but-convoluted code in
  `PXML::Serialize` (and figure out an automatic way to make it fast).

- finish PXML's HTML5 support.

- improve sequences class hierarchy

    - look at Ord (Ordering) in Haskell etc.

    - avoid the duplication between `FP::List` and `FP::Stream` as much as
      possible.

        - those not using lazy internally: implement the List variants using
          Keep and the stream variants.

- what to do about data types that have both a class and some
  functions, like `is_sequence`, that now lives in `FP::Predicates`,
  and might be moved elsewhere in the future, breaking code importing
  it...?

- messages like "expecting 2 arguments" are unclear and inconsistently
  used for functions reused as methods. How should it be? `flip`
  should work, for example, so do we have to live with methods
  including $self in their argument count? (For this reason, much of
  the code is now simply throwing the message "wrong number of
  arguments" without any indication of the expected
  count. `Function::Parameters` issues "Too many arguments" and "Not
  enough arguments", `Method::Signatures` says "missing required
  argument $a" or "was given too many arguments", both of which are
  good.)

- should `rest` (`cdr`) weaken its argument in the case of streams? 
  (`first` clearly shouldn't, right?)

- add `FP::List`'s `none` and the `all` alias (also, remove `every`
  *or* `all`?) to `FP::Stream`, or to common base class.


## Security, safety

- check 'XX.*[Ss]ecurity' comments


## Possibilities

- port `PXML::Element` to `FP::Struct` (it was originally written
  before that existed, iirc). Create a version/extension of
  `FP::Struct` that uses arrays instead of hashes,
  or is that irrelevant and stupid? (benchmark cpu and memory)

</with_toc>
