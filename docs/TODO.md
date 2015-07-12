Check the [functional-perl website](http://functional-perl.org/) for
properly formatted versions of these documents.

---

Also see [[ideas]], and [htmlgen/TODO](../htmlgen/TODO).

<with_toc>

## Licensing

- should I move the licensing statements into the POD of each file?

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


## Code structure

- fix the now horrible hand-optimized-but-convoluted code in
  `PXML::Serialize` (and figure out an automatic way to make it fast)

- avoid the duplication between `FP::List` and `FP::Stream` as much as
  possible.

  - those not using lazy internally: implement the List variants using
    Keep and the stream variants.

- add `join` method for all sequences by finally starting sequences
  base class.

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


## Security, safety

- check 'XX.*[Ss]ecurity' comments


## Names

- rename `PXML` to FXML (functional XML)?

- is it badly inconsistent to have names like `map_with_tail` but have
  the tail-taking function be named `rest`?

- should `FORCE` from `FP::Lazy` be renamed to `Force` to avoid the
  potential conflict with `use PXML::Tags 'force'` ?

Also see [[names]].


## Possibilities

- port `PXML::Element` to `FP::Struct` (it was originally written
  before that existed, iirc). Create a version/extension of
  `FP::Struct` that uses arrays instead of hashes,
  or is that irrelevant and stupid? (benchmark cpu and memory)

</with_toc>
