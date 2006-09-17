#!/usr/bin/perl

# File search.pl
# Called by search.html
# Uses form data to search database of publications.  Displays info for all
# publications that match the search criteria, including links to any available
# html or pdf versions.  Also creates online abstracts (when available) and 
# links to them.
# Formatting for output borrows heavily from bibTOhtml

use Pg; # postgresql
use CGI qw(:standard escapeHTML);

# connect to database biblio
$conn = Pg::connectdb("dbname=\"biblio\"");
if ($conn->status ne PGRES_CONNECTION_OK)
{ print "ERROR CONNECTING TO DATABASE: ".$conn->errorMessage; goto done; }

# pull data from user's search fields
$choice = param("choice");

$author = param("author");
$title = param("title");
$year = param("year");
$abstract = param("abstract");
$keyword = param("keyword");
$aut_rad = param("aut_radio");
$tit_rad = param("tit_radio");
$yea_rad = param("yea_radio");
$abs_rad = param("abs_radio");
$key_rad = param("key_radio");

# form database query from user's data
$query = "SELECT * FROM master WHERE ";
if($author) {
    if($aut_rad eq "exact") {
	$query .= "author~*'$author'"; }
    else {
	if($aut_rad eq "any") {
	    $conjunc = "OR"; }
	if($aut_rad eq "all") {
	    $conjunc = "AND"; }
	$author_query = join("' $conjunc author~*'", split(/ /,$author));
	$query .= "(author~*'$author_query')";
    }
}
if($title) {
    if($author) {
	$query .= " $choice ";
    }
    if($tit_rad eq "exact") {
	$query .= "title~*'$title'"; }
    else {
	if($tit_rad eq "any") {
	    $conjunc = "OR"; }
	if($tit_rad eq "all") {
	    $conjunc = "AND"; }
	$title_query = join("' $conjunc title~*'", split(/ /,$title));
	$query .= "(title~*'$title_query')";
    }
}
if($year) {
    if($author || $title) {
	$query .= " $choice ";
    }
    if($yea_rad eq "exact") {
	$query .= "year~*'$year'"; }
    else {
	if($yea_rad eq "any") {
	    $conjunc = "OR"; }
	if($yea_rad eq "all") {
	    $conjunc = "AND"; }
	$year_query = join("' $conjunc year~*'", split(/ /,$year));
	$query .= "(year~*'$year_query')";
    }
}
if($abstract) {
    if($author || $title || $year) {
	$query .= " $choice ";
    }
    if($abs_rad eq "exact") {
	$query .= "abstract~*'$abstract'"; }
    else {
	if($abs_rad eq "any") {
	    $conjunc = "OR"; }
	if($abs_rad eq "all") {
	    $conjunc = "AND"; }
	$abstract_query = join("' $conjunc abstract~*'", split(/ /,$abstract));
	$query .= "(abstract~*'$abstract_query')";
    }
}
if($keyword) {
    if($author || $title || $year || $abstract) {
	$query .= " $choice ";
    }
    if($key_rad eq "exact") {
	$query .= "keyword~*'$keyword'"; }
    else {
	if($key_rad eq "any") {
	    $conjunc = "OR"; }
	if($key_rad eq "all") {
	    $conjunc = "AND"; }
	$keyword_query = join("' $conjunc keyword~*'", split(/ /,$keyword));
	$query .= "(keyword~*'$keyword_query')";
    }
}
$query .= ";";

# query the database
$result = $conn->exec($query);
if ($result->resultStatus ne PGRES_TUPLES_OK)
{ print "ERROR IN QUERY: ".$conn->errorMessage; goto done; }

# Most of the following code pulled from bibTOhtml
# Setup variables to use in HTML output
$style = "/style.css"; # URL of a style sheet to be included
$picdir = "/i";        # URL of where the images and icons are
$verbose = 0;          # show file open/close info during parsing
$destdir = '/home/httpd/html/biblio'; # PATH where to write HTML

##### You Lab's Information & your Copyright:
$title = "iLab Publications - University of Southern California";

##### Colors:
$bgcol = "#CCF0FF"; # color for page background
$idcol = 'purple';  # color for file id number
$ticol = 'navy';    # color for titles
$jocol = 'red';     # color for journal names
$dacol = '#EE6600'; # color for year
$xxcol = 'blue';    # for the words: Abstract, Note, Keywords

