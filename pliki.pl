#!/usr/bin/env perl

use strict;
use warnings;

use File::Copy;
use File::Find;
use File::Path qw(make_path);
use File::stat;
use Digest::MD5;

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
our $UNIFIED_ATTRIBS = 0644;
our @UNWANTED_CHARS = (':', '"', '.', ';', '*', '?', '$', '#', '`', '|', '\\', ',', '<', '>', '/');
our $UNWANTED_SUBST = '_';
our @TMP_EXTS = ('~', '.tmp');

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

if ($mode == 1) {
    &remove_empty();
} elsif ($mode == 2) {
    &remove_temp();
} elsif ($mode == 3) {
    &unify_attrs();
} elsif ($mode == 4) {
    &remove_same_name();
} elsif ($mode == 5) {
    &remove_same_content();
} elsif ($mode == 6) {
    &subst_chars();
} elsif ($mode == 7) {
    &merge_dirs();
}


### PROCEDURES ###

sub remove_empty {
    print "Removing empty files...\n";

    my $last_answer = '';

    &process_files(sub {
        my ($base_dir, $rel_dir, $file_name) = @_;
        my $path = "$base_dir$rel_dir/$file_name";
        if (-z $path) {
            if ($last_answer eq 'A' or &in_list($last_answer = &prompt_yna("Remove empty file $path?"), ('Y', 'A'))) {
                print "Removing $path...\n";
                unlink($path) or print STDERR "Could not remove $path\n";
            }
        }
    });
}

sub remove_temp {
    print "Removing temporary files...\n";

    my $last_answer = '';

    &process_files(sub {
        my ($base_dir, $rel_dir, $file_name) = @_;
        my $path = "$base_dir$rel_dir/$file_name";
        foreach my $tmp_ext (@TMP_EXTS) {
            if ($path =~ m/\Q$tmp_ext\E$/) {
                if ($last_answer eq 'A' or &in_list($last_answer = &prompt_yna("Remove temporary file $path?"), ('Y', 'A'))) {
                    print "Removing $path...\n";
                    unlink($path) or print STDERR "Could not remove $path\n";
                    last;
                }
            }
        }
    });
}

sub unify_attrs {
    print "Unifying attributes...\n";

    my $last_answer = '';
    my $octal_unified = sprintf('%#04o', $UNIFIED_ATTRIBS);

    &process_files(sub {
        my ($base_dir, $rel_dir, $file_name) = @_;
        my $path = "$base_dir$rel_dir/$file_name";
        my $mode = stat($path)->mode & 0777;
        if ($mode ^ $UNIFIED_ATTRIBS) {
            if ($last_answer eq 'A' or &in_list($last_answer = &prompt_yna("Set attributes of $path to $octal_unified?"), ('Y', 'A'))) {
                print "Changing attributes of $path...\n";
                chmod($UNIFIED_ATTRIBS, $path) or print STDERR "Could not change mode of $path\n";
            }
        }
    });
}

sub remove_same_name {
    print "Removing duplicates (by name)...\n";

    my $last_answer = '';
    my %name_dict = ();

    # hash files by their name
    &process_files(sub {
        my ($base_dir, $rel_dir, $file_name) = @_;
        if (not defined $name_dict{$file_name}) {
            $name_dict{$file_name} = [ [ $base_dir, $rel_dir ] ];
        } else {
            push(@{$name_dict{$file_name}}, [ $base_dir, $rel_dir ]);
        }
    });

    # keep only duplicated ones
    foreach my $file_name (keys %name_dict) {
        if ($#{$name_dict{$file_name}} == 0) {
            delete($name_dict{$file_name});
        }
    }

    # process the dictionary
    foreach my $file_name (keys %name_dict) {
        my @occurences = @{$name_dict{$file_name}};
        @occurences = map {
            my ($base_dir, $rel_dir) = @{$_};
            my $path = "$base_dir$rel_dir/$file_name";
            [ $path, stat($path)->mtime ];
        } @occurences;
        @occurences = sort { @{$b}[1] <=> @{$a}[1] } @occurences;
        my ($original, @duplicates) = @occurences;
        foreach my $duplicate (@duplicates) {
            if ($last_answer eq 'A' or &in_list($last_answer = &prompt_yna("Remove file $duplicate->[0] from " . localtime($duplicate->[1]) .
                    " (seemingly superseded by $original->[0] from " . localtime($original->[1]) . ")?"), ('Y', 'A'))) {
                print "Removing $duplicate->[0]...\n";
                unlink($duplicate->[0]) or print STDERR "Could not remove $duplicate->[0]\n";
            }
        }
    }
}

