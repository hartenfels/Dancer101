TEXFILE  = dancer101.tex

all: presentation handout

presentation: presentation.pdf

handout: handout.pdf

clean:
	rm -rf .tmp
	rm presentation.pdf handout.pdf

presentation.pdf: $(TEXFILE) | .tmp
	perl -E 'local $$/; open($$f, "<", "$(TEXFILE)") or die; print("\\documentclass[12pt,slidestop]{beamer}\n", <$$f>)'\
	   | pdflatex -jobname=presentation -output-directory=.tmp
	mv .tmp/presentation.pdf .

handout.pdf: $(TEXFILE) | .tmp
	perl -E 'local $$/; open($$f, "<", "$(TEXFILE)") or die; print("\\documentclass[12pt,slidestop,handout]{beamer}\n", <$$f>)'\
	   | pdflatex -jobname=handout -output-directory=.tmp
	mv .tmp/handout.pdf .

.tmp:
	test -d .tmp || mkdir -p .tmp

.PHONY: all presentation handout clean

