#!/usr/bin/perl

use CGI qw(:standard escapeHTML);
use Text::BibTeX;

# this script is called when you click the "Save Changes" button on the Edit Entry page
# or the "Save Entry" button on the Add New Entry page

# copy the original bib file to BibFileOld
#    use move system command
system 'mv', 'sample.bib', 'sampleOLD.bib';

# create empty bibtex entry
$modifiedEntry = new Text::BibTeX::Entry;

# determine which parameters were sent by POST
#    are these sitting in a pre-defined array?


# fill empty bibtex entry with the new/modified data
#    use bibtex's set field function

#@fieldlist = Array of POST'ed data;
#foreach $f(@fieldlist)
#{
#$modifiedEntry->set($f, param($f)); # Syntax?
#}

# create a new bib file with the same name as the original bib file
# open old file for read $bibfile
$bibfile = new Text::BibTeX::File 'sampleOLD.bib';
# open new file for write $newbib
#system 'touch', 'sample.bib';
$newbib = new Text::BibTeX::File '>>sample.bib';

# copy all of old file, except for the modified entry, into the new file 
$found = 0;
while($entry = new Text::BibTeX::Entry $bibfile)
{
    next unless $entry->parse_ok;
    next unless $entry->metatype eq BTE_REGULAR;

    $paperID = $entry->get('paperid');
    if($paperID != param('paperID')) # not the modified entry, so just copy from old file
    {
	$entry->write ($newbib);
    }
    else # modified entry, copy from POST'ed data
    {
	$found = 1;	
	$modifiedEntry->write ($newbib);
    }
}

# if never matche the paperID, the modified entry must be a new entry
# copy the new entry to the end of the new file
if(!$found)
{
#    $modifiedEntry->write ($newbib);
}

# close opened files
$bibfile->close;
$newbib->close;
# delete old file
system 'rm', 'sampleOLD.bib';

# print message "Successfully Updated Bib Files"
# and show link to Publications page
print "Content-Type: text/html\n\n";
print "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 3.2 Final//EN\">\n"; 
print "<HTML><HEAD><TITLE>iLab Publications - University of Southern California</TITLE>\n";
print "<LINK rel=\"stylesheet\" href=\"/biblio/bibstyle.css\"><\HEAD>";
print "<BODY bgcolor=#CCF0FF>";
print "<H1>Modifying Entry</H1>";
print "<P>Successfully Updated Bib File";
print "<P><A HREF=\"http://ilab.usc.edu/publications\">Back to iLab Publications</A>";
print "</BODY></HTML>\n";
