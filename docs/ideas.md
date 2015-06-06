
* "function signatures", or rather runtime function argument type
  checks, using type predicate functions:
  does Method::Signatures need to be modified to support this?
  (Or should Function::Parameters be used instead?)

* reimplement parts in C (Pair, perhaps Promise?) to save some space
  and cpu

* read-only enforcing versions of the functional data structures (or,
  read-only by default, then togglable [or just offering unsafe
  usually-forbidden] mutators); including, especially, FP::Struct as
  potential building block of such data structures

* write sequences API declaration, to code alternative implementations
  against for optimization purposes (runtime coalescence of chained
  operations (something like `->map($f1)->map($f2)->filter($f3)->fold($f4,$x)`
  = `->map_filter_fold(compose($f1,$f2),$f3,$f4,$x)`)

* a variant of Scalar::Util's `weaken` that takes a value to be put
  into the spot that held a reference when it is deleted, so that the
  user can see something more useful like an object that carries a
  message "weakened by stream_ref" (perhaps including caller location)
  or some such instead of undef

  Or, fix the perl interpreter, after all (lexical variable life time
  analysis.)

