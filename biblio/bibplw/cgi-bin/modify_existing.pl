#!/usr/bin/perl

# modify_existing.pl
# Called by edit_db.pl
# Updates postgresql biblio db with data entered by user to modify an existing
# publication entry.

use CGI qw(:standard escapeHTML);
use Pg;
require 'ctime.pl'; # for recording current date

$key = param("key");
$entrytype = param("entrytype");
$author = param("author");
$title = param("title");
$journal = param("journal");
$volume = param("volume");
$number = param("number");
$pages = param("pages");
$month = param("month");
$year = param("year");
$booktitle = param("booktitle");
$editor = param("editor");
$organization = param("organization");
$publisher = param("publisher");
$address = param("address");
$keywords = param("keywords");
$abstract = param("abstract");
$type = param("type");# when is type used? (not entrytype)
$pdf = param("pdf");
$file = param("fileID");
$url = param("url");
$note = param("note");

# record date this entry is added to DB
$date = &ctime(time); # today's date, ie Mon Oct  8 11:44:51 2001
                      # pgsql automatically converts to yyyy-mm-dd
$date = substr($date,0,24);

$update = "UPDATE master SET ";
if($key) { $update .= "key = '$key', "; }
if($entrytype) { $update .= "entrytype = $entrytype, "; }
if($author) { $update .= "author = '$author', "; }
if($title) { $update .= "title = '$title', "; }
if($journal) { $update .= "journal = '$journal', "; }
if($volume) { $update .= "volume = '$volume', "; }
if($number) { $update .= "number = '$number', "; }
if($pages) { $update .= "pages = '$pages', "; }
if($month) { $update .= "month = $month, "; }
if($year) { $update .= "year = $year, "; }
if($booktitle) { $update .= "booktitle = '$booktitle', "; }
if($editor) { $update .= "editor = '$editor', "; }
if($organization) { $update .= "organization = '$organization', "; }
if($publisher) { $update .= "publisher = '$publisher', "; }
if($address) { $update .= "address = '$address', "; }
if($keywords) { $update .= "keywords = '$keywords', "; }
if($abstract) { $update .= "abstract = '$abstract', "; }
if($type) { $update .= "type = '$type', "; }
if($pdf) { $update .= "pdf = '$pdf', "; }
if($file) { $update .= "file = $file, "; }
if($url) { $update .= "url = '$url', "; }
if($note) { $update .= "note = '$note', "; }
$update .= "date = '$date' WHERE file = $file;";

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

print header();
print $HTMLstart;

$conn = Pg::connectdb("dbname=\"biblio\"");
if ($conn->status ne PGRES_CONNECTION_OK)
{ print "<p>ERROR CONNECTING TO DATABASE: ".$conn->errorMessage; goto done; }
# update db
$result = $conn->exec($update);
if ($result->resultStatus ne PGRES_COMMAND_OK)
{ print "<p>ERROR IN QUERY: ".$conn->errorMessage; goto done; }

print "<p>Publications Database was successfully updated";

done:
    print "<A HREF=\"/biblio/search.html\">Return to Publication Search</A>";
    print $HTMLend;
