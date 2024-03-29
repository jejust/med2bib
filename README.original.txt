==============================================================================
       med2bib and toc2bib: MEDLINE and TOC/DOC to BibTeX conversion
==============================================================================
Copyright (C) 1997, 1998, 1999, 2000 by Laurent Itti, itti@klab.caltech.edu
All rights reserved - Absolutely no warranty - Use at your own risk.
Distribute freely as long as you include this unaltered README file.


Goal:
------------------------------------------------------------------------------
Convert MEDLINE or TOC/DOC search results into BibTeX entries.

A key is automatically generated for each entry. You use the key with \cite
commands in your LaTeX files in order to cite the corresponding entry. Keys
are generated according to the following rules:

- if one author, year YY:  AuthorYY               e.g., Wilson80
- if 2 authors, year YY:   Author1_Author2YY      e.g., Hubel_Wiesel62
- if more than 2 authors:  Author1_etalYY         e.g., Koch_etal96

For each entry processed, a citation in short-hand format is output to
stderr, so that you can check for progress and bugs.


Compiling the software:
------------------------------------------------------------------------------
- Type 'make'.

- Copy 'med2bib' and 'toc2bib' to where your local binaries reside (e.g.,
  /usr/local/bin, or ~/bin);

- Copy 'med2bib.1' and 'toc2bib.1' to where your local man pages reside
  (e.g., /usr/local/man/man1, or ~/man/man1).

Make sure your default C compiler is ANSI-compliant (e.g., a recent
version of the GNU compiler 'gcc'). If this is not the case (e.g., your
'cc' is an old Sun compiler), but you also have gcc installed, add a
line 'CC=gcc' as the second line of the file 'Makefile'.

Tested on a variety of unix flavors.  If you have a different
operating system, consider switching to Linux, a free, full-featured,
POSIX-compliant unix ;-)       (www.linux.org)


Usage for MEDLINE:
------------------------------------------------------------------------------
- *** NEW *** using a nice script contributed by Marko Vendelin:
  USAGE: medref <keyword1> <keyword2> ... <keywordN> >> bibfile.bib
         will connect to pubmed via the Lynx web browser (must be installed),
         run a query for all keywords (AND'ed), convert the results to
         BibTeX and append them to the BibTeX file biblio.bib
  EXAMPLE: medref Wilson 1999 >> test.bib

- by telnet (if you have a password):
  After your search is done, type: 'mail med to youraddress@yourdomain';
  After you receive the email, save it (no need to strip the header),
    for example as file 'gogo';
  type: 'med2bib gogo biblio.bib' to add the new entries to your
    BibTeX file biblio.bib

- by web: http://www4.ncbi.nlm.nih.gov/PubMed/
  After your search is done, display the results in 'MEDLINE' format;
  Save it as UNIX text to a file, named for example 'gogo';
  Be sure that there is no trash and at least one empty line between
    different bibliographic entries;
  type: 'med2bib gogo biblio.bib' to add the new entries to your
    BibTeX file biblio.bib


Usage for TOC/DOC:
------------------------------------------------------------------------------
  After your search is done, type: 'e' then '4' and then enter your
    email address
  After you receive the email, save it (no need to strip the header),
    for example as file 'gogo'
  type: 'toc2bib gogo biblio.bib' to add the new entries to your
    BibTeX file biblio.bib


Comments and bugs:
------------------------------------------------------------------------------
- both med2bib and toc2bib work fine with composite names, as far as I
    know: e.g., vanEssen_etal97;

- these programs don't deal with repeated keys in your BibTeX files
    (e.g., you have to manually create Wilson80a and Wilson80b from two
    different Wilson80 entries).  I think some tools exist to cleanup
    your BibTeX files. This is not included here for two reasons:
    1) med2bib and toc2bib don't parse your BibTeX files, they just
       append new stuff to them, so I have written no code that could
       find out what the existing entries in your bibtex file are;
    2) I am still looking for a good standard. Clearly, a,b,c,... is
       not satisfactory, as you'll never remember which one to cite.
       The best I can think of is the initials of the journal/conference:
       e.g., Geman_Geman84pami. This is far from ambiguous, and breaks 
       down if you have several papers in the same journal in the same year,
       e.g., Itti_etal97hbm (January and June...);

