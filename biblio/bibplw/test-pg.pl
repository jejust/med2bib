#!/usr/bin/perl
use Pg;
$conn = Pg::connectdb("dbname=\"biblio\"");
if ($conn->status ne PGRES_CONNECTION_OK)
{ $res = "ERROR CONNECTING TO DATABASE: ".$conn->errorMessage; goto done; }

$result = $conn->exec("SELECT * FROM master");
if ($result->resultStatus ne PGRES_TUPLES_OK)
{ $res = "ERROR IN QUERY: ".$conn->errorMessage; goto done; }

while(@row = $result->fetchrow) {
    print "ROW: ".join(' | ', @row)."\n";
}
 done:
