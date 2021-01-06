Check the [functional-perl website](http://functional-perl.org/) for
properly formatted versions of these documents.

---

<with_toc>

## Guide

This is to give a quick overview of what should be done next. If you'd
like to scan through all possible work (or like to lose yourself), see
"Items" below.

* Finish `FP::AST::Perl` and rework `FP::Abstract::Show` to use it.
* Find the people potentially interested in this project.
* Collect and discuss open questions, perhaps via RFC processes,
  including:
    * General design and structure
    * Plan automatic lexical lifetime and TCO analysis
        * Perl AST in C to make it efficient?
    * Decide where to go with the experimental approaches taken,
      including:
        * Preferred way to create functional classes (`FP::Struct`
          or?)
        * Preferred way to make abstract classes and/or protocols.
        * Preferred way for equality (`FP::Abstract::Equal`) and
          comparison (`FP::Abstract::Compare`)
* Use for some (experimental) projects, gain experience, report/fix
  bugs.
* Videos (screen recordings), articles, talks.


## Items

This is an unsorted collection of items to work on.

See also [[ideas]], [[htmlgen/TODO]], [[functional_XML/TODO]] and the
"todo" markers in text (website / .md) files. Also, the [[names]] page.

### Features

* add a `pairkeys` method to `FP::Abstract::Sequence` (doing the
  equivalent of `->chunks_of(2)->map(the_method "first")` or
  `List::Util` 1.29's function of the same name)

### Work on the code

* In bin/perlrepl and bin/fperl, use the proper perl version in the
  shebang line; yet, still allow them to be run locally (project not
  installed). How?

* rename "hidden" methods like `FP_Equal_equal` to all-uppercase like
  `FP_EQUAL__EQUAL` as that seems to be preferred (`TO_JSON` was given
  as an example)

* Finish unmerged work on FP::Repl (see note from this commit in
  [intro])

* See entries in BUGS pod sections (e.g. `FP::Show` and `FP::Equal`
  cycles, `FP::Repl` bugs)

* `FP::Failure`: add tests. Solve the `complement` issue (which would
  mean, make FP::Result and use that)? Also: `failure`, since it
  overloads boolean, can basically only be used in boolean contexts,
  where the non-failure case is just true, since otherwise (the
  success case is itself a boolean) it would be dangerous in handling.

* Add an Error data type, similar to `FP::Failure`, but which wraps
  the success case as well?

* Consistently use "{ package Foo; ... }" or "package Foo { ... }"
  (latter if compatible with the minimal required Perl version)

* Rename `is_null` to `is_empty`? I'm torn. `null` to `empty`?

* Should I or should I not move modules that implement functions to
  `FP::Lib::` or something? They are still about a type; but
  `FP::Array` may break it (will want to use `FP::Array` as the class,
  hence `FP::Lib::Array` for the functions?)

* Rename `FP::Struct` to `FP::Define::Struct`?

* Make generic functions (for sequences) that work with both objects
  (which implement the method of the same name) and non-objects that
  are of the same kind; e.g. `first([3, 4])` and `first(list 3, 4)`
  would both return `3`. (Will conflict in the case of `map` with the
  built-in, though.) -- May not be useful enough any more given that
  there's now `FP::autobox`.

* Immutable and mutable blessed strings?

* Currently `purearray(3,4)->cons(2)->map(\&inc)` is broken. Figure out
  which way to go, perhaps implement `FP::Vec` first? How does Clojure
  handle it again?

* In `t/pod_snippets`, remove entries from the ignore list and fix
  their pod snippets. Also, now that pod snippets can be tested
  directly, remove duplicates of tests e.g. in `t/fp-struct` (and in
  general move tests to POD?)
  
* Systematically go through the docs and update it. Use/make something
  like POD snippets for markdown and change the docs to use examples
  and then automatically check that they are up to date.

* Make the remaining pure datastructures immutable, unless requested
  by user (using similar approach like taken in `FP::List`),
  e.g. StrictList; and them to `FP::Abstract::Pure`.
  
* Change `FP::Struct` to allow mutable private fields that don't
  impede `FP::Abstract::Pure` (see comments in FP::Struct)?

* Consistently `use Scalar::Util qw(reftype)`? What was the point
  again of using this over `ref` or `UNIVERSAL::isa` for `CODE` and
  such?

* die vs. croak: die is nice since `FP::Repl::Trap` will go to the real
  location, how is the situation with croak? (Also, `Chj::Backtrace`?)
  In `FP::Repl`, skip call frames within `Carp` and similar like
  `FP::Repl::WithRepl` (maybe the same way calling code from `Carp`, or
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

* Show: handle cycles; pretty printing. Also, add an auto-forcing
  dynamic parameter and print immediately instead of building a string
  (have `show` just capture that)?

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

* Consistency check: any method/function that returns a maybe or
  perhaps type must be named appropriately, otherwise throw exceptions
  on errors. Or: Error data type above?

* Implement `FP::Vec`, a data structure with both efficient functional
  updates and efficient random access. RandomAccessSequence
  protocol. Then hash maps with the same properties. (In C for speed?
  For algorithms, see Clojure.)

* Add ->[$i] to RandomAccessSequence protocol. Move ref and set over
  to RandomAccessSequence protocol?

* `FP::Repl::Trap`, `FP::Repl::AutoTrap`, tests: check `DEBUG` or `BACKTRACE`
  or similar env var(s) to make it possible to enable permanently in
  the code but stay really safe (never break the situation for any
  user). Write docs about it.

* Similar to the above point, `RUN_TESTS` should be streamlined /
  automated (any program should ~by default allow to have its tests
  run by simply setting this env var (OK?); `perhaps_run_tests` does
  part of the job).

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

* Add a Changes file.

* e.g. when implementing `FP::Interfaces`, how to collect the values
  from all super classes? Well, use `NEXT::` and make these methods
  folds (take a rest argument)!

* Mostly eliminate the use of `FP::DumperEqual` (replace with
  `FP::Equal`). Also, make `TEST` use `equal` so that there's no need
  to `->array`.

* Make `FP::StrictList` implement `FP::Abstract::Sequence`.

* Repl: support language server protocol for IDE integration?

* Get rid of `test.pl` script, as this is old style and not necessary
  anymore? But I'm setting an env var and define the ordering there,
  how?

* Perhaps do not use all-lowercase module namings

* `Test::Needs` has been recommended over `Test::Requires` "for reasons specified in its documentation", look into it.

* Performance: look into inlining for speed sensitive code? Have a
  look at `Class::XSAccessor`, or mst mentioned some underdocumented
  crazy way.

### Get rid of unnecessary home-grown code

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

- merge FP::Repl with other repls/debuggers? Also,
  Chj::{FP::Repl::Trap,WithRepl,Backtrace}. They are still fertile grounds for
  experimentation, though, thus shouldn't merge things too soon.

- maybe `FP::Path` is not general or useful enough to keep

### Licensing

- should I move the licensing statements from the top of the files
  into the POD section of each file?

- should I specify a license for the text? A different one than the
  ones for the code? Who should be the copyright holder of the
  website, "the project"?


### Documentation and tests

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


### Other people's code

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

- extend Data::Dumper (or alternative dumper(s)) to show a simpler
  syntax for linked lists, and streams (and perhaps more) (mostly for
  the repl, but also in general):

        FP::list(1,2,3)  # instead of bless [1, bless [2, bless ...],...

  (Show only evaluated part of streams (and the rest as a promise), or
  force evaluation of the first n items then cut off the same way as
  for lists?)


### Code structure

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


### Security, safety

- check 'XX.*[Ss]ecurity' comments


### Possibilities

- port `PXML::Element` to `FP::Struct` (it was originally written
  before that existed, iirc). Create a version/extension of
  `FP::Struct` that uses arrays instead of hashes,
  or is that irrelevant and stupid? (benchmark cpu and memory)

</with_toc>
