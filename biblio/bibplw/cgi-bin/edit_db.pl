#!/usr/bin/perl

# edit_db.pl
# Script is a little confusing because it can be called by add.html (to create a blank form)
# or by search.pl (to create a form with existing bibtex data as default values.)
# In each case you must treat finding paperID's and the "type" variable/parameter differently.

use CGI qw(:standard escapeHTML);
use Pg;

# setup variables for html output
$style = "/biblio/bibstyle.css"; # URL of a style sheet to be included
$picdir = "/i";        # URL of where the images and icons are
$title = "iLab Publications - University of Southern California";
$bgcol = "#CCF0FF"; # color for page background
$bannerPic = $picdir."/ilab5.gif"; # a banner at top of page (or comment out)
$titlePic = $picdir."/publi1.gif"; # a title just below banner (or comment out)

$HTMLhead = "<HTML><HEAD><LINK rel=\"stylesheet\" href=\"$style\">".
    "<TITLE>$title</TITLE><META HTTP-EQUIV=\"Pragma\" CONTENT=\"no-cache\">";
$HTMLstart = "</HEAD><BODY BGCOLOR=\"$bgcol\">\n";
if ($bannerPic) {
    $HTMLstart .= "<P><CENTER><IMG SRC=\"$bannerPic\"></IMG></CENTER></P>\n";
}
if ($titlePic) {
    $HTMLstart .= "<P><CENTER><IMG SRC=\"$titlePic\"></IMG></CENTER></P>\n";
}
$HTMLend = "</BODY></HTML>\n"; # could include copyright or footer

print header();
print $HTMLhead;
print "<script language=\"javascript\">\n";
print "function editFileID(input) {\n";
print " var oldID = input.value;\n";
print " var okay = confirm('Do not change the FileID unless you are sure you need to do so.  FileID must be unique.');\n";
print "	if(okay) {\n";
print "   var newID = prompt(\"New File ID\", oldID);\n";
print "   if(newID != null) {\n";
print "	   input.value = newID;\n";
print "   }\n";
print "  alert('The display will not change, but when you click \"Save Changes\" the new File ID will be stored.');";
#print " fid.document.open(); fid.document.write(\"Something Worked\"); fid.document.close();";
#print " fid.innerHTML = \"Something Worked!\";";
print " }\n}\n</script>";
print $HTMLstart;

# connect to postgresql database named biblio
$conn = Pg::connectdb("dbname=\"biblio\"");
if ($conn->status ne PGRES_CONNECTION_OK)
{ print "<p>ERROR CONNECTING TO DATABASE: ".$conn->errorMessage; goto done; }

# get existing paper ID from search.pl or new entry type from add.html
$paperID = param("fileID");
$entrytype = param("entrytype");

$exists = 0;
if($paperID != 0) {
    # query db
    $query = "SELECT * FROM master WHERE file=$paperID;";
    $result = $conn->exec($query);
    if ($result->resultStatus ne PGRES_TUPLES_OK)
    { print "<p>ERROR IN QUERY: ".$conn->errorMessage; goto done; }

    # should only get 1 result, if any
    while(@row = $result->fetchrow) {
	$exists = 1;
	# create hash containing all data for found entry
	$entry{"key"} = $row[0]; #key
	$et = $row[1]; #entrytype (Article, etc)
	$entry{"authors"} = $row[2]; #authors
	$entry{"title"} = $row[3]; #title
	$entry{"journal"} = $row[4]; #journal
	$entry{"volume"} = $row[5]; #volume
	$entry{"number"} = $row[6]; #number
	$entry{"pages"} = $row[7]; #pages
	$entry{"month"} = $row[8]; #month
	$entry{"year"} = $row[9]; #year
	$entry{"booktitle"} = $row[10]; #booktitle
	$entry{"editor"} = $row[11]; #editors
	$entry{"organization"} = $row[12]; #organization
	$entry{"publisher"} = $row[13]; #publisher
	$entry{"address"} = $row[14]; #address
	$entry{"keywords"} = $row[15]; #keywords
	$entry{"abstract"} = $row[16]; #abstract
	$entry{"other_type"} = $row[17]; #type
	$entry{"pdf"} = $row[18]; #pdf file
	$entry{"file"} = $row[19]; #file number
	$entry{"url"} = $row[20]; #html url
	$entry{"note"} = $row[21]; #notes
	$entry{"date"} = $row[22]; #date entered
	
	$entry{"entrytype"} = &decode_entrytype($et);
    }
}

