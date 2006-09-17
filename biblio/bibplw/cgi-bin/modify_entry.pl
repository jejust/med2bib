#!/usr/bin/perl

use CGI qw(:standard escapeHTML);
use Text::BibTeX;

# this script is called when you click the "Save Changes" button on the Edit Entry page
# or the "Save Entry" button on the Add New Entry page

# copy the original bib file to BibFileOld
#    use move system command
system 'mv', 'sample.bib', 'sampleOLD.bib';

# create empty bibtex entry
$modifiedEntry = new Text::BibTeX:Entry;

# determine which parameters were sent by POST
#    are these sitting in a pre-defined array?

# fill empty bibtex entry with the new/modified data
#    use bibtex's set field function


# create a new bib file with the same name as the original bib file
# open old file for read $bibfile
# open new file for write $newbib

# copy all of old file, except for the modified entry, into the new file 
# copy the new entry to the end of the new file
#
# print message "Successfully Updated Bib Files"
# show link to Publications page
