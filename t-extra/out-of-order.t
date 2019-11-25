#!/bin/bash

set -euo pipefail
IFS=

# check that tests work even when called in any order; XX for now just
# deletes tail-expanded files, should actually freshly unpack the
# distribution tarball?

# uses scripts from chj-bin, really only meant to be run by the
# maintainer; look at the output whether it contains FAILED or other
# issues
ele bash -c '
for f in t/*.t; do
   rm -rf .htmlgen # XX and all other tail-expanded files
   echo "&&&& $f:"
   if $f; then 
      echo OK
   else 
      echo FAILED
   fi
done
'

