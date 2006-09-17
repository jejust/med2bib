#!/usr/bin/perl

# edit_entry.pl
# Script is a little confusing because it can be called by add.html (to create a blank form)
# or by edit.html (to create a form with existing bibtex data as default values.)
# In each case you must treat finding paperID's differently.

use CGI qw(:standard escapeHTML);
use Text::BibTeX;

# open BibTeX file
$bibname = 'sample.bib';
$bibfile = new Text::BibTeX::File $bibname;

$found = 0;
@used_paperIDs = ();

# parse BibTeX file
while ($entry = new Text::BibTeX::Entry $bibfile) # continue to parse entire bib file 
                         # even if you find the paper, to keep track of ALL used id's
{
    next unless $entry->parse_ok;
    next unless $entry->metatype eq BTE_REGULAR;
    
    $paperID = $entry->get('paperid');


    $used_paperIDs[$paperID] = 1; # keep track of all used ID's
    # seems inefficient to create an array this big
    #  (what if there's a lot of blank space?)

	if($paperID == param('paperID')) # entry already exists, must be editing
	{
	    if($found == 1) { # entry has been found more than once!  there are duplicate paper IDs
		print "<SCRIPT TYPE=\"text/javascript\">\n";
		print "alert(\"Duplicate Paper IDs Found!\");\n";
		print "</SCRIPT>\n";
	    }
	    $found = 1;
	    $type = $entry->type;
	    # create form
	    &html_start($found);		
	    # print form based on entry type w/entry fields as default values
	    if(!&print_type_form($type, $paperID, $entry)) { # did not recognize specified type
		&print_generic_form($entry); 
	    }	    
	    print "<P><INPUT TYPE=\"submit\" VALUE=\"Save Changes\">\n";
	    print "<INPUT TYPE=\"reset\" VALUE=\"Undo All Changes\">\n";
	}
}
if(!$found) # entry does not exist, must be adding new one
{
    $newID = 0;
    $didprint = 0;
    # find an unused paperID
    $length = @used_paperIDs;
    for($j = 1; (j < $length) && (!$newID); $j++) # assuming no paperID == 0
    {
	if($used_paperIDs[$j] == 0) { $newID = $j; }
    }
    if(!$newID) # for loop didn't find any blank spots in the array
    {
	$newID = $length;
    }
    
    # create form
    &html_start($found);
    # print form based on entry type
    # can't print_generic_form because no entry to be parsed for a new entry

    # create a blank default entry
    $bibname2 = 'blank.bib'; # all blank.bib needs to contain is "@type"
                             # (doesn't even have to be a valid type)
    $bibfile2 = new Text::BibTeX::File $bibname2;
    $entry = new Text::BibTeX::Entry $bibfile2;

    if(&print_type_form(param('type'), $newID, $entry)) {
	print "<P><INPUT TYPE=\"submit\" VALUE=\"Save Entry\">\n";
	print "<INPUT TYPE=\"reset\" VALUE=\"Clear All\">\n";
    }
    else {
	print"<P>ERROR: Unknown BibTeX type specified";
	print"<BR>Should be of type Article, Book, InProceedings, etc.";
	# would never get this error if type were picked from a pull-down menu
    }   
}
&html_end;

exit(0);

sub html_start { # found
    print "Content-Type: text/html\n\n";
    print "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 3.2 Final//EN\">\n"; 
    # is above line necessary?
    print "<HTML><HEAD><TITLE>iLab Publications - University of Southern California</TITLE>\n";
    print "<LINK rel=\"stylesheet\" href=\"/biblio/bibstyle.css\"><\HEAD>";
    print "<BODY bgcolor=#CCF0FF>";
    print "<P><CENTER><IMG SRC=\"/i/ilab5.gif\"></IMG></CENTER></P>";
    print "<P><CENTER><IMG SRC=\"/i/publi1.gif\"></IMG></CENTER></P>";
    if($_[0]) { 
	print "<H1>EDIT SELECTED ENTRY</H1>\n"; 
    }
    else { 
	print "<H1>ADD NEW ENTRY</H1>\n";	
    }
    # could include banner, etc.
    print "<FORM METHOD=POST ACTION=\"/cgi-bin/biblio/modify_entry.pl\">";
    # have to specify complete path name? or is /cgi..., or just modify... enough?
    # may need seperate scripts for modify and new
}