sub remove_same_content {
    print "Removing duplicates (by content)...\n";

    my $last_answer = '';
    my %digest_dict = ();

    # hash files by their digest
    &process_files(sub {
        my ($base_dir, $rel_dir, $file_name) = @_;
        my $path = "$base_dir$rel_dir/$file_name";
        open(my $handle, "<$path");
        binmode($handle);
        my $digest = Digest::MD5->new->addfile($handle)->hexdigest;
        close($handle);
        if (not defined $digest_dict{$digest}) {
            $digest_dict{$digest} = [ [ $base_dir, $rel_dir, $file_name ] ];
        } else {
            push(@{$digest_dict{$digest}}, [ $base_dir, $rel_dir, $file_name ]);
        }
    });

    # keep only duplicated ones
    foreach my $digest (keys %digest_dict) {
        if ($#{$digest_dict{$digest}} == 0) {
            delete($digest_dict{$digest});
        }
    }

    # process the dictionary
    foreach my $digest (keys %digest_dict) {
        my @occurences = @{$digest_dict{$digest}};
        @occurences = map {
            my ($base_dir, $rel_dir, $file_name) = @{$_};
            my $path = "$base_dir$rel_dir/$file_name";
            [ $path, stat($path)->mtime ];
        } @occurences;
        @occurences = sort { @{$a}[1] <=> @{$b}[1] } @occurences;

        my ($original, @duplicates) = @occurences;
        foreach my $duplicate (@duplicates) {
            if ($last_answer eq 'A' or &in_list($last_answer = &prompt_yna("Remove file $duplicate->[0] from " . localtime($duplicate->[1]) .
                    " (probably a backup of $original->[0] from " . localtime($original->[1]) . ")?"), ('Y', 'A'))) {
                print "Removing $duplicate->[0]...\n";
                unlink($duplicate->[0]) or print STDERR "Could not remove $duplicate->[0]\n";
            }
        }
    }
}

sub subst_chars {
    print "Substituting unwanted characters in filenames...\n";

    my $last_answer = '';

    &process_files(sub {
        my ($base_dir, $rel_dir, $file_name) = @_;
        my $path = "$base_dir$rel_dir/$file_name";
        my $match_pattern = join('|', map { quotemeta($_) } @UNWANTED_CHARS);
        my $new_name = $file_name;
        if ($new_name =~ s/$match_pattern/$UNWANTED_SUBST/g) {
            if ($last_answer eq 'A' or &in_list($last_answer = &prompt_yna("Rename badly named $path to $new_name?"), ('Y', 'A'))) {
                print "Renaming $path...\n";
                my $new_path = "$base_dir$rel_dir/$new_name";
                rename($path, $new_path) or print STDERR "Could not rename $path\n";
            }
        }
    });
}

sub merge_dirs {
    print "Merging directories...\n";

    my $last_answer = '';

    &process_files(sub {
        my ($base_dir, $rel_dir, $file_name) = @_;
        if ($base_dir eq $directories[0]) {
            return;
        }
        my $path = "$base_dir$rel_dir/$file_name";
        my $mirror_dir = "$directories[0]$rel_dir/";
        my $mirror_path = "$mirror_dir$file_name";
        if (not -e $mirror_path) {
            if ($last_answer eq 'A' or &in_list($last_answer = &prompt_yna("Move file $path to $mirror_dir?"), ('Y', 'A'))) {
                print "Moving $path...\n";
                if (not -e $mirror_dir) {
                    make_path($mirror_dir);
                }
                move($path, $mirror_path) or print STDERR "Could not move $path\n";
            }
        }
    });
}

sub process_files {
    my ($callback) = @_;
    foreach my $i (0..$#directories) {
        foreach my $file_info (@{$files_in_dirs[$i]}) {
            $callback->($directories[$i], $file_info->[1], $file_info->[0]);
        }
    }
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
