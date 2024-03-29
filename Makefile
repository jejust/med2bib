# Makefile for bibtex utils

OBJS=med2bib toc2bib jt2bib

all: $(OBJS)
	@echo "All done!"

med2bib: med2bib.c
	$(CC) -O4 -o med2bib med2bib.c
	strip med2bib

toc2bib: toc2bib.c
	$(CC) -O4 -o toc2bib toc2bib.c
	strip toc2bib

jt2bib: jt2bib.c
	$(CC) -O4 -o jt2bib jt2bib.c
	strip jt2bib

clean:
	@/bin/rm -f $(OBJS)