sub html_end {
    print "</FORM></BODY></HTML>\n";
    # could include copyright
}

# simple form, prints all fields same length, one per line, with default values
# used for editing an unrecognized entry type
sub print_generic_form { # entry
    print "<BR><P>NOTE: Type specified for this entry in the BibTeX file \"$bibname\" is unrecognized by this script.\n<BR>";
    @fieldlist = $_[0]->fieldlist;
    print "<TABLE border=0 cellpadding=0 cellspacing=0>\n";
    foreach $f(@fieldlist) {
	if(!($f =~ /^paperid$/)) { # shouldn't be able to edit paperID
	    print "<TR><TD CLASS=\"opt\">$f: ";
	    print "<TD><INPUT TYPE = \"text\" NAME=\"$f\" SIZE=\"60\" VALUE=\"".$_[0]->get($f)."\"></TR>\n";
	}
    }		
    print "</TABLE>\n";
}
 
sub print_type_form { # type, paperID, entry
    $type = $_[0];
    $answer = 1; # assume we will print a form for an identified type
    #print "paper ID: <INPUT TYPE=\"text\" NAME=\"paperID\" SIZE=\"7\" VALUE=\"$_[1]\" READONLY>\n";
    # why isn't READONLY working?
    print "<P>Paper ID: $_[1]";
    print "<BR>Entry Type: $type";
    if($_[2]) { $entry = $_[2]; }
    print "<P><TABLE border=0 cellpadding=0 cellspacing=0>\n";
    if($type =~ /^[Aa]rticle$/) { &print_art($entry); }
    elsif($type =~ /^[Bb]ook$/) { &print_boo($entry); }
    elsif($type =~ /^[Bb]ooklet$/) { &print_let($entry); }
    elsif($type =~ /^[Ii]n[Bb]ook$/) { &print_inb($entry); }
    elsif($type =~ /^[Ii]n[Cc]ollection$/) { &print_inc($entry); }
    elsif($type =~ /^[Ii]n[Pp]roceedings$/) { &print_inp($entry); }
    elsif($type =~ /^[Mm]anual$/) { &print_man($entry); }
    elsif($type =~ /^[Mm]aster[Tt]hesis$/) { &print_mas($entry); }
    elsif($type =~ /^[Mm]isc$/) { &print_mis($entry); }
    elsif($type =~ /^[Pp]atent$/) { &print_pat($entry); }
    elsif($type =~ /^[Pp]h[Dd][Tt]hesis$/) { &print_phd($entry); }
    elsif($type =~ /^[Pp]roceedings$/) { &print_pro($entry); }
    elsif($type =~ /^[Tt]ech[Rr]eport$/) { &print_tec($entry); }
    elsif($type =~ /^[Uu]n[Pp]ublished$/) { &print_unp($entry); }
    else { $answer = 0; } # did not print a form
    if($answer) {
	print "</TR></TABLE>\n"; # close table that started above function
	# color code
	print "<P><TABLE border=0 cellpadding=0 cellspacing=0>\n";
	print "<TR>".&cell("*Red = Required field",req)."\n";
	print "<TR>".&cell("*Blue = Exactly one",exact)."\n";
	print "<TR>".&cell("*Green = At least one",atlst)."\n";
	print "<TR>".&cell("*Black = Optional field",opt)."\n";
	print "<TR>".&cell("*Orange = At most one",atmst)."\n";
	print "</TR></TABLE>\n";
    }
    else { print "</TR></TABLE>\n"; } # close table that started above function 
    return $answer;
}

sub print_art { # entry
    $e = $_[0];
    # required fields
    print "<TR>".&author($e,req,100,11).""; # Should any other types use the (mulitiple) author field?
    print "<TR>".&field("title",$e,req,100,11)."";
    print "<TR>".&field("journal",$e,req,23)." ".&field("year",$e,req,5)." ";
    # optional fields
    print "".&field("month",$e,opt,10)."".&field("volume",$e,opt,4)." ";
    print "".&field("number",$e,opt,5)." ".&field("pages",$e,opt,9)."";
    print "<TR>".&abstract($e,opt,98,11).""; # (non-standard)
    # should Abstract be included for any types other than article?
    # optional fields for all types (not standard BibTeX)
    print "<TR>".&field("note",$e,opt,35,3)."".&field("keyword",$e,opt,54,7)."";
    print "<TR>".&field("theme",$e,opt,35,3)."".&field("url",$e,opt,54,7)."";
}

