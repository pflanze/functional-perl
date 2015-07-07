Check the [functional-perl website](http://functional-perl.org/) for
properly formatted versions of these documents.

---

# Guidelines to hack on the functional-perl project

See also [[design]].


## Style

* as `*foo` has not shown to be slower than `\&foo` or have other
  drawbacks than ambiguity for type checking, it's often preferred
  for looking visually cleaner.  (XXX should the type checking issue
  perhaps be treated strongly enough to really discourage this
  instead?)

* `XXX` in comments is used to mark important outstanding work (todo),
  `XX` is used for "should probably be improved, but not essential for
  security and safety under normal working conditions".

