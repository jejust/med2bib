#!/usr/bin/perl
use Text::BibTeX;
$bibname = shift || die "USAGE: $0 <bibfile.bib>\n";
$bibfile = new Text::BibTeX::File $bibname;
$newbib = new Text::BibTeX::File ">new-$bibname";

while ($entry = new Text::BibTeX::Entry $bibfile)
{
    next unless $entry->parse_ok;
    next unless $entry->metatype eq BTE_REGULAR;
#    $au = eclean('author');
#    if (length($au) > 1) { $entry->set('author', $au); }
#    $ed = eclean('editor');
#    if (length($ed) > 1) { $entry->set('editor', $ed); }

    if ($jo = $entry->get('journal')) {
	$jo =~ s/\.\s/ /g; $jo =~ s/\.$//;
	$jo =~ s/\s+/ /g;
	$entry->set('journal', $jo);
    }
    $entry->write($newbib);
}

sub eclean {
    if (! $entry->get($_[0])) { return ""; }
    my @x = $entry->split($_[0]);
    my $zz = join(' & ', @x);
    my $y = ""; my $a;
    while($a = shift(@x)) {
	$a =~ s/[\.{}]/ /g;
	$a =~ s/\s+/ /g; 
	my $n = "", $i = "", $jj;
	if ($a =~ m/,/) {
	    ($n, $i) = split(/\s*,/, $a, 2);
	    $y .= "$n, "; $i = substr($i, 1, length($i)-1);
	    my @ii = split(/\s+/, $i);
	    while($jj = shift(@ii)) { $y .= uc(substr($jj, 0, 1))." "; }
	    $y .= "and ";
	} else {
	    my @ff = split(/ /, $a); my $init = 1; my $jj;
	    while($jj = shift(@ff)) {
		if ($init) {
		    if (length($jj) == 1) { $i .= uc($jj)." "; }
		    else { $n .= $jj." "; $init = 0; }
		} else { $n .= $jj." "; }
	    }
	    $n = substr($n, 0, length($n)-1);
	    $y .= "$n, ${i}and ";
	}
    }
    $y = substr($y, 0, length($y) - 5);
    print "$zz => $y\n";
    return $y
}
