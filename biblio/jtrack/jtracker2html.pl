#!/usr/bin/perl

$nb = 10;   # number of pages kept in the queue
chdir("/home/httpd/html/jtrack");
umask 022;

$txt = ""; $jtrack = 0; $dat = ""; $subj = "";
while(<STDIN>) {
    chomp; $x = $_; $txt .= $x."\n";
    if (substr($x, 0, 15) eq "From: JTracker@") { $jtrack = 1; }
    if (substr($x, 0, 5) eq "Date:") { $dat = substr($x, 6); }
    if (substr($x, 0, 8) eq "Subject:") { $subj = substr($x, 9); }
}

if ($jtrack == 0) {   # not a JTrack mail!
    open F, ">>/home/jtrack/mail/bogus";
    print F $txt; close F; exit 0;
}

# make sure another jtracker2html is not already messing things up:
$lockfile = SetLockFile("lock", "lock");
while($lockfile eq "") { sleep 2; $lockfile = SetLockFile("lock", "lock"); }

# shift all the old records up:
system("/bin/mkdir 00"); system("/bin/rm -rf $nb");
$ii = $nb - 1;
while($ii >= 0) {
    $old = sprintf("%02d", $ii); $new = sprintf("%02d", $ii+1);
    system("/bin/mv $old $new"); $ii --;
}

# write summary info and recompile main index:
open F, ">01/info" || die "Cannot write 01/info: $!";
print F "<TR><TD><A HREF=\"_%_/all.html\">$subj</A></TD><TD>"
    ."$dat</TD></TR>\n";
close F;
$ii = 1; $idx = `/bin/cat index.start`;
while($ii <= $nb) {
    $curr = sprintf("%02d", $ii);
    $inf = `cat $curr/info`; $inf =~ s/\_%\_/$curr/;
    $idx .= $inf; $ii ++;
}
$idx .= `/bin/cat index.end`;
open F, ">index.html" || die "Cannot write index.html: $!";
print F $idx; close F;

# now process the email and generate the html:
open F, "|./jt2bib > 01/jtrack.bib" || die "Cannot pipe to jt2bib: $!";
print F $txt; close F;
system("cd 01; ../bibTOhtml-JT jtrack.bib");

# remove our lockfile
system("/bin/rm $lockfile");
exit(0);

# This is the file locking routines which come with Agora.  Code is
# either partially modified or directly ripped from that program.
#
# Agora is by Arthur Secret <secret@w3.org> and Hugh Sasse
# <hgs@dmu.ac.uk>.  Agora's copyright is at
# http://www.w3.org/hypertext/COPYRIGHT.html.
#


# SetLockFile(Directory, Filename)
#
# Returns 1 on success, 0 on error.
sub SetLockFile
{
    local($Dir, $FileName) = @_;
    local($have_exclusive_lock) = 0;

    srand $$;

    while(!$have_exclusive_lock)
    {
        # Is there a lockfile?
        opendir(LOCKDIR, "$Dir") || return 0;
        @lockfiles = readdir(LOCKDIR);
        closedir(LOCKDIR);

        @lockfiles = grep(($_ =~ /${FileName}_[0-9]+.lck/i), @lockfiles);

        if( $#lockfiles == -1)
        {
            # there are none here already, so we can create one.
            open(LOCKFILE, ">$Dir/${FileName}_$$.lck") ||
                return 0;
            print LOCKFILE "Lock file\n";
            close(LOCKFILE);

            ## So we have now created a lock file.  We
            # may still not have an exclusive lock. Another
            # process may have got the lock at the same time.

            opendir(LOCKDIR, "$Dir") || return 0;
            @lockfiles = readdir(LOCKDIR);  
            closedir(LOCKDIR); 
 
            @lockfiles = grep(($_ =~ /${FileName}_[0-9]+.lck/i),
                @lockfiles);

            if($#lockfiles == 0)
            {
               # there is only one lock file so it must be
               # ours.
               $have_exclusive_lock = 1;
            } 
            else
            {
               # we need to remove the lockfile we have made...
               unlink("$Dir/${FileName}_$$.lck") || return 0;
               # and wait a random length of time.
               sleep(rand($$ % 3));
            }; # end if $#lockfiles == 0 ...else..
        }
        else
        {
            # there is a lock file.
            # wait a random length of time.
            sleep(rand($$ % 3));
        }; # end if ($#lockfiles == -1) ... else....

    }; # end while(!$have_exclusive_lock)

    # there is only one lockfile -- ours -- so we can proceed
    return "$Dir/${FileName}_$$.lck";
}; # end sub quota_write_file();

