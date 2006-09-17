#!/usr/bin/perl
use Pg; # postgresql
use Text::BibTeX;
require 'ctime.pl'; # for recording current date

$bibname = $ARGV[0]; # script takes first argument as file to convert
$bibfile = new Text::BibTeX::File $bibname;

while ($entry = new Text::BibTeX::Entry $bibfile)
{
    next unless $entry->parse_ok;
    next unless $entry->metatype eq BTE_REGULAR;

    @fields = $entry->fieldlist;
    foreach $field (@fields) {
	$values{$field} = $entry->get($field);
    }

    # Key and type are present for every BibTeX entry
    $values{"key"} = $entry->key;
    $entrytype = $entry->type;
    # author, year, and file are mandatory
    # month is included in every DB entry, even if it was not in the BibTeX entry
    # date is added to every DB entry

    # Make sure all mandatory fields are present
    # If not, display error and continue to next entry
    if ( (!$entry->exists('author')) || ($values{"author"} eq "") ) {
	print "ERROR: Author field not present or empty for ".$values{"key"}."\n";
	next;
    }
    if ( (!$entry->exists('year')) || ($values{"year"} eq "")) {
	print "ERROR: Year field not present or empty for ".$values{"key"}."\n";
	next;
    }    
    if ( (!$entry->exists('file')) || ($values{"file"} eq "") ) {
	print "ERROR: File field not present or empty for ".$values{"key"}."\n";
	next;    
    }

    # encode entrytype as an integer
    if($entrytype =~ /^[Aa]rticle$/) { $typecode = 1; }
    elsif($entrytype =~ /^[Bb]ook$/) { $typecode = 2; }
    elsif($entrytype =~ /^[Bb]ooklet$/) { $typecode = 3; }
    elsif($entrytype =~ /^[Ii]n[Bb]ook$/) { $typecode = 4; }
    elsif($entrytype =~ /^[Ii]n[Cc]ollection$/) { $typecode = 5; }
    elsif($entrytype =~ /^[Ii]n[Pp]roceedings$/) { $typecode = 6; }
    elsif($entrytype =~ /^[Mm]anual$/) { $typecode = 7; }
    elsif($entrytype =~ /^[Mm]aster[Tt]hesis$/) { $typecode = 8; }
    elsif($entrytype =~ /^[Mm]isc$/) { $typecode = 9; }
    elsif($entrytype =~ /^[Pp]h[Dd][Tt]hesis$/) { $typecode = 10; }
    elsif($entrytype =~ /^[Pp]roceedings$/) { $typecode = 11; }
    elsif($entrytype =~ /^[Tt]ech[Rr]eport$/) { $typecode = 12; }
    elsif($entrytype =~ /^[Uu]n[Pp]ublished$/) { $typecode = 13; }
    elsif($entrytype =~ /^[Pp]atent$/) { $typecode = 14; }
    else { print "ERROR: Unkown entry type for ".$values{"key"}."\n"; next; }
    $values{"entrytype"} = $typecode;
    
    # if year is "in press", set it to -1
    $year = $entry->get('year');
    if($year eq "in press") { $year = -1; }
    $values{"year"} = $year;

    # file in BibTex is XXXXX.pdf, in DB is just XXXXX (drop the ".pdf")
    $values{"file"} = substr($values{"file"},0,5);

    # institution, school, and organization are all stored in "organization" field of DB
    if ($entry->exists('institution')) { 
	$values{"organization"} = $entry->get('institution'); 
	delete $values{"institution"}
    }
    if ($entry->exists('school')) { 
	$values{"organization"} = $entry->get('school'); 
	delete $values{"school"};
    }

    # format month as an integer, 1-12 if it exists, 0 if it does not
    $mo = 0; # default
    if ($entry->exists('month')) {
	$month = $entry->get('month');
	if($month eq "Jan") { $mo = 1; }
	elsif($month eq "Feb") { $mo = 2; }
	elsif($month eq "Mar") { $mo = 3; }
	elsif($month eq "Apr") { $mo = 4; }
	elsif($month eq "May") { $mo = 5; }
	elsif($month eq "Jun") { $mo = 6; }
	elsif($month eq "Jul") { $mo = 7; }
	elsif($month eq "Aug") { $mo = 8; }
	elsif($month eq "Sep") { $mo = 9; }
	elsif($month eq "Oct") { $mo = 10; }
	elsif($month eq "Nov") { $mo = 11; }
	elsif($month eq "Dec") { $mo = 12; }
    }
    $values{"month"} = $mo;

    # record date this entry is added to DB
    $date = &ctime(time); # today's date, ie Mon Oct  8 11:44:51 2001
                          # pgsql automatically converts date to form yyyy-mm-dd
    $date = substr($date,0,24);

    # create SQL command string
    $cmd = "INSERT INTO master (";
    foreach $key (keys %values) {
	$cmd .= $key.", ";
    }
    $cmd .= "date) VALUES ("; # couldn't think of better way to eliminate trailing comma
                              # so "date" is not included in %values
    foreach $key (keys %values) {
	$cmd .= "'".$values{$key}."', ";
    }
    $cmd .= "'".$date."');";

    print $cmd."\n\n";
}

 done:






