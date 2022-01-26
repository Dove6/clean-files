#!/bin/perl

use strict;

my $USAGE = "usage: $0 mode original_dir [copy_dir...]

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
my @ALLOWED_MODES = (1, 2, 3, 4, 5, 6, 7);

if (&in_list('-h', @ARGV) or &in_list('--help', @ARGV)) {
    print $USAGE;
    exit();
}
my ($mode, $original_dir, @copy_dirs) = @ARGV;
if (defined $mode and not &in_list($mode, @ALLOWED_MODES)) {
    print STDERR "Invalid mode!\n";
    print STDERR $USAGE;
    exit();
}
if (not defined $mode or not defined $original_dir) {
    print STDERR "Required arguments are missing!\n";
    print STDERR $USAGE;
    exit();
}

my $CONFIG_FILE_LOCATION = "$ENV{HOME}/.clean_files";

# default settings
my $UNIFIED_ATTRIBS = 0064;
my @UNWANTED_CHARS = (':', '"', '.', ';', '*', '?', '$', '#', '`', '|', '\\', ',', '<', '>', '/');
my $UNWANTED_SUBST = '_';
my @TMP_EXTS = ('~', '.tmp');

do "$CONFIG_FILE_LOCATION" if -f "$CONFIG_FILE_LOCATION";

sub eqi {
    my ($a, $b) = @_;
    return uc($a) eq uc($b);
}

sub in_list {
    my ($needle, @haystack) = @_;
    foreach (@haystack) {
        if (&eqi($needle, $_)) {
            return 1;
        }
    }
}

# source: https://stackoverflow.com/a/18104317
sub prompt {
  my ($query) = @_;  # take a prompt string as argument
  local $| = 1;  # activate autoflush to immediately show the prompt
  print $query;
  chomp(my $answer = <STDIN>);
  return $answer;
}

# based on: https://stackoverflow.com/a/18104317
sub prompt_ynaec {
    my ($query) = @_;
    my @ACCEPTABLE_ANSWERS = ('Y', 'N', 'A', 'E', 'C', '');
    my $message = 'Yes (Y)/ No (N)/ Yes for all (A)/ No for all (E)/ Cancel (C): [Y]';
    my $answer = &prompt("$query$message\n");
    while (not &in_list($answer, @ACCEPTABLE_ANSWERS)) {
        print STDERR "Bad input!!\n";
        $answer = &prompt("$query$message\n");
    }
    if ($answer eq '') {
        $answer = 'Y';
    }
    return uc($answer);
}

sub remove_empty {
    ;
}

sub remove_temp {
    ;
}

sub unify_attrs {
    ;
}

sub remove_same_name {
    ;
}

sub remove_same_content {
    ;
}

sub subst_chars {
    ;
}

sub merge_dirs {
    ;
}
