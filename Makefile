# Makefile for bibtex utils

all: med2bib toc2bib
	@echo "All done!"

med2bib: med2bib.c
	$(CC) -O4 -o med2bib med2bib.c
	strip med2bib

toc2bib: toc2bib.c
	$(CC) -O4 -o toc2bib toc2bib.c
	strip toc2bib