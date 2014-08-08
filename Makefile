MODULES = $(wildcard C101/*.pm)

all: web_ui doc test

web_ui: public/web_ui.js

doc: doc/dancer101.html

test: results

clean:
	rm public/web_ui.js doc/dancer101.html results


public/web_ui.js: public/web_ui.coffee
	coffee -c public/web_ui.coffee

doc/dancer101.html: $(MODULES)
	cat doc/dancer101.pod $(MODULES) \
	| perl -MPod::Simple::HTML \
	  -e '$$p=Pod::Simple::HTML->new;$$p->index(1);$$p->parse_from_file' \
	> doc/dancer101.html

results: $(MODULES) dancer101.plx test101.plx
	perl -c dancer101.plx && perl test101.plx | tee results


.PHONY: all clean web_ui doc test
