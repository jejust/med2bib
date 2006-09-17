#!/bin/sh
HTDIR="/lab/httpd"
BIBDIR="biblio"

/bin/cp -f html/* ${HTDIR}/html/${BIBDIR}/
/bin/cp -f cgi-bin/* ${HTDIR}/cgi-bin/${BIBDIR}/
