#!/usr/bin/perl
use Pg; # postgresql
use Text::BibTeX;
require 'ctime.pl'; # for recording current date

$bibname = $ARGV[0] || die "USAGE: $0 <bibfile> <tablename>\n";
$tabname = $ARGV[1] || die "USAGE: $0 <bibfile> <tablename>\n";

$bibfile = new Text::BibTeX::File $bibname;
$conn = Pg::connectdb("dbname=\"biblio\"");
if ($conn->status ne PGRES_CONNECTION_OK)
{ $res = "ERROR CONNECTING TO DATABASE: ".$conn->errorMessage; goto done; }

# there are two many possible bogus fake BibTeX entries in to filter
# out. So rather we will enforce that we only use in %values the
# entries in our database; here we provide valid database fields for
# given BibTeX fields:
%valid = ( 'key' => 'key',
	   'entrytype' => 'entrytype',
	   'author' => 'author',
	   'title' => 'title',
	   'journal' => 'journal',
	   'volume' => 'volume',
	   'number' => 'number',
	   'pages' => 'pages',
	   'page' => 'pages',
	   'month' => 'month',
	   'year' => 'year',
	   'booktitle' => 'booktitle',
	   'editor' => 'editor',
	   'organization' => 'organization',
	   'institution' => 'organization',
	   'school' => 'organization',
	   'publisher' => 'publisher',
	   'address' => 'address',
	   'keywords' => 'keywords',
	   'abstract' => 'abstract',
	   'type' => 'type',
	   'pdf' => 'pdf',
	   'pdfurl' => 'pdf',
	   'file' => 'file',
	   'url' => 'url',
	   'note' => 'note' ); # date handled separately

# if a paper has not been filed yet, we will give it a number >= 10000
# first, figure out the max file number:
$result = $conn->exec("SELECT max(file) FROM $tabname");
if ($result->resultStatus ne PGRES_TUPLES_OK)
{ print $conn->errorMessage; exit(1); }
@row = $result->fetchrow; $number = $row[0];
if ($number < 10000) { $number = 10000; }
print "Highest entry number in database: $number\n";
$number ++;

while ($entry = new Text::BibTeX::Entry $bibfile)
{
    next unless $entry->parse_ok;
    next unless $entry->metatype eq BTE_REGULAR;
    undef %values;

    @fields = $entry->fieldlist;
    foreach $field (@fields) {
	if ($valid{$field}) {
	    $values{$valid{$field}} = $entry->get($field);
	}
    }

    # Key and type are present for every BibTeX entry
    $values{"key"} = $entry->key;
    $entrytype = lc($entry->type); $entrytype =~ s/\s+//g;
    # author, year, and file are mandatory
    # month is included in every DB entry, even if was not in the BibTeX entry
    # date is added to every DB entry

    # Make sure all mandatory fields are present
    # If not, display error and continue to next entry
    if ( (!$entry->exists('author')) || ($values{"author"} eq "") ) {
	print "ERROR: Author field not present or empty for ".
	    $values{"key"}." -- SKIPPING.\n";
	next;
    }
    if ( (!$entry->exists('year')) || ($values{"year"} eq "")) {
	print "ERROR: Year field not present or empty for ".
	    $values{"key"}." -- SKIPPING.\n";
	next;
    }    

    # if file is an URL, move it to pdf (for iLab.bib):
    if (lc($values{'file'} =~ /http/)) {
	$values{'pdf'} = $values{'file'}; $values{'file'} = "";
    }
    if ( (!$entry->exists('file')) || ($values{"file"} eq "") ) {
	$values{'file'} = $number;
    }

    # encode entrytype as an integer
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
    else {
	print "ERROR: Unkown entry type for ".
	    $values{"key"}." -- SKIPPING.\n";
	next;
    }
    $values{"entrytype"} = $typecode;

    # if year is "in press", set it to -1
    $year = lc($entry->get('year')); 
    $year =~ s/\s+//g;
    if($year eq "inpress") { $year = -1; }
    # remove non-digits from year:
    $year =~ s/\D//g;
    $values{"year"} = $year;

    # file in BibTex is XXXXX.pdf, in DB is just XXXXX (drop the ".pdf")
    $values{"file"} = substr($values{"file"},0,5);

    # format month as an integer, 1-12 if it exists, 0 if it does not
    $mo = 0; # default
    if ($entry->exists('month')) {
	$month = substr(lc($entry->get('month')),0,3);
	if($month eq "jan") { $mo = 1; }
	elsif($month eq "feb") { $mo = 2; }
	elsif($month eq "mar") { $mo = 3; }
	elsif($month eq "apr") { $mo = 4; }
	elsif($month eq "may") { $mo = 5; }
	elsif($month eq "jun") { $mo = 6; }
	elsif($month eq "jul") { $mo = 7; }
	elsif($month eq "aug") { $mo = 8; }
	elsif($month eq "sep") { $mo = 9; }
	elsif($month eq "oct") { $mo = 10; }
	elsif($month eq "nov") { $mo = 11; }
	elsif($month eq "dec") { $mo = 12; }
    }
    $values{"month"} = $mo;

    # record date this entry is added to DB
    $date = &ctime(time); # today's date, ie Mon Oct  8 11:44:51 2001
                          # pgsql automatically converts to yyyy-mm-dd
    $date = substr($date,0,24);
    $notdone = 26;

    while($notdone) {
	# create SQL command string
	$cmd = "INSERT INTO $tabname (";
	foreach $key (keys %values) {
	    $cmd .= $key.", ";
	}
	$cmd .= "date) VALUES (";
	# couldn't think of better way to eliminate trailing comma
	# so "date" is not included in %values
	foreach $key (keys %values) {
	    $v = $values{$key};
	    $v =~ s/'/\\'/g; # protect single quotes
	    $v =~ s/[{}]//g; # remove bibtex braces
	    $cmd .= "'" . $v . "', ";
	}
	$cmd .= "'".$date."')";

	$result = $conn->exec($cmd);
	if ($result->resultStatus ne PGRES_COMMAND_OK)  
	{
	    print "INSERT failed! for $values{'key'} [$number]\n";
	    print "  ". $conn->errorMessage;

	    # check whether the existing entry in the
	    # database matches the one we are trying to insert...
	    # we already know that first 2 authors & year match; let's
	    # just do an additional test on page numbers:
	    $res2 = $conn->exec("select pages from $tabname where key='".
				$values{'key'}."'");
	    
	    if ($res2->resultStatus ne PGRES_TUPLES_OK)
	    { print $conn->errorMessage; $notdone = 0; }
	    $notfound = 1; $pp = $values{'pages'}; $pp =~ s/\s+//g;
	    while (@row2 = $res2->fetchrow) {
		$p = $row2[0]; $p =~ s/\s+//g;
		if ($p eq $pp) {
		    $notfound = 0;
		    print "  OK, already in database.\n";
		}
	    }
	    if ($notfound) {
		# add a 'a' or other letter at the end of the key:
		if (substr($values{'key'}, -1, 1) =~ /[0-9]/) {
		    $values{'key'} .= 'a';
		} else { substr($values{'key'}, -1, 1) ++; }
		print "  retrying as $values{'key'}...\n";
		$notdone --;
	    } else { $notdone = 0; }
	}
	else
	{ print "INSERTed " . $values{'key'} .".\n"; $notdone=0; $number ++; }
    }
}