if($exists) { # modifying existing entry
    print "<H1>EDIT SELECTED ENTRY</H1>\n";

    # print form based on entry type w/entry fields as default values
    #print "<P id=\"fid\">File ID: $paperID</P>\n";
    print "<FORM METHOD=\"POST\" ACTION=\"modify_existing.pl\">";
    print "<INPUT TYPE=\"hidden\" name=\"key\" value=\"".$entry{"key"}."\">";
    if(!&print_type_form($entry{"entrytype"}, $paperID)) { # did not recognize specified type
	&print_generic_form($paperID); 
    }	    
    print "<P><INPUT TYPE=\"submit\" VALUE=\"Save Changes\">\n";
    print "<INPUT TYPE=\"reset\" VALUE=\"Undo All Changes\">\n";
    print "</FORM>\n";
}
else { # adding new entry
    print "<H1>ADD NEW ENTRY</H1>\n";

    # We will give new paper a number >= 10000
    # first, figure out the max file number:
    $result = $conn->exec("SELECT max(file) FROM master;");
    if ($result->resultStatus ne PGRES_TUPLES_OK)
    { print "<p>$conn->errorMessage"; goto done; }
    @row = $result->fetchrow; 
    $number = $row[0];
    if ($number < 10000) { $number = 10000; }
    $number ++;

    # print form based on entry type
    # can't print_generic_form because no entry to be parsed for a new entry
    print "<FORM METHOD=\"POST\" ACTION=\"create_new.pl\">";
    if(&print_type_form($entrytype, $number)) {
	print "<P><INPUT TYPE=\"submit\" VALUE=\"Save Entry\">\n";
	print "<INPUT TYPE=\"reset\" VALUE=\"Clear All\">\n";
    }
    else {
	print"<P>ERROR: Unknown BibTeX type specified";
	print"<BR>Should be of type Article, Book, InProceedings, etc.";
	# will never get this error if type is picked from a menu
    }
    print "</FORM>\n";
}

print $HTMLend;
exit(0);

#==========================================
# decode entrytype from integer to string
sub decode_entrytype { # et (int 1-14)
    my $et = $_[0];
    my $entry;
    if($et == 1) { $entry = "Article"; }
    elsif($et == 2) { $entry = "Book"; }
    elsif($et == 3) { $entry = "Booklet"; }
    elsif($et == 4) { $entry = "InBook"; }
    elsif($et == 5) { $entry = "InCollection"; }
    elsif($et == 6) { $entry = "InProceedings"; }
    elsif($et == 7) { $entry = "Manual"; }
    elsif($et == 8) { $entry = "MastersThesis"; }
    elsif($et == 9) { $entry = "Misc"; }
    elsif($et == 10) { $entry = "PhDThesis"; }
    elsif($et == 11) { $entry = "Proceedings"; }
    elsif($et == 12) { $entry = "TechReport"; }
    elsif($et == 13) { $entry = "UnPublished"; }
    elsif($et == 14) { $entry = "Patent"; }
    else { $entry = "Unknown"; }
    return $entry;
}

