#!/usr/bin/perl
while(<STDIN>) {
    chomp; $line = $_;
    if (lc(substr($line, 0, 5)) eq 'month') {
	($xx, $yy) = split(/=/, $line, 2);
	$yy =~ s/\s+//g; $yy =~ s/[\{\}]//g;
	$mo = uc(substr($yy,0,1)).lc(substr($yy, 1, 2));
	if ($mo eq "Jan" || $mo eq "Feb" || $mo eq "Mar" || $mo eq "Apr" ||
	    $mo eq "May" || $mo eq "Jun" || $mo eq "Jul" || $mo eq "Aug" ||
	    $mo eq "Sep" || $mo eq "Oct" || $mo eq "Nov" || $mo eq "Dec")
	{ print "month = { $mo },\n"; }
    } else { print "$line\n"; }
}