sub print_boo { # entry
    $e = $_[0];
    # required fields
    print "<TR>".&field("author",$e,exact,100,11).""; #exactly1
    print "<TR>".&field("title",$e,req,100,11)."";
    print "<TR>".&field("editor",($e),exact,35,4).""; #exactly1
    print "".&field("publisher",($e),req,53,6)."";
    print "<TR>".&field("year",($e),req,5)."";
    # optional fields
    print "".&field("month",($e),opt,10)."";
    print "".&field("volume",($e),atmst,4)."".&field("number",($e),atmst,5).""; #atmost1
    print "".&field("edition",($e),opt,10)."".&field("series",($e),opt,9)."";
    print "<TR>".&field("address",($e),opt,100,11)."";
    # optional fields for all types (not standard BibTeX)
    print "<TR>".&field("note",($e),opt,35,4)."".&field("keyword",($e),opt,53,7)."";
    print "<TR>".&field("theme",($e),opt,35,4)."".&field("url",($e),opt,53,7)."";
}

sub print_let { # entry
    $e = $_[0];
    # required fields
    print "<TR>".&field("title",($e),req,100,6)."";
    # optional
    print "<TR>".&field("author",($e),opt,100,6)."";
    print "<TR>".&field("year",($e),opt,5)."".&field("month",($e),opt,10)."".&field("howpublished",($e),opt,57,2)."";
    print "<TR>".&field("address",($e),opt,100,6)."";
    # optional fields for all types (not standard BibTeX)
    print "<TR>".&field("note",$e,opt,40,4)."".&field("keyword",$e,opt,49)."";
    print "<TR>".&field("theme",$e,opt,40,4)."".&field("url",$e,opt,49)."";
}

sub print_inb { # entry
    $e = $_[0];
    # required
    print "<TR>".&field("author",($e),exact,100,11).""; #exactly1
    print "<TR>".&field("title",($e),req,100,11)."";
    print "<TR>".&field("editor",($e),exact,33,3).""; #exactly1
    print "".&field("publisher",($e),req,53,5)."";
    print "<TR>".&field("year",($e),req,5)."";
    #optional
    print "".&field("month",($e),opt,10)."";
    print "".&field("type",($e),opt,27,3)."".&field("edition",($e),opt,8)."";
    print "<TR>".&field("volume",($e),atmst,5)."".&field("number",($e),atmst,10).""; #atmost1
    print "".&field("chapter",($e),atlst,5)."".&field("pages",($e),atlst,8).""; #atleast1
    print "".&field("series",($e),opt,8)."";
    print "<TR>".&field("address",($e),opt,100,11)."";
    # optional fields for all types (not standard BibTeX)
    print "<TR>".&field("note",$e,opt,33,3)."".&field("keyword",$e,opt,53,5)."";
    print "<TR>".&field("theme",$e,opt,33,3)."".&field("url",$e,opt,53,5)."";
}

sub print_inc { # entry
    $e = $_[0];
    # required
    print "<TR>".&field("author",($e),req,100,7).""; 
    print "<TR>".&field("title",($e),req,100,7)."";
    print "<TR>".&field("booktitle",($e),req,58,3).""; # what's the difference?
    print "".&field("year",($e),req,5)."";
    # optional
    print "".&field("month",($e),opt,8)."";
    print "<TR>".&field("editor",($e),opt,35)."".&field("edition",($e),opt,5)."";
    print "".&field("volume",($e),atmst,5)."".&field("number",($e),atmst,8).""; #atmost1
    print "<TR>".&field("type",($e),opt,35)."".&field("series",($e),opt,5)."";
    print "".&field("chapter",($e),opt,5)." ".&field("pages",($e),opt,8)."";
    print "<TR>".&field("address",($e),opt,100,7)."";
    # optional fields for all types (not standard BibTeX)
    print "<TR>".&field("keyword",$e,opt,58,3)."".&field("note",$e,opt,29,3)."";
    print "<TR>".&field("url",$e,opt,58,3)."".&field("theme",$e,opt,29,3)."";
}

