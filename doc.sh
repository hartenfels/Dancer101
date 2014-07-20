#!/bin/sh
doc='$p=Pod::Simple::HTML->new;$p->index(1);$p->parse_from_file'

# combine all documentation and generate HTML file
cat doc/dancer101.pod C101/*.pm | perl -MPod::Simple::HTML -e $doc >doc/dancer101.html

# generate HTML for Web UI documentation
perl -MPod::Simple::HTML -e $doc <doc/web_ui.pod >doc/web_ui.html
