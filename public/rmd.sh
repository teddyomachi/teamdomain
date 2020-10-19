#!/bin/sh
BINDIR=`dirname $0`
psql -d spin_development -U spinadmin < $BINDIR/rmd.sql
