(Check the [functional-perl website](http://functional-perl.org/) for
properly formatted versions of these documents.)

---

- clean up licensing (some files currently are MIT license even though
  COPYING claims Perl licensing)

- more `intro/`, more `examples/`

- more tests:

  - more systematic stream leak testing

- replace FP::Lazy with Data::Thunk? This would be cool from a
  transparency stand point, except that separate code by way of
  dynamic dispatch (method calls) *can't* be used anymore then, and
  thus the only code always needs to do the environment cleaning,
  which is bad from a usability perspective since users not working
  with lazy data will still have their variables (unexpectedly)
  deleted. Also, when a Data::Thunk thunk (promise) fails, it won't be
  run again and is instead silently casted to e.g. an integer in
  number context, which will be a usability neightmare.

  Also, what about Params::Lazy?

- xopen_read etc. are throwing exceptions; there are no non-throwing
  variants currently. What interface is preferred for handling errors:
  maybe_ variants that return undef (then assume the error is in $! ?),
  give exceptions types so as to catch them selectively, something
  else? (but, see next Chj::IO comment)

- replace Chj::IO::* with something else?

- work on getting perl issues fixed, see failing tests `t/perl-*`

- messages like "expecting 2 arguments" are unclear and inconsistently
  used for functions reused as methods. How should it be? `flip`
  should work, for example, so do we have to live with methods
  including $self in their argument count?

- which of the car, cdr etc. accessors should weaken their argument in
  the case of streams?

- disable stringification and numerification lexically using "no
  stringification"? But it currently doesn't work with bleadperl
  anymore. -> Just suggest in docs?

- `Sub::Call::Tail` depends on `B::Hooks::OP::Check::EntersubForCV`
  which doesn't work on current bleadperl. Get this fixed.

  Reimplement it on top of `Devel::CallChecker` or
  `Devel::CallParser`?

  (Would it be obsolete if automatic TCO is implemented?)

- rename PXML to FXML?

- rename FP::ArrayUtil to FP::Array; also, possibly generally bless
  result arrays to enable OO? (without requiring the ... module which
  is lexically scoped only anyway)

