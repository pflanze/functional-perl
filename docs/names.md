Check the [functional-perl website](http://functional-perl.org/) for
properly formatted versions of these documents.

---

There are many function and module names that have doubtful names. If
you've got some comments on some names, like how the same or similar
functions are named in other languages or ideas on how they could be
named for more consistency, please [tell](//mailing_list.md).

This list of doubtful names is not exhaustive.

- is it badly inconsistent to have names like `map_with_tail` but have
  the tail-taking function be named `rest`?
- should `FORCE` from `FP::Lazy` be renamed to `Force` to avoid the
  potential conflict with `use PXML::Tags 'force'` ?
- rename `PXML` to FXML (functional XML)?
- `array_to_hash_group_by`
- `compose_1side`
- `pxml_map_elements_exhaustively`
- should `stream_iota` be renamed or have different arguments? Compare
  with APL etc.
- `the_object_method`
- `Chj::WithRepl`, `WithRepl_eval`, `Chj::Trapl`
- `FP::Struct`: rename to `FP::Class` or should that name remain
  reserved for a new implementation on top of `Moose` or something?
- should `null` always be used, including instead of `empty_trie`
  etc. (i.e. rename those to `null_trie` etc.)?


## TODO

- rename csvstream_to_fh to rows_to_csv_fh,
  csvstream_to_file to rows_to_csv_file, etc.
