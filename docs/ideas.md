Check the [functional-perl website](http://functional-perl.org/) for
properly formatted versions of these documents.

---

Also see [[TODO]].


## Various

* "function signatures", or rather runtime function argument type
  checks, using type predicate functions:
  does Method::Signatures need to be modified to support this?
  (Or should Function::Parameters be used instead?)

* reimplement parts in C (Pair, perhaps Promise?) to save some space
  and CPU (but then, that prevents serialization [unless more work is
  done]; also, to really optimize, want a custom/fake SV type that
  includes the pair fields directly?)

* read-only enforcing versions of the functional data structures (or,
  read-only by default, then togglable [or just offering unsafe
  usually-forbidden] mutators); including, especially, FP::Struct as
  potential building block of such data structures

* write sequences API declaration, to code alternative implementations
  against for optimization purposes (runtime coalescence of chained
  operations (something like `->map($f1)->map($f2)->filter($f3)->fold($f4,$x)`
  = `->map_filter_fold(compose($f1,$f2),$f3,$f4,$x)`) (or would
  deforestation be feasible? Or just compile time optimization of the
  same as above?)

* add set API, make `FP::HashSet` and OO based port.

* a variant of Scalar::Util's `weaken` that takes a value to be put
  into the spot that held a reference when it is deleted, so that the
  user can see something more useful like an object that carries a
  message "weakened by stream_ref" (perhaps including caller location)
  or some such instead of undef

  Or, fix the perl interpreter, after all (lexical variable life time
  analysis.) Could this be done as a module working on the byte code?

* Byte code optimizer that automatically turns function calls in tail
  position into gotos, if some 'TCO' pragma is in effect

* Provide a 'recursive let' form that includes weakening or
  application of the fix point combinator

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


## Website

* improve website layout

* when linking to an anchor (like `todo.xhtml#Names`) is there a way
  (without javascript) to make the linked-to item (section header)
  appear high-lighted or something (if the end of the page isn't
  reached, then it's visually clear which item is meant, but items
  towards the end of the page don't have that luxury)


## Not so good ideas

* Add AUTOLOAD to FP::List to auto-generate lisp style c[ad]*r
  accessors? Benchmark the overhead of adding a DESTROY method,
  though!

  Not such a good idea since (a) is someone really using them much?,
  (b) complexity. (See the `c_r` method already implemented first.)


