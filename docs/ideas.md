Check the [functional-perl website](http://functional-perl.org/) for
properly formatted versions of these documents.

---

Also see [[TODO]].

## General

* start an RFC process to work out changes and additions?

## Various

* "function signatures", or rather runtime function argument type
  checks, using type predicate functions:
  does Method::Signatures need to be modified to support this?
  (Or should Function::Parameters be used instead?)

* reimplement parts in C (Pair, perhaps Promise?) to save some space
  and CPU (but then, that prevents serialization [unless more work is
  done]; also, to really optimize, want a custom/fake SV type that
  includes the pair fields directly?)

* add set API, make `FP::HashSet` and OO based port.

* a variant of Scalar::Util's `weaken` that takes a value to be put
  into the spot that held a reference when it is deleted, so that the
  user can see something more useful like an object that carries a
  message "weakened by stream_ref" (perhaps including caller location)
  or some such instead of undef. (Even after changing the interpreter
  to do lexical lifetime analysis, such values can be seen via
  debugger infrastructure (stack locations). But then, instead of
  weaken simple assignments can be used.)

* Byte code optimizer that automatically turns function calls in tail
  position into gotos, if some 'TCO' pragma is in effect

* Provide a 'recursive let' form that includes weakening or
  application of the fix point combinator, like:
  
        my rec ($foo,$bar) =
            sub { $bar->() },
            sub { $foo->() };

* change `FP::Struct` into a Moose extension? Is Moose ok to have as a
  hard dependency? (Because why are there all these Moose alternatives
  like `Moo`?)

  Are `MooseX::Locked`, `MooseX::MultiMethods` good?

  What about the nice-and-simple predicate approach? Extend that to
  make multimethod dispatch still fast? Would that then (really?) be
  the same as `Moose::Util::TypeConstraints`? 

* add functional vector implementation with good computational
  complexity (see paper from which Clojure implemented theirs),
  perhaps base FP::PureArray on it, implement functional hashmap on
  it, implement set with it. (There are implementations on JavaScript
  too, already. Are there any in C?)

* currying, pattern matching, multimethods, ...: see if existing
  modules can be used. Experiment, embrace, extend...

* serialisation of closures, once lexical analysis is present, or/and
  via some declaration of which variables in which order should be
  captured.

## Questions

(For RFC process?)

* Should subtrees of modules (in the namespace hiearchy) be disallowed
  from loading the tree parent? Example: `FP::Repl` implements the
  repl, and uses for example `FP::Repl::Stack` and
  `FP::Repl::corefuncs`. But the latter do not themselves use or
  require `FP::Repl`. OTOH, `FP::Repl::WithRepl` does that--it is a
  'wrapper'. The only reason this module is currently below the
  `FP::Repl` namespace is that it's "related". But perhaps that's a
  bad justification.

* Should various of the more central modules be coalesced into a
  `FP::Core` module (like
  [clojure/core](https://github.com/clojure/clojure/blob/master/src/clj/clojure/core.clj)
  or Haskell's
  [Prelude](https://hackage.haskell.org/package/base-4.12.0.0/docs/Prelude.html))?
  (These tend to be disappointing over time... so perhaps not? There's
  the re-export feature of the `FunctionalPerl` module, maybe just use
  `:core` there and maintain that to be equivalent. Does that make the
  situation any different?)

## Website

* improve website layout

* when linking to an anchor (like `todo.xhtml#Names`) is there a way
  (without javascript) to make the linked-to item (section header)
  appear high-lighted or something (if the end of the page isn't
  reached, then it's visually clear which item is meant, but items
  towards the end of the page don't have that luxury)