sub print_inp { # entry
    $e = $_[0];
    # required
    print "<TR>".&field("author",($e),req,100,11)."";
    print "<TR>".&field("title",($e),req,100,11)."";
    print "<TR>".&field("booktitle",($e),req,40,5).""; # what's the difference?
    # optional
    print "".&field("editor",($e),opt,45,5)."";
    print "<TR>".&field("publisher",($e),opt,40,5)."".&field("organization",($e),opt,45,5)."";
    print "<TR>".&field("year",($e),req,5).""; # required
    print "".&field("month",($e),opt,10)."";
    print "".&field("volume",($e),atmst,5)."".&field("number",($e),atmst,10).""; #atmost1
    print "".&field("series",($e),opt,10)."".&field("pages",($e),opt,10)."";
    print "<TR>".&field("address",($e),opt,100,11)."";
    # optional fields for all types (not standard BibTeX)
    print "<TR>".&field("note",$e,opt,40,5)."".&field("keyword",$e,opt,45,5)."";
    print "<TR>".&field("theme",$e,opt,40,5)."".&field("url",$e,opt,45,5)."";
}

sub print_man { # entry
    $e = $_[0];
    # required
    print "<TR>".&field("title",($e),req,100,7)."";
    # optional
    print "<TR>".&field("author",($e),opt,100,7)."";
    print "<TR>".&field("organization",($e),opt,35)." ".&field("edition",($e),opt,20)." ".&field("year",($e),opt,6)." ".&field("month",($e),opt,11)."";
    print "<TR>".&field("address",($e),opt,100,7)."";
    # optional fields for all types (not standard BibTeX)
    print "<TR>".&field("note",$e,opt,35)."".&field("keyword",$e,opt,56,5)."";
    print "<TR>".&field("theme",$e,opt,35)."".&field("url",$e,opt,56,5)."";
}

sub print_mas { # entry
    $e = $_[0];
    # required
    print "<TR>".&field("author",($e),req,100,5)."";
    print "<TR>".&field("title",($e),req,100,5)."";
    print "<TR>".&field("school",($e),req,100,5)."";
    print "<TR>".&field("year",($e),req,10)."";
    # optional
    print " ".&field("month",($e),opt,12)." ".&field("type",($e),opt,54)."";
    print "<TR>".&field("address",($e),opt,100,5)."";     
    # optional fields for all types (not standard BibTeX)
    print "<TR>".&field("note",$e,opt,35,3)."".&field("keyword",$e,opt,54)."";
    print "<TR>".&field("theme",$e,opt,35,3)."".&field("url",$e,opt,54)."";
}

sub print_mis { # entry
    $e = $_[0];
    #(none required)
    # optional
    print "<TR>".&field("author",($e),opt,100,5)."";
    print "<TR>".&field("title",($e),opt,100,5)."";
    print "<TR>".&field("year",($e),opt,10)."".&field("month",($e),opt,12)."".&field("howpublished",($e),opt,54)."";
    # optional fields for all types (not standard BibTeX)
    print "<TR>".&field("note",$e,opt,31,3)."".&field("keyword",$e,opt,54)."";
    print "<TR>".&field("theme",$e,opt,31,3)."".&field("url",$e,opt,54)."";
}

sub print_pat { # entry
    $e = $_[0];
    # required
    print "<TR>".&author($e,req,100,5)."";
    print "<TR>".&field("title",$e,req,100,5)."";
    print "<TR>".&field("year",$e,req,6,1)."";
    # optional
    print " ".&field("month",$e,opt,20,1)."".&field("organization",$e,opt,51,1).""; 
    # optional fields for all types (not standard BibTeX)
    print "<TR>".&field("theme",$e,opt,35,3)."".&field("url",$e,opt,51,1)."";
    print "<TR>".&field("note",$e,opt,35,3)."".&field("keyword",$e,opt,51,1)."";
}

