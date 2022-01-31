# Clean files

A simple, interactive Perl script for tidying up your documents, photos, music... by detecting duplicates, temporary and empty files.

An assignment for the ["Unix System and TCP/IP Network Administration" course](https://usosweb.usos.pw.edu.pl/kontroler.php?_action=katalog2%2Fprzedmioty%2FpokazPrzedmiot&prz_kod=103B-INSID-ISP-ASU&lang=en).

## Task

Let's assume we have a multitude of documents, video records, movies and photos in directory **X** and its subdirectories. We also store one or more copies of those files in directories **Y1**, **Y2**, ..., but the copies can be named differently and be located at a different point of the directory tree. There may even appear some files that are present in **Y1**, **Y2**, ... dirs, but not in **X**.

Clean up the file structure so that:
- directory **X** stores all the files,
- exact duplicates are removed: only the oldest one of files sharing the same content is left as the others are probably backups,
- empty and temporary files are removed,
- from among files sharing the same name, only the newest one remains,
- file attributes are unified (eg. `rw-r--r--`),
- troublesome characters in filenames (eg. `:`, `"`, `.`, `;`, `*`, `?`, `$`, `#`, `` ` ``, `|`, `\`, ...) are substituted with a safe one (eg. `_`).

Users should be prompted to confirm any permanent modification (eg. removing, renaming or moving a file).

The script should be able to search for:
- files sharing the same content (but not necessarily the same name or relative location),
- empty files,
- files sharing the same name (but not necessarily the same relative location),
- temporary files (with names ending with `~`, `.tmp` or other, user-defined extensions),
- files with atypical attributes (eg. `rwxrwxrwx`),
- files with names containing troublesome characters.

The script should suggest a proper action for each found file:
- moving or copying the file to directory **X**,
- removing the duplicate, empty or temporary file,
- replacing the older version with the newer version,
- replacing the newer version with the older version (for files with identical content),
- changing file attributes,
- changing file name,
- no action.

Performing all the actions may require the script to be run several times (for example in the first run the script deals with all empty files, in the second run it removes duplicates, etc.).

Configuration including:
- file attributes after unification, eg. `rw-r--r--`,
- list of troublesome characters,
- a substitute for troublesome character,
- extensions of temporary files

should be read from a file, eg. `$HOME/.clean_files`.
