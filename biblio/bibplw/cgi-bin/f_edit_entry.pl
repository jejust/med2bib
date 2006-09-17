#!/usr/bin/perl

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
    # seems inefficient to create an array that big
    #  (what if there's a lot of blank space?)

	if($paperID == param('paperID')) # entry already exists, must be editing
	{
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
    $bibname2 = 'blank.bib';
    $bibfile2 = new Text::BibTeX::File $bibname2;
    $entry = new Text::BibTeX::Entry $bibfile2;

    if(&print_type_form(param('type'), $newID, $entry)) {
	print "<P><INPUT TYPE=\"submit\" VALUE=\"Save Entry\">\n";
	print "<INPUT TYPE=\"reset\" VALUE=\"Clear All\">\n";
    }
    else {
	print"<P>ERROR: Unknown BibTeX type specified";
	print"<BR>Should be of type Article, Book, InProceedings, etc.";
	# should never get this error because type is picked from a pull-down menu
    }
}
&html_end;

exit(0);

sub html_start { # found
    print "Content-Type: text/html\n\n";
    print "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 3.2 Final//EN\">\n"; 
    # is above line necessary? what does it do?
    if($_[0]) { 
	print "<HTML><HEAD><TITLE>Edit Entry</TITLE>\n";
	print "<LINK rel=\"stylesheet\" href=\"/biblio/bibstyle.css\"><\HEAD>";
	print "<BODY bgcolor=#CCF0FF><H1>EDIT SELECTED ENTRY</H1>\n"; 
    }
    else { 
	print "<HTML><HEAD><TITLE>Add New Entry</TITLE>\n";
	print "<LINK rel=\"stylesheet\" href=\"/biblio/bibstyle.css\"><\HEAD>";
	print "<BODY bgcolor=#CCF0FF><H1>ADD NEW ENTRY</H1>\n";	
    }
    # could include banner, etc.
    print "<FORM METHOD=POST ACTION=\"/cgi-bin/biblio/modify_entry\">";
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
    print "<BR>NOTE: Type specified for this entry in the BibTeX file \"$bibname\" is unrecognized by this script.\n<BR>";
    @fieldlist = $_[0]->fieldlist;
    foreach $f(@fieldlist) {
	if(!($f =~ /^paperid$/)) { # shouldn't be able to edit paperID
	    print "<BR>$f: <INPUT TYPE = \"text\" NAME=\"$f\" SIZE=\"60\" VALUE=\"".$_[0]->get($f)."\">\n";
	}
    }		
}
 
