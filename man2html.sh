#!/usr/bin/env bash

cd "$(dirname "$0")"

/usr/bin/man ./hear.1 | ./cat2html > hear.1.html
