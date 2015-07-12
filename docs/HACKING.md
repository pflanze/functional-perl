Check the [functional-perl website](http://functional-perl.org/) for
properly formatted versions of these documents.

---

# Guidelines to hack on the functional-perl project

See also [[design]].


## Style

* as `*foo` has not shown to be slower than `\&foo` or have other
  drawbacks than ambiguity for type checking, it's often preferred
  for looking visually cleaner.  (Todo: should the type checking issue
  perhaps be treated strongly enough to really discourage this
  instead?)

* `XXX` in comments in source code is used to mark important
  outstanding work, `XX` is used for "should probably be
  improved, but not essential under normal working conditions".
  In text files, 'todo' is used.


## Testing

### Perl issues

Tests that depend on the Perl core being fixed are only run if the
`TEST_PERL` env variable is true. I.e. run

    TEST_PERL=1 make test

or similar.