# encode entrytype from string to integer
sub encode_entrytype { # type (string)
    my $entrytype = $_[0];
    my $typecode = 0;
    if($entrytype =~ /^[Aa]rticle$/) { $typecode = 1; }
    elsif($entrytype =~ /^[Bb]ook$/) { $typecode = 2; }
    elsif($entrytype =~ /^[Bb]ooklet$/) { $typecode = 3; }
    elsif($entrytype =~ /^[Ii]n[Bb]ook$/) { $typecode = 4; }
    elsif($entrytype =~ /^[Ii]n[Cc]ollection$/) { $typecode = 5; }
    elsif($entrytype =~ /^[Ii]n[Pp]roceedings$/) { $typecode = 6; }
    elsif($entrytype =~ /^[Mm]anual$/) { $typecode = 7; }
    elsif($entrytype =~ /^[Mm]asters[Tt]hesis$/) { $typecode = 8; }
    elsif($entrytype =~ /^[Mm]isc$/) { $typecode = 9; }
    elsif($entrytype =~ /^[Pp]h[Dd][Tt]hesis$/) { $typecode = 10; }
    elsif($entrytype =~ /^[Pp]roceedings$/) { $typecode = 11; }
    elsif($entrytype =~ /^[Tt]ech[Rr]eport$/) { $typecode = 12; }
    elsif($entrytype =~ /^[Uu]n[Pp]ublished$/) { $typecode = 13; }
    elsif($entrytype =~ /^[Pp]atent$/) { $typecode = 14; }
    return $typecode;
}

# simple form, prints all fields same length, one per line, with default values
# used for editing an unrecognized entry type
sub print_generic_form { #paperID
    my $fileID = $_[0];
    print "<BR><P>NOTE: Type specified for this entry in the Biblio Master Database file is unrecognized by this script.\n<BR>";
    # print hash keys and values
    print "<TABLE border=0 cellpadding=0 cellspacing=0>\n";
    print "<TR><TD CLASS=\"req\">File ID: <TD>$fileID\n";
    print "<INPUT TYPE=\"hidden\" name=\"file\" value=\"$fileID\">";
    foreach $k(keys(%entry)) {
	if(!($k =~ /file/)) { # don't allow direct editing of paperID
	    print "<TR><TD CLASS=\"opt\">$k: ";
	    print "<TD><INPUT TYPE=\"text\" NAME=\"$k\" SIZE=\"60\" VALUE=\"".$entry{$k}."\"></TR>\n";
	}
    }
    print "</TABLE>\n";
}
 
