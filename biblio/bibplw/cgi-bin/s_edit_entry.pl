#!/usr/bin/perl

use CGI;
use Text::BibTeX;

# open BibTeX file
$bibname = "sample.bib";
$bibfile = new Text::BibTeX::File $bibname;

$found = 0;
@used_paperIDs = ();
# parse BibTeX file
while ($entry = new Text::BibTeX::Entry $bibfile)
{
	next unless $entry->parse_ok;
	next unless $entry->metatype eq BTE_REGULAR;

	$paperID = $entry->get('paperID');
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
		#if(!&print_type_form($type, $paperID, $entry))
		#{
		#	&print_boring_form($entry);
		#}
		&print_boring_form($entry); # test with this for now

		print "<INPUT TYPE=\"submit\" VALUE=\"Save Changes\">\n";
		print "<INPUT TYPE=\"reset\" VALUE=\"Undo All Changes\">\n";
	}
}
if(!$found) # entry does not exist, must be adding new one
{
	$newID = 0;
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
	# can't print_boring_form because no entry to be parsed for a new entry
	&print_type_form(param('type'), $newID);
	
	print "<INPUT TYPE=\"submit\" VALUE=\"Save Entry\">\n";
	print "<INPUT TYPE=\"reset\" VALUE=\"Clear All\">\n";
}
&html_end;

exit(0);

sub html_start {
	print "Content-Type: text/html\n\n";
	print "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 3.2 Final//EN\">\n"; 
	# is above line necessary? what does it do?
	if($found == 1) { print "<HTML><HEAD><TITLE>Edit Entry</TITLE></HEAD><BODY>\n"; }
	else { print "<HTML><HEAD><TITLE>Add New Entry</TITLE></HEAD><BODY>\n"; }
	# could include banner, etc.
	print "<FORM METHOD=POST ACTION=\"/cgi-bin/biblio/modify_entry\">"
}

sub html_end {
	print "</FORM></BODY></HTML>\n";
	# could include copyright
}

# simple form, prints all fields same length, one per line, with default values
sub print_boring_form { # entry
	@fieldlist = $_[0]->fieldlist;
	foreach $f(@fieldlist)
	{
		print "$f: <INPUT TYPE = \"text\" NAME=\"$f\" VALUE=\"param($f)\">\n"; # need to specify SIZE?
	}		
}

sub print_type_form { # type, paperID, (entry)
	$type = $_[0];
	$answer = 1; # assume we will print a form for an identified type
	print "paper ID: <INPUT TYPE=\"text\" NAME=\"paperID\" SIZE=\"7\" VALUE=\"$_[1]\" READONLY>\n";
	if($_[2]) { $entry = $_[2]; }
	else { $entry = new Text::BibTeX::Entry; } # trying to create an empty entry

	# handling case correctly?
	# Need {} for if statement commands?
	if($type =~ /^[Aa]rticle$/) { &print_art($entry); }
	elsif($type =~ /^[Bb]ook$/) { &print_boo; }
	elsif($type =~ /^[Bb]ooklet$/) { &print_let; }
	elsif($type =~ /^[Ii]nbook$/) { &print_inb; }
	elsif($type =~ /^[Ii]n[Cc]ollection$/) { &print_inc; }
	elsif($type =~ /^[Ii]n[Pp]roceedings$/) { &print_inp; }
	elsif($type =~ /^[Mm]anual$/) { &print_man; }
	elsif($type =~ /^[Mm]aster[Tt]hesis$/) { &print_mas; }
	elsif($type =~ /^[Mm]isc$/) { &print_mis; }
	elsif($type =~ /^[Pp]atent$/) { &print_pat; }
	elsif($type =~ /^[Pp]h[Dd][Tt]hesis$/) { &print_phd; }
	elsif($type =~ /^[Pp]roceedings$/) { &print_pro; }
	elsif($type =~ /^[Tt]ech[Rr]eport$/) { &print_tec; }
	elsif($type =~ /^[Uu]n[Pp]ublished$/) { &print_unp; }
	else { $answer = 0; } # did not print a form
	return $answer;
}

sub print_art {
	$entry = $_[0];
#	print "&cell(Title: <INPUT TYPE=\"text\" NAME=\"title\" SIZE=\"40\" VALUE=$entry->get('title')>)\n";
	print "Title: <INPUT TYPE=\"text\" NAME=\"title\" SIZE=\"40\" VALUE=$entry->get('title')>\n";
}

sub print_boo {

}

sub print_let {

}

sub print_inb {

}

sub print_inc {

}

sub print_inp {

}

sub print_man {

}

sub print_mas {

}

sub print_mis {

}

sub print_pat {

}

sub print_phd {

}

sub print_pro {

}

sub print_tec {

}

sub print_unp {

}

#sub cell { # text, style
#	if($_[1]) { return ("<TD CLASS=`$_[1]`>$_[0]</TD>"); } # are back quotes correct?
	#else { 
#	return (<TD>$_[0]</TD>); 
	#}
#}

#sub row {
#	return (<TR>$_[0]</TR>);
#}