sub print_phd { # entry
    $e = $_[0];
    # required
    print "<TR>".&field("author",($e),req,100,5)."";
    print "<TR>".&field("title",($e),req,100,5)."";
    print "<TR>".&field("school",($e),req,100,5)."";
    print "<TR>".&field("year",($e),req,10)."";
    # optional
    print " ".&field("month",($e),opt,12)." ".&field("type",($e),opt,54)."";
    print "<TR>".&field("address",($e),opt,100,5)."";
    # optional fields for all types (not standard BibTeX)
    print "<TR>".&field("note",$e,opt,35,3)."".&field("keyword",$e,opt,54)."";
    print "<TR>".&field("theme",$e,opt,35,3)."".&field("url",$e,opt,54)."";
}

sub print_pro { # entry
    $e = $_[0];
    # required
    print "<TR>".&field("title",($e),req,100,7)."";
    print "<TR>".&field("year",($e),req,10)."";
    # optional
    print " ".&field("month",($e),opt,12)."";
    print " ".&field("volume",($e),atmst,10)."".&field("number",($e),atmst,15).""; #atmost1
    print "<TR>".&field("series",($e),opt,10)."".&field("edition",($e),opt,12)."".&field("publisher",($e),opt,46,3)."";
    print "<TR>".&field("organization",($e),opt,100,7)."";
    print "<TR>".&field("address",($e),opt,100,7)."";
    # optional fields for all types (not standard BibTeX)
    print "<TR>".&field("note",$e,opt,35,3)."".&field("keyword",$e,opt,46,3)."";
    print "<TR>".&field("theme",$e,opt,35,3)."".&field("url",$e,opt,46,3)."";
}

sub print_tec { # entry
    $e = $_[0];
    # required
    print "<TR>".&field("author",($e),req,100,7)."";
    print "<TR>".&field("title",($e),req,100,7)."";
    print "<TR>".&field("institution",($e),req,100,7)."";
    print "<TR>".&field("year",($e),req,10)."";
    # optional
    print "".&field("month",($e),opt,12)."";
    print "".&field("type",($e),opt,30)."".&field("number",($e),opt,15)."";
    print "<TR>".&field("address",($e),opt,100,7)."";
    # optional fields for all types (not standard BibTeX)
    print "<TR>".&field("note",$e,opt,35,3)."".&field("keyword",$e,opt,54,3)."";
    print "<TR>".&field("theme",$e,opt,35,3)."".&field("url",$e,opt,54,3)."";
}
    
sub print_unp { # entry
    $e = $_[0];
    # required
    print "<TR>".&field("author",($e),req,100,6)."";
    print "<TR>".&field("title",($e),req,45,2)."";
    # "Note" below is also a required field
    # optional
    print "".&field("year",$e,opt,12)."".&field("month",$e,opt,12)."";
    # optional fields for all types (not standard BibTeX)
    print "<TR>".&field("note",$e,req,35)."".&field("keyword",$e,opt,45,4)."";
    print "<TR>".&field("theme",$e,opt,35)."".&field("url",$e,opt,45,4)."";
}

# routines for printing fields, with default values if entry exists
# used above to make the entry printing routines easier to read
sub abstract { # entry, style, input field width, colspan for input cell
    return ("".&cell("abstract ", $_[1])."".&cell("<TEXTAREA NAME=\"abstract\" ROWS=6 COLS=$_[2] WRAP>".$_[0]->get('abstract')."</TEXTAREA>", $_[1], $_[3])."");
}

sub author { # entry, style, input field width, colspan for input cell
    return ("".&cell("author(s) ", $_[1])."".&cell("<INPUT TYPE=\"text\" NAME=\"author\" 
SIZE=$_[2] VALUE=\"".join(', ', $_[0]->split('author'))."\">", $_[1], $_[3])."");
}

# all other fields are formatted same way
sub field { # field type, entry, style, input width, colspan for input
    return ("".&cell($_[0], $_[2])."".&cell("<INPUT TYPE=\"text\" NAME=$_[0] SIZE=$_[3] VALUE=\"".$_[1]->get($_[0])."\">", $_[2], $_[4])."");
}

sub cell { # text, style, colspan
       if ( ($_[1]) && ($_[2]) ) { return ("<TD CLASS=$_[1] COLSPAN=$_[2]> $_[0] </TD>"); }
       elsif ($_[1]) { return ("<TD CLASS=$_[1] COLSPAN=1> $_[0] </TD>"); }
       else { return ("<TD> $_[0] </TD>"); }
}

sub row { return ("<TR>$_[0]</TR>"); }