sub print_type_form { # type, paperID, entry
    $type = $_[0];
    $note = 0; 
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
    elsif($type =~ /^[Uu]n[Pp]ublished$/) { 
	&print_unp($entry); 
	$note = 1; # special case: Unpublished is only type where "note" is required
    }
    else { $answer = 0; } # did not print a form
    if($answer) {
	# optional fields for all types (not standard BibTeX)
	if ($note) {
	    print "<TR>".&cell(&note($e),req,47)."";
	}
	else {
	    print "<TR>".&cell(&note($e),opt,47)."";
	}
	print "".&cell(&keyword($e),opt,56)."";
	print "<TR>".&cell(&theme($e),opt,18)."".&cell(&url($e),opt,86)."";
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
    # use cell, row, etc

    # required fields
    print "<TR>".&cell(&author($e),req,92)."";
    print "<TR>".&cell(&title($e),req,108)."";
    print "<TR>".&cell(&journal($e),req,30)." ".&cell(&year($e),req,12)." ";
    # optional fields
    print "".&cell(&month($e),opt,18)."".&cell(&volume($e),opt,13)." ";
    print "".&cell(&number($e),opt,15)." ".&cell(&pages($e),opt,18)."";
    print "<TR>".&cell(&abstract($e),opt,106).""; # (non-standard)
    # should Abstract be included for any types other than article?
}

sub print_boo { # entry
    $e = $_[0];
    # required fields
    print "<TR>".&cell(&author($e),exact,92).""; #exactly1
    print "<TR>".&cell(&title($e),req,108)."";
    print "<TR>".&cell(&editor($e),exact,49).""; #exactly1
    print "".&cell(&publisher($e),req,72)."";
    print "<TR>".&cell(&year($e),req,12)."";
    # optional fields
    print " ".&cell(&month($e),opt,18)."";
    print " ".&cell(&volume($e),atmst,13).""&cell(&number($e),atmst,15).""; #atmost1
    print " ".&cell(&edition($e),opt,15)." ".&cell(&series($e),opt,14)."";
    print "<TR>".&cell(&address($e),opt,110)."";
}

sub print_let { # entry
    $e = $_[0];
    # required fields
    print "<TR>".&cell(&title($e),req,108)."";
    # optional
    print "<TR>".&cell(&author($e),opt,92)."";
    print "<TR>".&cell(&year($e),opt,12)." ".&cell(&month($e),opt,18)." ".&cell(&howpublished($e),opt,56)."";
    print "<TR>".&cell(&address($e),opt,110)."";
}

sub print_phd { # entry
    $e = $_[0];
    # required
    print "<TR>".&cell(&author($e),req,92)."";
    print "<TR>".&cell(&title($e),req,108)."";
    print "<TR>".&cell(&school($e),req,89)."";
    print "<TR>".&cell(&year($e),req,12)."";
    # optional
    print " ".&cell(&month($e),opt,18)." ".&cell(&type($e),opt,27)."";
    print "<TR>".&cell(&address($e),opt,110)."";
}

sub print_inb { # entry
    $e = $_[0];
    # required
    print "<TR>".&cell(&author($e),exact,92).""; #exactly1
    print "<TR>".&cell(&title($e),req,108)."";
    print "<TR>".&cell(&editor($e),exact,49).""; #exactly1
    print " ".&cell(&publisher($e),req,72)."";
    print "<TR>".&cell(&chapter($e),atlst,13)." ".&cell(&pages($e),atlst,18).""; #atleast1
    print " ".&cell(&year($e),req,12)."";
    # optional
    print " ".&cell(&month($e),opt,18)."";    
    print " ".&cell(&volume($e),atmst,13)." ".&cell(&number($e),atmst,15).""; #atmost1
    print "<TR>".&cell(&edition($e),opt,15)." ".&cell(&series($e),opt,14)." ".&cell(&type($e),opt,27)."";
    print "<TR>".&cell(&address($e),opt,110)."";
}

sub print_inc { # entry
    $e = $_[0];
    # required
    print "<TR>".&cell(&author($e),req,92)."";
    print "<TR>".&cell(&title($e),req,108)."";
    print "<TR>".&cell(&booktitle($e),req,53).""; # what's the difference?
    print " ".&cell(&year($e),req,12)."";
    # optional
    print " ".&cell(&month($e),opt,18)."";
    print "<TR>".&cell(&editor($e),opt,49)."";
    print " ".&cell(&volume($e),atmst,13)." ".&cell(&number($e),atmst,15).""; #atmost1
    print "<TR>".&cell(&edition($e),opt,15)." ".&cell(&series($e),opt,14)." ";
    print "".&cell(&type($e),opt,27)." ".&cell(&chapter($e),opt,13)." ".&cell(&pages($e),opt,18)."";
    print "<TR>".&cell(&address($e),opt,110)."";
}

sub print_inp { # entry
    $e = $_[0];
    # required
    print "<TR>".&cell(&author($e),req,92)."";
    print "<TR>".&cell(&title($e),req,108)."";
    print "<TR>".&cell(&booktitle($e),req,53).""; # what's the difference?
    print " ".&cell(&year($e),req,12)."";
    # optional
    print " ".&cell(&month($e),opt,18)."";
    print "<TR>".&cell(&editor($e),opt,49)."";
    print " ".&cell(&volume($e),atmst,13)." ".&cell(&number($e),atmst,15).""; #atmost1
    print " ".&cell(&series($e),opt,14)." ".&cell(&pages($e),opt,18)."";
    print "<TR>".&cell(&organization($e),opt,55)." ".&cell(&publisher($e),opt,72)."";
    print "<TR>".&cell(&address($e),opt,110)."";
}

sub print_man { # entry
    $e = $_[0];
    # required
    print "<TR>".&cell(&title($e),req,108)."";
    # optional
    print "<TR>".&cell(&author($e),opt,92)."";
    print "<TR>".&cell(&organization($e),opt,55)." ".&cell(&edition($e),opt,15)." ".&cell(&year($e),opt,12)." ".&cell(&month($e),opt,18)."";
    print "<TR>".&cell(&address($e),opt,110)."";
}

sub print_mas { # entry
    $e = $_[0];
    # required
    print "<TR>".&cell(&author($e),req,92)."";
    print "<TR>".&cell(&title($e),req,108)."";
    print "<TR>".&cell(&school($e),req,89)."";
    print "<TR>".&cell(&year($e),req,12)."";
    # optional
    print " ".&cell(&month($e),opt,18)." ".&cell(&type($e),opt,27)."";
    print "<TR>".&cell(&address($e),opt,110)."";     
}

sub print_mis { # entry
    $e = $_[0];
    #(none required)
    # optional
    print "<TR>".&cell(&author($e),opt,92)."";
    print "<TR>".&cell(&title($e),opt,108)."";
    print "<TR>".&cell(&howpublished($e),opt,56)." ".&cell(&year($e),opt,12)." ".&cell(&month($e),opt,18)."";
}

sub print_pro { # entry
    $e = $_[0];
    # required
    print "<TR>".&cell(&title($e),req,108)."";
    print "<TR>".&cell(&year($e),req,12)."";
    # optional
    print " ".&cell(&month($e),opt,18)."";
    print " ".&cell(&volume($e),atmst,13)." ".&cell(&number($e),atmst,15).""; #atmost1
    print "<TR>".&cell(&publisher($e),opt,72)." ".&cell(&series($e),opt,14)." ".&cell(&edition($e),opt,15)."";
    print "<TR>".&cell(&organization($e),opt,55)."";
    print "<TR>".&cell(&address($e),opt,110)."";
}

sub print_tec { # entry
    $e = $_[0];
    # required
    print "<TR>".&cell(&author($e),req,92)."";
    print "<TR>".&cell(&title($e),req,108)."";
    print "<TR>".&cell(&institution($e),req,54)."";
    print " ".&cell(&year($e),req,12)."";
    # optional
    print " ".&cell(&month($e),opt,18)."";
    print "<TR>".&cell(&type($e),opt,27)." ".&cell(&number($e),opt,15)."";
    print "<TR>".&cell(&address($e),opt,110)."";
}
    
sub print_unp { # entry
    $e = $_[0];
    # required
    print "<TR>".&cell(&author($e),req,92)."";
    print "<TR>".&cell(&title($e),req,108)."";
    # "Note" below is also a required field
    # optional
    print "<TR>".&cell(&year,opt,12)." ".&cell(&month,opt,12)."";
}

sub print_pat { # entry
    $e = $_[0];
    # required
    print "<TR>".&cell(&author($e),req,92)."";
    print "<TR>".&cell(&title($e),req,108)."";
    print "<TR>".&cell(&year($e),req,12)."";
    # optional
    print " ".&cell(&month($e),opt,18)." ".&cell(&organization($e),opt,55)."";  
}

# routines for printing fields, with default values if they exist
# used above to make the entry printing routines easier to read
# the main difference for each routine below is the SIZE used
sub abstract { return("Abstract: <TEXTAREA NAME=\"abstract\" 
ROWS=\"6\" COLS=\"95\" WRAP>".$_[0]->get('abstract')."</TEXTAREA>\n");}
# will saving from a Textarea work the same as saving from an Input box?
sub address { return("Address: <INPUT TYPE=\"text\" NAME=\"address\" SIZE=\"
100\" VALUE=\"".$_[0]->get('address')."\">\n");}
sub author { return("Author(s): <INPUT TYPE=\"text\" NAME=\"author\" SIZE=\"
80\" VALUE=\"".join(', ', $_[0]->split('author'))."\">\n"); }
sub booktitle { return("Book Title: <INPUT TYPE=\"text\" NAME=\"booktitle\" SIZE=\"
40\" VALUE=\"".$_[0]->get('booktitle')."\">\n");}
sub chapter { return("Chapter: <INPUT TYPE=\"text\" NAME=\"chapter\" SIZE=\"
3\" VALUE=\"".$_[0]->get('chapter')."\">\n");}
sub edition { return("Edition: <INPUT TYPE=\"text\" NAME=\"edition\" SIZE=\"
5\" VALUE=\"".$_[0]->get('edition')."\">\n");}
sub editor { return("Editor: <INPUT TYPE=\"text\" NAME=\"editor\" SIZE=\"
40\" VALUE=\"".$_[0]->get('editor')."\">\n");}
sub howpublished { return("How Published: <INPUT TYPE=\"text\" NAME=\"howpublished\" SIZE=\"
40\" VALUE=\"".$_[0]->get('howpublished')."\">\n");}
sub institution { return("Institution: <INPUT TYPE=\"text\" NAME=\"institution\" SIZE=\"
40\" VALUE=\"".$_[0]->get('institution')."\">"); }
sub journal { return("Journal: <INPUT TYPE=\"text\" NAME=\"journal\" SIZE=\"
20\" VALUE=\"".$_[0]->get('journal')."\">"); }
sub keyword { return("Keywords: <INPUT TYPE=\"text\" NAME=\"keyword\" SIZE=\"
45\" VALUE=\"".$_[0]->get('keyword')."\">\n"); }
sub month { return("Month: <INPUT TYPE=\"text\" NAME=\"month\" SIZE=\"
10\" VALUE=\"".$_[0]->get('month')."\">\n"); }
sub number { return("Number: <INPUT TYPE=\"text\" NAME=\"number\" SIZE=\"
6\" VALUE=\"".$_[0]->get('number')."\">\n"); }
sub note { return("Note: <INPUT TYPE=\"text\" NAME=\"note\" SIZE=\"
40\" VALUE=\"".$_[0]->get('note')."\">\n"); }
sub organization { return("Organization: <INPUT TYPE=\"text\" NAME=\"organization\" SIZE=\"
40\" VALUE=\"".$_[0]->get('organization')."\">\n");}
sub pages { return("Pages: <INPUT TYPE=\"text\" NAME=\"pages\" SIZE=\"
10\" VALUE=\"".$_[0]->get('pages')."\">\n"); }
sub pdfurl { return("PDF URL: <INPUT TYPE=\"text\" NAME=\"pdfurl\" SIZE=\"
80\" VALUE=\"".$_[0]->get('pdfurl')."\">\n");}
sub publisher { return("Publisher: <INPUT TYPE=\"text\" NAME=\"publisher\" SIZE=\"
60\" VALUE=\"".$_[0]->get('publisher')."\">\n");}
sub school { return("School: <INPUT TYPE=\"text\" NAME=\"school\" SIZE=\"
80\" VALUE=\"".$_[0]->get('school')."\">\n");}
sub series { return("Series: <INPUT TYPE=\"text\" NAME=\"series\" SIZE=\"
5\" VALUE=\"".$_[0]->get('series')."\">\n");}
sub theme { return("Theme: <INPUT TYPE=\"text\" NAME=\"theme\" SIZE=\"
10\" VALUE=\"".$_[0]->get('theme')."\">\n");}
sub title { return("Title: <INPUT TYPE=\"text\" NAME=\"title\" SIZE=\"
100\" VALUE=\"".$_[0]->get('title')."\">\n"); }
sub type { return("Type: <INPUT TYPE=\"text\" NAME=\"type\" SIZE=\"
20\" VALUE=\"".$_[0]->get('type')."\">\n");}
sub url { return("URL: <INPUT TYPE=\"text\" NAME=\"url\" SIZE=\"
80\" VALUE=\"".$_[0]->get('url')."\">\n");}
sub volume { return("Volume: <INPUT TYPE=\"text\" NAME=\"volume\" SIZE=\"
4\" VALUE=\"".$_[0]->get('volume')."\">\n"); }
sub year { return("Year: <INPUT TYPE=\"text\" NAME=\"year\" SIZE=\"
5\" VALUE=\"".$_[0]->get('year')."\">\n"); }

sub cell { # text, style, colspan
       if ( ($_[1]) && ($_[2]) ) {
	   return ("<TD CLASS=$_[1] COLSPAN=$_[2]> $_[0] </TD>");
       }
       elsif ($_[1]) { 
	   return ("<TD CLASS=$_[1]> $_[0] </TD>"); 
       }
       else { 
	   return ("<TD> $_[0] </TD>"); 
       }
}

sub row {
	return ("<TR>$_[0]</TR>");
}
