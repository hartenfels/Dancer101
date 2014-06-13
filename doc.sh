#!/bin/sh
# Combines all documentation into a HTML file, the readme into markdown and
# then removes the temporary files that pod2html leaves laying around.
# Requires pod2html and pod2markdown.
cat doc/dancer101.pod C101/*.pm\
  | pod2html --title=Contribution:Dancer --outfile=doc/dancer101.html
pod2markdown doc/readme.pod readme.md
rm *.tmp

