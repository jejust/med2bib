#!/usr/bin/perl

require 'ctime.pl';
print &ctime(time),"\n";

system 'date';

$date = system 'date';
print $date;
print "\n\n";
$date2 = substr($date, 0, 1);
print $date2;
$date3 = substr($date, 24, 4);
print $date3;