sub print_type_form { # type, paperID
    my $type = $_[0];
    $answer = 1; # assume default that we will print a form for an identified type
    my $fileID = $_[1];
    print "<TABLE border=0 cellpadding=0 cellspacing=0>\n";
    # Didn't want to put fileID or entrytype in editable input fields (and READONLY attribute
    # is not very well-supported) but still want to pass the data along after other fields are 
    # modified, so include them as hidden fields
    print "<TR><TD CLASS=\"req\">File ID: </TD><TD>$fileID</TD>\n";
    print "<TD><INPUT TYPE=\"hidden\" name=\"file\" value=\"$fileID\">";
    print "<INPUT TYPE=\"button\" VALUE=\"Edit File ID\" NAME=\"EditID\" onClick=\"editFileID(this.form.file)\"></TD></TR>";
    print "<TR><TD CLASS=\"req\">Entry Type: <TD>$type\n";
    # modify_existing.pl and create_new.pl expect entrytype as an integer
    my $entrytype = &encode_entrytype($type);
    print "<INPUT TYPE=\"hidden\" name=\"entrytype\" value=\"$entrytype\">";
    print "</TABLE>";
    print "<P><TABLE border=0 cellpadding=0 cellspacing=0>\n";
    if($type =~ /^[Aa]rticle$/) { &print_art(); }
    elsif($type =~ /^[Bb]ook$/) { &print_boo(); }
    elsif($type =~ /^[Bb]ooklet$/) { &print_let(); }
    elsif($type =~ /^[Ii]n[Bb]ook$/) { &print_inb(); }
    elsif($type =~ /^[Ii]n[Cc]ollection$/) { &print_inc(); }
    elsif($type =~ /^[Ii]n[Pp]roceedings$/) { &print_inp(); }
    elsif($type =~ /^[Mm]anual$/) { &print_man(); }
    elsif($type =~ /^[Mm]aster[Tt]hesis$/) { &print_mas(); }
    elsif($type =~ /^[Mm]isc$/) { &print_mis(); }
    elsif($type =~ /^[Pp]atent$/) { &print_pat(); }
    elsif($type =~ /^[Pp]h[Dd][Tt]hesis$/) { &print_phd(); }
    elsif($type =~ /^[Pp]roceedings$/) { &print_pro(); }
    elsif($type =~ /^[Tt]ech[Rr]eport$/) { &print_tec(); }
    elsif($type =~ /^[Uu]n[Pp]ublished$/) { &print_unp(); }
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

sub print_art { 
    # required fields
    print "<TR>".&author(req,100,11).""; # Should any other types use the (mulitiple) author field?
    print "<TR>".&field("title",req,100,11)."";
    print "<TR>".&field("journal",req,23)." ".&field("year",req,5)." ";
    # optional fields
    print "".&field("month",opt,10)."".&field("volume",opt,4)." ";
    print "".&field("number",opt,5)." ".&field("pages",opt,9)."";
    print "<TR>".&abstract(opt,98,11).""; # (non-standard)
    # should Abstract be included for any types other than article?
    # optional fields for all types (not standard BibTeX)
    print "<TR>".&field("note",opt,35,3)."".&field("keywords",opt,54,7)."";
    print "<TR>".&field("pdf",opt,35,3)."".&field("url",opt,54,7)."";
}

sub print_boo {
    # required fields
    print "<TR>".&field("author",exact,100,7).""; #exactly1
    print "<TR>".&field("title",req,100,7)."";
    print "<TR>".&field("editor",exact,35,3).""; #exactly1
    print "".&field("publisher",req,53,3)."";
    print "<TR>".&field("year",req,5)."";
    # optional fields
    print "".&field("month",opt,10)."";
    print "".&field("volume",atmst,4)."".&field("number",atmst,5).""; #atmost1
    #print "".&field("edition",opt,10)."".&field("series",opt,9)."";
    print "<TR>".&field("address",opt,100,7)."";
    # optional fields for all types (not standard BibTeX)
    print "<TR>".&field("note",opt,35,3)."".&field("keywords",opt,53,3)."";
    print "<TR>".&field("pdf",opt,35,3)."".&field("url",opt,53,3)."";
}

sub print_let {
    # required fields
    print "<TR>".&field("title",req,100,6)."";
    # optional
    print "<TR>".&field("author",opt,100,6)."";
    print "<TR>".&field("year",opt,5)."".&field("month",opt,10)."";#.&field("howpublished",opt,57,2)."";
    print "<TR>".&field("address",opt,100,6)."";
    # optional fields for all types (not standard BibTeX)
    print "<TR>".&field("note",opt,40,4)."".&field("keywords",opt,49)."";
    print "<TR>".&field("pdf",opt,40,4)."".&field("url",opt,49)."";
}

sub print_inb { 
    # required
    print "<TR>".&field("author",exact,100,11).""; #exactly1
    print "<TR>".&field("title",req,100,11)."";
    print "<TR>".&field("editor",exact,33,3).""; #exactly1
    print "".&field("publisher",req,53,5)."";
    print "<TR>".&field("year",req,5)."";
    #optional
    print "".&field("month",opt,10)."";
    print "".&field("type",opt,27,3)."";#.&field("edition",opt,8)."";
    print "<TR>".&field("volume",atmst,5)."".&field("number",atmst,10).""; #atmost1
    #print "".&field("chapter",atlst,5)."";
    print "".&field("pages",atlst,8).""; #atleast1
    #print "".&field("series",opt,8)."";
    print "<TR>".&field("address",opt,100,11)."";
    # optional fields for all types (not standard BibTeX)
    print "<TR>".&field("note",opt,33,3)."".&field("keywords",opt,53,5)."";
    print "<TR>".&field("pdf",opt,33,3)."".&field("url",opt,53,5)."";
}

sub print_inc {
    # required
    print "<TR>".&field("author",req,100,7).""; 
    print "<TR>".&field("title",req,100,7)."";
    print "<TR>".&field("booktitle",req,58,3).""; # what's the difference?
    print "".&field("year",req,5)."";
    # optional
    print "".&field("month",opt,8)."";
    print "<TR>".&field("editor",opt,35)."";#.&field("edition",opt,5)."";
    print "".&field("volume",atmst,5)."".&field("number",atmst,8).""; #atmost1
    print "<TR>".&field("type",opt,35)."";#.&field("series",opt,5)."";
    #print "".&field("chapter",opt,5).;
    print " ".&field("pages",opt,8)."";
    print "<TR>".&field("address",opt,100,7)."";
    # optional fields for all types (not standard BibTeX)
    print "<TR>".&field("keywords",opt,58,3)."".&field("note",opt,29,3)."";
    print "<TR>".&field("url",opt,58,3)."".&field("pdf",opt,29,3)."";
}

sub print_inp {
    # required
    print "<TR>".&field("author",req,100,11)."";
    print "<TR>".&field("title",req,100,11)."";
    print "<TR>".&field("booktitle",req,40,5).""; # what's the difference?
    # optional
    print "".&field("editor",opt,45,5)."";
    print "<TR>".&field("publisher",opt,40,5)."".&field("organization",opt,45,5)."";
    print "<TR>".&field("year",req,5).""; # required
    print "".&field("month",opt,10)."";
    print "".&field("volume",atmst,5)."".&field("number",atmst,10).""; #atmost1
    #print "".&field("series",opt,10).;
    print "".&field("pages",opt,10)."";
    print "<TR>".&field("address",opt,100,11)."";
    # optional fields for all types (not standard BibTeX)
    print "<TR>".&field("note",opt,40,5)."".&field("keywords",opt,45,5)."";
    print "<TR>".&field("pdf",opt,40,5)."".&field("url",opt,45,5)."";
}

sub print_man {
    # required
    print "<TR>".&field("title",req,100,7)."";
    # optional
    print "<TR>".&field("author",opt,100,7)."";
    print "<TR>".&field("organization",opt,35)." ";#.&field("edition",opt,20)." "
    print "".&field("year",opt,6)." ".&field("month",opt,11)."";
    print "<TR>".&field("address",opt,100,7)."";
    # optional fields for all types (not standard BibTeX)
    print "<TR>".&field("note",opt,35)."".&field("keywords",opt,56,5)."";
    print "<TR>".&field("pdf",opt,35)."".&field("url",opt,56,5)."";
}

sub print_mas {
    # required
    print "<TR>".&field("author",req,100,5)."";
    print "<TR>".&field("title",req,100,5)."";
    print "<TR>".&field("organization",req,100,5).""; # use organization for school
    print "<TR>".&field("year",req,10)."";
    # optional
    print " ".&field("month",opt,12)." ".&field("type",opt,54)."";
    print "<TR>".&field("address",opt,100,5)."";     
    # optional fields for all types (not standard BibTeX)
    print "<TR>".&field("note",opt,35,3)."".&field("keywords",opt,54)."";
    print "<TR>".&field("pdf",opt,35,3)."".&field("url",opt,54)."";
}

sub print_mis {
    #(none required)
    # optional
    print "<TR>".&field("author",opt,100,5)."";
    print "<TR>".&field("title",opt,100,5)."";
    print "<TR>".&field("year",opt,10)."".&field("month",opt,12)."";#.&field("howpublished",opt,54)."";
    # optional fields for all types (not standard BibTeX)
    print "<TR>".&field("note",opt,31,3)."".&field("keywords",opt,54)."";
    print "<TR>".&field("pdf",opt,31,3)."".&field("url",opt,54)."";
}

sub print_pat {
    # required
    print "<TR>".&author(req,100,5)."";
    print "<TR>".&field("title",req,100,5)."";
    print "<TR>".&field("year",req,6,1)."";
    # optional
    print " ".&field("month",opt,20,1)."".&field("organization",opt,51,1).""; 
    # optional fields for all types (not standard BibTeX)
    print "<TR>".&field("pdf",opt,35,3)."".&field("url",opt,51,1)."";
    print "<TR>".&field("note",opt,35,3)."".&field("keywords",opt,51,1)."";
}

sub print_phd {
    # required
    print "<TR>".&field("author",req,100,5)."";
    print "<TR>".&field("title",req,100,5)."";
    print "<TR>".&field("organization",req,100,5).""; # use organization for school
    print "<TR>".&field("year",req,10)."";
    # optional
    print " ".&field("month",opt,12)." ".&field("type",opt,54)."";
    print "<TR>".&field("address",opt,100,5)."";
    # optional fields for all types (not standard BibTeX)
    print "<TR>".&field("note",opt,35,3)."".&field("keywords",opt,54)."";
    print "<TR>".&field("pdf",opt,35,3)."".&field("url",opt,54)."";
}

sub print_pro {
    # required
    print "<TR>".&field("title",req,100,7)."";
    print "<TR>".&field("year",req,10)."";
    # optional
    print " ".&field("month",opt,12)."";
    print " ".&field("volume",atmst,10)."".&field("number",atmst,15).""; #atmost1
    print "<TR>";#.&field("series",opt,10)."".&field("edition",opt,12).;
    print "".&field("publisher",opt,46,3)."";
    print "<TR>".&field("organization",opt,100,7)."";
    print "<TR>".&field("address",opt,100,7)."";
    # optional fields for all types (not standard BibTeX)
    print "<TR>".&field("keywords",opt,46,3)."".&field("note",opt,35,3)."";
    print "<TR>".&field("url",opt,46,3)."".&field("pdf",opt,35,3)."";
}

sub print_tec {
    # required
    print "<TR>".&field("author",req,100,7)."";
    print "<TR>".&field("title",req,100,7)."";
    print "<TR>".&field("organization",req,100,7).""; # use organization for institution
    print "<TR>".&field("year",req,10)."";
    # optional
    print "".&field("month",opt,12)."";
    print "".&field("type",opt,30)."".&field("number",opt,15)."";
    print "<TR>".&field("address",opt,100,7)."";
    # optional fields for all types (not standard BibTeX)
    print "<TR>".&field("note",opt,35,3)."".&field("keywords",opt,54,3)."";
    print "<TR>".&field("pdf",opt,35,3)."".&field("url",opt,54,3)."";
}
    
sub print_unp {
    # required
    print "<TR>".&field("author",req,100,6)."";
    print "<TR>".&field("title",req,45,2)."";
    # "Note" below is also a required field
    # optional
    print "".&field("year",opt,12)."".&field("month",opt,12)."";
    # optional fields for all types (not standard BibTeX)
    print "<TR>".&field("note",req,35)."".&field("keywords",opt,45,4)."";
    print "<TR>".&field("pdf",opt,35)."".&field("url",opt,45,4)."";
}

# routines for printing fields, with default values if entry exists
# used above to make the entry printing routines easier to read
sub abstract { # style, input field width, colspan for input cell
    return ("".&cell("abstract ", $_[0])."".&cell("<TEXTAREA NAME=\"abstract\" ROWS=6 COLS=$_[1] WRAP>".$entry{"abstract"}."</TEXTAREA>", $_[0], $_[2])."");
}

sub author { # style, input field width, colspan for input cell
    return ("".&cell("author(s) ", $_[0])."".&cell("<INPUT TYPE=\"text\" NAME=\"author\" 
SIZE=$_[1] VALUE=\"".$entry{"authors"}."\">", $_[0], $_[2])."");
}

# all other fields are formatted same way
sub field { # field type, style, input width, colspan for input
    return ("".&cell($_[0], $_[1])."".&cell("<INPUT TYPE=\"text\" NAME=$_[0] SIZE=$_[2] VALUE=\"".$entry{$_[0]}."\">", $_[1], $_[3])."");
}

sub cell { # text, style, colspan
       if ( ($_[1]) && ($_[2]) ) { return ("<TD CLASS=$_[1] COLSPAN=$_[2]> $_[0] </TD>"); }
       elsif ($_[1]) { return ("<TD CLASS=$_[1] COLSPAN=1> $_[0] </TD>"); }
       else { return ("<TD> $_[0] </TD>"); }
}

sub row { return ("<TR>$_[0]</TR>"); }

done:
print $HTMLend;
exit(1);