##### Images and Icons:
$bannerPic = $picdir."/ilab5.gif"; # a banner at top of page (or comment out)
$titlePic = $picdir."/publi1.gif"; # a title just below banner (or comment out)
$ICONpdf = $picdir."/ICONpdf.gif";
$ICONhtml = $picdir."/ICONhtml.gif";
$ICONabs = $picdir."/ICONabs.gif";
$ICONblank = $picdir."/ICONblank.gif";
$ICONbib = $picdir."/ICONbib.gif";

$HTMLstart = "<HTML><HEAD><LINK rel=\"stylesheet\" href=\"$style\">".
    "<TITLE>$title</TITLE><META HTTP-EQUIV=\"Pragma\" CONTENT=\"no-cache\">".
	"</HEAD><BODY BGCOLOR=\"$bgcol\">\n";
if ($bannerPic) {
    $HTMLstart .= "<P><CENTER><IMG SRC=\"$bannerPic\"></IMG></CENTER></P>\n";
}
if ($titlePic) {
    $HTMLstart .= "<P><CENTER><IMG SRC=\"$titlePic\"></IMG></CENTER></P>\n";
}

$HTMLend = "<P> &nbsp; </P><CENTER><P class=\"sm\">$copy</P></CENTER></BODY></HTML>\n";

$HTMLicons = "<HR><CENTER><P class=\"desc\"><IMG SRC=\"$ICONhtml\" ".
    "BORDER=0></IMG> = HTML Version, &nbsp; &nbsp; <IMG ".
    "SRC=\"$ICONpdf\" BORDER=0></IMG> = PDF Version, &nbsp; &nbsp; <IMG ".
    "<IMG SRC=\"$ICONabs\" BORDER=0></IMG> = Online ".
    "Abstract</CENTER></P>".
    #"<CENTER><P class=\"BIBkw\">NOTE: The pdf ".
    #"files are compressed with gzip, which will confuse older ".
    #"browsers. If they appear corrupted, <A HREF=\"doc/problem.html\">".
    #"see here.</A></P></CENTER>".
    "<HR>";

# output search results
print header();
print $HTMLstart;
print $HTMLicons;
print "<h1>Search Results</h1>";
print "<p><i>To edit an entry, enter its File ID in the field at the bottom of this page.</i></p>";

