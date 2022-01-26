#!/bin/perl

$CONFIG_FILE_LOCATION = "$ENV{HOME}/.clean_files";

# default settings
$UNIFIED_ATTRIBS = 'rw-r--r--';
@UNWANTED_CHARS = (':', '"', '.', ';', '*', '?', '$', '#', '`', '|', '\\', ',', '<', '>', '/');
$UNWANTED_SUBST = '_';
@TMP_EXTS = ('~', '.tmp');

do "$CONFIG_FILE_LOCATION" if -f "$CONFIG_FILE_LOCATION";
