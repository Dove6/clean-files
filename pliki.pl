#!/bin/perl

$USAGE = "usage: $0 mode original_dir [copy_dir...]

mode            operational mode, which may be
                1 - remove empty files
                2 - remove temp files
                3 - unify file attributes
                4 - remove duplicates (by content)
                5 - remove duplicates (by name)
                6 - substitute unwanted characters in filenames
                7 - merge directories
original_dir    path to the original file directory
copy_dir        path to a directory where copies may reside
";
@ALLOWED_MODES = (1, 2, 3, 4, 5, 6, 7);

if (grep(/^(-h)|(--help)$/, @ARGV)) {
    print $USAGE;
    exit();
}
($mode, $original_dir, @copy_dirs) = @ARGV;
if (defined $mode and not grep(/^$mode$/, @ALLOWED_MODES)) {
    print STDERR "Invalid mode!\n";
    print STDERR $USAGE;
    exit();
}
if (not defined $mode or not defined $original_dir) {
    print STDERR "Required arguments are missing!\n";
    print STDERR $USAGE;
    exit();
}

$CONFIG_FILE_LOCATION = "$ENV{HOME}/.clean_files";

# default settings
$UNIFIED_ATTRIBS = 0064;
@UNWANTED_CHARS = (':', '"', '.', ';', '*', '?', '$', '#', '`', '|', '\\', ',', '<', '>', '/');
$UNWANTED_SUBST = '_';
@TMP_EXTS = ('~', '.tmp');

do "$CONFIG_FILE_LOCATION" if -f "$CONFIG_FILE_LOCATION";
