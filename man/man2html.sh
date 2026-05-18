#!/usr/bin/env bash

cd "$(dirname "$0")" || exit

/usr/bin/man ./hear.1 | ./cat2html > hear.1.html