- both programs also accept redirections: e.g., med2bib <gogo >>biblio.bib;

- if only one argument is given, it is used as input and stdout is the
  output;

- if no argument is given, stdin is the input and stdout the output. So,
  you can use med2bib and toc2bib with pipes;

- *** NEW *** pages now reported in long format thanks to a routine
  contributed by Olav Kongas <ok@mito.physiol.med.vu.nl> <kongas@ioc.ee>

- Inconsistencies still exist concerning:
  Journal name, abbreviated in MEDLINE but not TOC/DOC, and
  Language, abbreviated in MEDLINE, but not TOC/DOC;

- *** preferably use MEDLINE *** as TOC/DOC has the following problems:
    - titles and journal names are available only in uppercase. The
      following rules try to convert them back to normal form:
          - In general, words are converted to lowercase except for
            their first letter (e.g., 'EXCELLENT' -> 'Excellent');
          - words with 3 chars or less become all-lowercase unless they
            are a single letter which is not an 'A', unless said 'A' is 
            immediately followed by a non-space
            (e.g., 'PHYSICAL REVIEW A' -> 'Physical Review A');
          - words containing non-alpha chars are always kept uppercase
            (e.g., '3D' -> '3D');
          - First letter of an entry is always capitalized
            (e.g., 'A MODEL' -> 'A Model');
          - Chemical formulas and acronyms will not be translated correctly:
            'CUSO4' -> 'CUSO4' (instead of 'CuSO4'),
            'FMRI' -> 'Fmri' (instead of 'fMRI'). Requires manual correction.
     - When journal title exceeds about 75 chars, TOC/DOC produces a bogus
          entry and the title is truncated;

- both programs generate entries that may be used for non-latex purposes:
     - the abstract (abstract = { ... }), if available;
     - a list of keywords separated by '|' (keyword = { ... });
     - for med2bib, a note (note = { ... }) that contains MEDLINE
       comments (e.g., publication of an erratum), and the language of the
       paper, if not English;
     - for toc2bib, a note that contains the language of the paper, if not
       English.
  These entries are ignored by most BibTeX styles, and will not generate bugs.
  You can use them to search/review your bibliography.

Revision history:
------------------------------------------------------------------------------

==================== Revision 1.00:  13 Mar 1998
Initial release.

==================== Revision 1.01:  06 Nov 1998
Now can handle abbreviated medline entries which don't have the
explicit journal, year, issue, etc. fields but have the abbreviated SO
field instead.  After a suggestion by Ulrich G�nther
<ugunt@bpc.uni-frankfurt.de>. The SO field will be used only if any of
the regular fields have not be found before the SO field comes up.
Multiline journal names are supported (see sample_so.med).  Note that
this creates a further inconsistency since in the SO field journal
names are not abbreviated while they are in the TA field.

Maybe I'll add a switch that lets you choose some day.  Is there any
general bibtex rule for entering both abbreviated and non-abbreviated
journal names?

==================== Revision 1.02:  22 Feb 1999
Fixed bogus parsing of month in med2bib when there is no month information
in the Medline entry. Thanks to Olav Kongas <kongas@ioc.ee>.

==================== Revision 1.03:  02 Aug 2000
Added medref script and code to convert page numbers to long form, both
thanks to Olav Kongas <kongas@ioc.ee>.

==================== Revision 1.04:  24 Oct 2003
Added support for new pubmed format where entries start with a PMID
field rather than a UI field like they used to. Contributed by 
J�r�my JUST <just@inapg.inra.fr>.