while(@row = $result->fetchrow) {
    #### parse row:
    $key = $row[0]; #key
    $type = $row[1]; #entrytype
    $au = $row[2]; #authors
    $ti = $row[3]; #title
    $jo = $row[4]; #journal
    $vo = $row[5]; #volume
    $nu = $row[6]; #number
    $pp = $row[7]; #pages
    $mo = $row[8]; #month
    $ye = $row[9]; #year
    $bt = $row[10]; #booktitle
    $ed = $row[11]; #editors
    $or = $row[12]; #organization
    $pu = $row[13]; #publisher
    $ad = $row[14]; #address
    $kk = $row[15]; #keywords
    $abs = $row[16]; #abstract
    $ty = $row[17]; #type
    $pdf = $row[18]; #pdf file
    $fi = $row[19]; #file number
    $url = $row[20]; #html url
    $nt = $row[21]; #notes
    $da = $row[22]; #date entered

    #print STDERR "$key, $jo$bt, $ye [$type]\n";
    print STDERR "$key [$type]\n";
    ##### format and colorize the various fields:
    if ($key) { $key =~ s/\s+$//; } # drop trailing spaces
    if ($fi) { $fi = "<FONT COLOR=\"$idcol\">File #$fi: </FONT> "; }
    if ($au) { $au = "$au, "; }
    if ($ti) { $ti = "<FONT COLOR=\"$ticol\">$ti,</FONT> "; } 
    if ($jo) { $jo = "<FONT COLOR=\"$jocol\"><I>$jo,</I></FONT> ";}
    if ($vo) { $vo = "Vol. <B>$vo</B>, "; }
    if ($nu) { $nu = "No. $nu, "; }
    if ($ye) { 
	$dat = "<FONT COLOR=\"$dacol\">";
	if($mo) {
	    $mo = conv_month($mo);
	    $dat .= "$mo ";
	}
	$dat .= "$ye.</FONT>";
    }
    if ($pp) { $pp = "p. $pp, "; if ($pp =~ "-") { $pp = "p$pp"; } }
    if ($pu) { $pu = "$pu, "; }
    if ($bt) { $bt = "<FONT COLOR=\"$jocol\"><B>In: </B><I>$bt,</I></FONT> "; }
    if ($ed) { $ed = " ($ed <B>Ed.</B>), "; }
    if ($ad && $pu) { $ad = "$ad:$pu"; $pu = ""; } else { $ad = ""; }
    if ($or) { $or = "$or, "; }

    ##### Build html representation of entry:
    $ref = "$fi$au$ti$jo$bt$ed$vo$nu$or$pp$pu$ad$dat";

    ##### if we have an HTML version, add it:
    if ($url) {
	$txt = icon($ICONhtml, $url);
    } else {
	$txt = icon($ICONblank);
    }

    ##### if we have a PDF version, add it:
    if ($pdf) {
	$txt .= icon($ICONpdf, $pdf);
    } else {
	$txt .= icon($ICONblank);
    }

    ##### if we have an abstract, add a link and create a page with it:
    if ($abs) {
	$fname = "$key.html"; 
	$txt .= icon($ICONabs, "/biblio/abstracts/$fname");
	$abs =~ s/\\+//g;  # cleanup bogus \'s that remain...
	if ($kk) {
	    $kw = "<P class=\"BIBkw\"><FONT COLOR=\"$xxcol\"><B>Keywords:".
		" </B></FONT>".join("; ", split(/\|/, $kk))."</P>\n";
	} else { $kw = ""; }
	if ($nt) {
	    $note = "<P class=\"BIBkw\"><FONT COLOR=\"$xxcol\"><B>Note: </B>".
		"</FONT>".$nt."</P>\n";
	} else { $note = ""; }
	openout($key);
	out($key, "<P class=\"BIBent\">$txt $ref</P>\n<P class=\"BIBabs\">".
	    "<FONT COLOR=\"$xxcol\"><B>Abstract: </B></FONT> $abs</P>\n".
	    "$kw$note");
	# close this one right away so that we don't have too many open files
	closeout($key);
    } else {
	$txt .= icon($ICONblank);
    }
    print "<p>$txt $ref</p>";
}

print "<h1>Edit an Entry</h1>";
print "<form method=\"get\" action=\"edit_db.pl\">";
print "<p>File ID: <input type=\"text\" name=\"fileID\" size=\"8\">";
print "<input type=\"hidden\" name=\"entrytype\" value=\"unknown\">";
print "<input type=\"submit\" value=\"Edit Entry\"></form>";
print $HTMLend;
closeouts();

##############################################################################
##############################################################################
sub conv_month { # month as an integer
# check for 0 < month < 13 before calling conv_month()    
    $m = $_[0];
    if($m == 1) { $mo = "Jan"; }
    elsif($m == 2) { $mo = "Feb"; }
    elsif($m == 3) { $mo = "Mar"; }
    elsif($m == 4) { $mo = "Apr"; }
    elsif($m == 5) { $mo = "May"; }
    elsif($m == 6) { $mo = "Jun"; }
    elsif($m == 7) { $mo = "Jul"; }
    elsif($m == 8) { $mo = "Aug"; }
    elsif($m == 9) { $mo = "Sep"; }
    elsif($m == 10) { $mo = "Oct"; }
    elsif($m == 11) { $mo = "Nov"; }
    elsif($m == 12) { $mo = "Dec"; }
    else { $mo = "XXX"; }
    return $mo;
}

##############################################################################
sub openout {  # name
    my $k = $_[0];
    local *FH; 
    open FH, ">$destdir/abstracts/$k.html" || die "Cannot write $k.html: ";
    if ($verbose) { print STDERR "##### Creating $k.html\n"; }
    $out{$k} = *FH; 
    print FH $HTMLstart;
    print FH "<H1>Abstract</H1>\n";
    print FH "$HTMLicons\n";
}

##############################################################################
sub out {
    my ($k, $txt) = @_;
    if (! defined($out{$k})) { openout($k); }
    local *F = $out{$k}; 
    print F $txt;
}

##############################################################################
sub closeouts {
    foreach $k (keys %out) {
	local *FH = $out{$k};
	print FH "\n$HTMLend\n";
	if ($verbose) { print STDERR "##### Closing $k.html\n"; }
	close FH;
    }
}

##############################################################################
sub closeout {
    if ($out{$_[0]}) {
	local *FH = $out{$_[0]};
	print FH "\n$HTMLend\n";
	if ($verbose) { print STDERR "##### Closing $_[0].html\n"; }
	close FH; 
	delete $out{$_[0]};
    }
}

##############################################################################
sub icon {
    if ($_[1]) {
	return "<A HREF=\"$_[1]\"><IMG SRC=\"$_[0]\" BORDER=0></IMG></A> ";
    } else {
	return "<IMG SRC=\"$_[0]\" BORDER=0></IMG> ";
    }
}
 done:
