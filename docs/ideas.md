
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

