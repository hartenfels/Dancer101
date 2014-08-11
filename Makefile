EXECUTABLES = $(wildcard *.plx)
MODULES     = $(wildcard C101/*.pm)
PERL_FILES  = $(EXECUTABLES) $(MODULES)

all: doc test html

html: public/web_ui.html

doc: doc/dancer101.html

test: results

clean:
	rm -f public/web_ui.html doc/dancer101.html results

public/web_ui.html:
	GET https://rawgit.com/hartenfels/WebUI101/master/dist/web_ui.html > public/web_ui.html

doc/dancer101.html: $(PERL_FILES)
	cat doc/dancer101.pod $(PERL_FILES) \
	| perl -MPod::Simple::HTML \
	  -e '$$p=Pod::Simple::HTML->new;$$p->index(1);$$p->parse_from_file' \
	> doc/dancer101.html

results: $(PERL_FILES)
	perl -c dancer101.plx && perl test101.plx | tee results


.PHONY: all clean doc test html
