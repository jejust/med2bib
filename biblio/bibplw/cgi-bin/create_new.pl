#!/usr/bin/perl

# create_new.pl
# Called by edit_db.pl
# Inserts data entered by user into postgresql biblio db

use CGI qw(:standard escapeHTML);
use Pg;
require 'ctime.pl'; # for recording current date

# setup variables for html output
$style = "/biblio/bibstyle.css"; # URL of a style sheet to be included
$picdir = "/i";        # URL of where the images and icons are
$title = "iLab Publications - University of Southern California";
$bgcol = "#CCF0FF"; # color for page background
$bannerPic = $picdir."/ilab5.gif"; # a banner at top of page (or comment out)
$titlePic = $picdir."/publi1.gif"; # a title just below banner (or comment out)

$HTMLstart = "<HTML><HEAD><LINK rel=\"stylesheet\" href=\"$style\">".
    "<TITLE>$title</TITLE><META HTTP-EQUIV=\"Pragma\" CONTENT=\"no-cache\">".
	"</HEAD><BODY BGCOLOR=\"$bgcol\">\n";
if ($bannerPic) {
    $HTMLstart .= "<P><CENTER><IMG SRC=\"$bannerPic\"></IMG></CENTER></P>\n";
}
if ($titlePic) {
    $HTMLstart .= "<P><CENTER><IMG SRC=\"$titlePic\"></IMG></CENTER></P>\n";
}
$HTMLend = "</BODY></HTML>\n"; # could include copyright or footer

$entrytype = param("entrytype");
$author = param("author");
$year = param("year");
$file = param("fileID");

$entry{"title"} = param("title");
$entry{"journal"} = param("journal");
$entry{"volume"} = param("volume");
$entry{"number"} = param("number");
$entry{"pages"} = param("pages");
$entry{"month"} = param("month");
$entry{"booktitle"} = param("booktitle");
$entry{"editor"} = param("editor");
$entry{"organization"} = param("organization");
$entry{"publisher"} = param("publisher");
$entry{"address"} = param("address");
$entry{"keywords"} = param("keywords");
$entry{"abstract"} = param("abstract");
$entry{"type"} = param("type");# when is type (not entrytype) used?
$entry{"pdf"} = param("pdf");
$entry{"url"} = param("url");
$entry{"note"} = param("note");

# create a key for the new entry
@authors = split(/ and /, $author);
@names0 = split(/,/, $authors[0]);
$key = $names0[0];
if($authors[2]) { $key .= "etal"; }
elsif($authors[1]) {
    @names1 = split(/,/, $authors[1]);
    $key .= $names1[0];
}
$yearkey = $year;
if($year > 1900) { $yearkey = substr($yearkey,-2); }
$key .= $yearkey;

# record date this entry is added to DB
$date = &ctime(time); # today's date, ie Mon Oct  8 11:44:51 2001
                      # pgsql automatically converts to yyyy-mm-dd
$date = substr($date,0,24);

$conn = Pg::connectdb("dbname=\"biblio\"");
if ($conn->status ne PGRES_CONNECTION_OK)
{ print "ERROR CONNECTING TO DATABASE: ".$conn->errorMessage; goto done; }

$notdone = 26;
while($notdone) {
# create SQL command string
    # add required fields
    $fields .= "key, entrytype, author, year, file, date";
    $values .= "'$key', $entrytype, '$author', $year, $file, $date"; 
    # add other existing fields
    foreach $f (keys %entry) {
	$v = $entry{$f};
	if($v) {
	    $fields .= ", $f";
	    $values .= ", '$v'";
	}
    }    
    $insert = "INSERT INTO master ($fields) VALUES ($values);";

# update db
    $result = $conn->exec($insert);
# make sure inserted correctly
    if ($result->resultStatus ne PGRES_COMMAND_OK) {
	print "INSERT failed! for $key\n";
	print "  ". $conn->errorMessage;
	
	# check whether the existing entry in the
	# database matches the one we are trying to insert...
	# we already know that first 2 authors & year match; let's
	# just do an additional test on page numbers:
	$res2 = $conn->exec("select pages from master where key='$key';");
	
	if ($res2->resultStatus ne PGRES_TUPLES_OK)
	{ print $conn->errorMessage; $notdone = 0; goto done; }
	$notfound = 1; $pp = $entry{"pages"}; $pp =~ s/\s+//g;
	while (@row2 = $res2->fetchrow) {
	    $p = $row2[0]; $p =~ s/\s+//g;
	    if ($p eq $pp) {
		$notfound = 0;
		print "  OK, already in database.\n";
	    }
	}
	if ($notfound) {
	    # add a 'a' or other letter at the end of the key:
	    if (substr($key, -1, 1) =~ /[0-9]/) {
		$key .= 'a';
	    } else { substr($key, -1, 1) ++; }
	    print "  retrying as $key...\n";
	    $notdone --;
	} else { $notdone = 0; }
    }
    else {
	print "INSERTed " . $key . ".\n"; $notdone=0; 
	print header(); print $HTMLstart;
	print "<p>Publications Database was successfully updated";
	print "<A HREF=\"/biblio/search.html\">Return to Publication Search</A>";
	print $HTMLend;
    }
}

done:
