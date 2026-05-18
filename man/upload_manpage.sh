#!/bin/sh

REMOTE_USER=$1

scp hear.1.html "$REMOTE_USER"@sveinbjorn.org:/www/sveinbjorn/html/files/manpages/hear.1.html
