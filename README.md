# med2bib & bibTOhtml

Please see the original website at <http://ilab.usc.edu/bibTOhtml/>

Copyright © 2000 by the University of Southern California, iLab and [Prof. Laurent Itti](mailto:itti@pollux.usc.edu).



## med2bib - Convert Medline to BibTeX


**med2bib** converts MEDLINE full-record ASCII bibliographic entries for journal articles into BibTeX entries. **toc2bib** converts TOC/DOC (the electronic literature search engine available at Caltech) full-record entries.

All entries from your medline file or tocdoc file are parsed, converted into BibTeX fields, and appended to the end of your bibtex file (no checking is done as to the nature of the bibtex file).

A key is automatically generated for each entry. It is used in \cite{key} commands in LaTeX files, to cite the entry. Key generation rules are:

- if one author, year YY: AuthorYY (_e.g._, Wilson80)
- if 2 authors, year YY: Author1_Author2YY (_e.g._, Hubel_Wiesel62)
- if more than 2 authors: Author1_etalYY (_e.g._, Koch_etal96)

For each entry processed, a citation in short-hand format is output to stderr, so that you can check for progress and bugs.

No checking for duplicate keys is done. Only article BibTeX entries are generated, with fields: author, title, journal (abbreviated in MEDLINE but not in TOC/DOC), volume, number, pages, month (MEDLINE only), year, abstract, keyword (separated by `|`), address, note (contains MEDLINE notes (_e.g._, publication of an erratum) and language if not English).

**NEW IN VERSION 1.03 [2 Aug 2000]:** Medline page numbers corrected to long format (_e.g._, 1234-1256 instead of 1234-56) and added script `medref` to automatically query pubmed and convert results. Contributed by [Olav Kongas](mailto:kongas@ioc.ee) and [Marko Vendelin](mailto:markov@ioc.ee).

Download [`med2bib-1.03.tar.gz`](http://ilab.usc.edu/bibTOhtml/med2bib-1.03.tar.gz)

**NEW IN VERSION 1.04 [24 Oct 2003]:** Bugfix of Medline page numbers when article has only one page. Contributed by [Stephan Imfeld](mailto:imfeld@geo.unizh.ch). Bugfix to support new pubmed format that starts with a PMID field rather than a UI field like it used to. Contributed by [Jérémy Just](mailto:just@inapg.inra.fr).

Download [`med2bib-1.04.tar.gz`](http://ilab.usc.edu/bibTOhtml/med2bib-1.04.tar.gz)

Download [`biblio-1.04.tgz`](http://ilab.usc.edu/bibTOhtml/biblio-1.04.tgz). This is a bundled download, which is a snapshot of our CVS tree. It contains some work-in-progress code that may not be usable or of interest to you. Please see the `README`s.


## bibTOhtml - Convert BibTeX to HTML

**bibTOhtml** is a small perl script that takes a BibTeX file as input and outputs a set of HTML pages. See our [publication pages](http://ilab.usc.edu/publications/) for an example of output.

We had negative 10 minutes to write this script, so it comes with no real interface, documentation, or anything. The definitions which you can change to customize it to your needs are all at the top of the perl code, which should make it easy to edit.

Download [`bibTOhtml-1.00.tar.gz`](http://ilab.usc.edu/bibTOhtml/bibTOhtml-1.00.tar.gz)

**New (Aug 1, 2002):** For the current version of the script itself, with some minor enhancements compared to the script in the above tar file, check [here](https://github.com/jejust/med2bib/blob/main/bibTOhtml) (you still need to get the tar file for the other files necessary to actually run the script).
