#!/usr/bin/perl

print "Content-Type: text/html\n\n";
print "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 3.2 Final//EN\">\n"; 
# is above line necessary? what does it do?
print "<HTML><HEAD><TITLE>Test Page</TITLE></HEAD><BODY>\n";
# could include banner, etc.
print "<FORM METHOD=GET>\n";

print "paper ID: <INPUT TYPE=\"text\" NAME=\"paperID\" SIZE=\"7\" VALUE=\"37\" READONLY>\n";
print "Name: <INPUT TYPE=\"text\" NAME=\"name\" SIZE=\"20\" VALUE=\"Philip Williams\">\n";

print "<INPUT TYPE=\"submit\" VALUE=\"Save Entry\">\n";
print "<INPUT TYPE=\"reset\" VALUE=\"Clear All\">\n";
print "</FORM></BODY></HTML>\n";

