#!/usr/bin/env perl

use strict;
use warnings;

use File::Find;
use Data::Dumper;

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


### VALIDATION OF ARGUMENTS ###

my ($mode, @directories) = @ARGV;

if (&in_list('-h', @ARGV) or &in_list('--help', @ARGV)) {
    print $USAGE;
    exit();
}
if (defined $mode and not &in_list($mode, @ALLOWED_MODES)) {
    &my_die("Invalid mode: $mode");
}
if (defined $directories[0]) {
    my @sorted_dirs = sort @directories;
    my $last_dir = '';
    foreach my $dir (@sorted_dirs) {
        if (not -d $dir) {
            &my_die("Invalid path: $dir");
        }
        if ($dir eq $last_dir) {
            &my_die("Directory is duplicated: $dir");
        }
        $last_dir = $dir;
    }
}
if (not defined $mode or not defined $directories[0]) {
    &my_die('Required arguments are missing!');
}


### CONFIGURATION DEFINITION ###

my $CONFIG_FILE_LOCATION = "$ENV{HOME}/.clean_files";

# default settings
my $UNIFIED_ATTRIBS = 0064;
my @UNWANTED_CHARS = (':', '"', '.', ';', '*', '?', '$', '#', '`', '|', '\\', ',', '<', '>', '/');
my $UNWANTED_SUBST = '_';
my @TMP_EXTS = ('~', '.tmp');

do "$CONFIG_FILE_LOCATION" if (-f "$CONFIG_FILE_LOCATION");


### GATHERING ALL FILES ###

my @files_in_dirs = ();
foreach my $i (0..$#directories) {
    my @files_in_dir = ();
    find(sub {
        my ($name_only, $relative_dir) = ($_, $File::Find::dir);
        $relative_dir =~ s/\Q$directories[$i]//;
        push(@files_in_dir, [ $name_only, $relative_dir ]) if (-f $_);
    }, $directories[$i]);
    push(@files_in_dirs, \@files_in_dir);
}


### MAIN SWITCH ###

if ($mode eq 1) {
    &remove_empty();
} elsif ($mode eq 2) {
    &remove_temp();
} elsif ($mode eq 3) {
    &unify_attrs();
} elsif ($mode eq 4) {
    &remove_same_name();
} elsif ($mode eq 5) {
    &remove_same_content();
} elsif ($mode eq 6) {
    &subst_chars();
} elsif ($mode eq 7) {
    &merge_dirs();
}


### PROCEDURES ###

sub remove_empty {
    print "Removing empty files...\n";

    my $last_answer = '';

    foreach my $i (0..$#directories) {
        foreach my $file_info (@{$files_in_dirs[$i]}) {
            my $path = "$directories[$i]$file_info->[1]/$file_info->[0]";
            if (-z $path) {
                if ($last_answer eq 'A' or &in_list($last_answer = &prompt_yna("Remove empty file $path?"), ('Y', 'A'))) {
                    print "Removing $path...\n";
                    unlink($path);
                }
            }
        }
    }
}

sub remove_temp {
    print "Removing temporary files...\n";
}

sub unify_attrs {
    print "Unifying attributes...\n";
}

sub remove_same_name {
    print "Removing duplicates (by name)...\n";
}

sub remove_same_content {
    print "Removing duplicates (by content)...\n";
}

sub subst_chars {
    print "Substituting unwanted characters in filenames...\n";
}

sub merge_dirs {
    print "Merging directories...\n";
}

sub my_die {
    my ($message) = @_;
    print STDERR "$message\n\n";
    print STDERR $USAGE;
    exit();
}

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
sub prompt_yna {
    my ($query) = @_;
    my @ACCEPTABLE_ANSWERS = ('Y', 'N', 'A', '');
    my $message = 'Yes (Y)/ No (N)/ Yes to all (A): [Y]';
    my $answer = &prompt("$query\n$message\n");
    while (not &in_list($answer, @ACCEPTABLE_ANSWERS)) {
        print STDERR "Bad input!!\n";
        $answer = &prompt("$query\n$message\n");
    }
    if ($answer eq '') {
        $answer = 'Y';
    }
    return uc($answer);
}
