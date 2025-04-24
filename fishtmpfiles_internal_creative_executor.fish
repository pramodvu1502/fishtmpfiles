#!/usr/bin/env fish

# This script implements a parser for tmpfiles.d files
# to create temporary files as specified.

# Systemd v257 spec: https://www.freedesktop.org/software/systemd/man/257/tmpfiles.d.html

# This works by listing the tmpfiles.d files,
# masking the overriden files in preceding directories,
# and sourcing the files as if they were a script.

# The "Type" field's identifiers like 'f' are defined as fish functions
# This includes '!' '$' '+' identifiers as separate functions...

# This script initially has only functions to parse a single file...
# and will be executed by another as a helper, on the files, after listing.

### IMPORTANT rewrite to use execl-toc from 66-tools

# XXX XXX NOT argv[x] x=1, but x= something else
set -g tmpfilesdotdfile "$argv[1]"

set -g verbose "-v" # Needs to be externally configurable... and actually used in the script

# Environment variables for 66-yeller/oblog
set -gx PROG (status basename) # Not used, but still...
test -n "$VERBOSITY" || set -gx VERBOSITY 1
set -gx COLOR_ENABLED 1
set -gx CLOCK_ENABLED 0

## Internal helper functions

# Start every tmpfiles.d function with "_argv_vars $argv" to get the variables
# The variables are set globally across the script,
# so all other helper functions get it too, automatically.
function _argv_vars
set -g path "$argv[1]" # /file/or/directory/or/whatever
set -g mode "$argv[2]" # octal permission mode
set -g user "$argv[3]" # The owning user
set -g group "$argv[4]" # The owning group
set -g cleanup_age "$argv[5]" # XXX This isn't yet implemented
# argv[6] is function-specific.
end

function _wrong_file_format
    # Define the file formats
    # Using test rather than execl-toc to avoid extra processes
    test -b "$path" && set -f ftype "block device"
    test -c "$path" && set -f ftype "character device"
    test -d "$path" && set -f ftype "directory"
    test -f "$path" && set -f ftype "regular file"
    test -L "$path" && set -f ftype "symbolic link (symlink)"
    test -p "$path" && set -f ftype "named pipe (fifo)"
    test -s "$path" && set -f ftype "AF_UNIX socket"

    # Print the file format as wrong
    # This function is called *only* if the file type is wrong to the tmpfiles.d-function
    test "argv[1]" = "nooverwrite" && set -f vF '-F'
    test "argv[1]" = "nooverwrite" && set -f msg_end "%yleft untouched%n."
    test "argv[1]" = "nooverwrite" || set -f msg_end "%yoverwritten%n."
    # '-F' just exits non-zero if in $vF
    oblog $vF "The specified path is of a %rwrong type%n $ftype and is $msg_end"
end

# All might be redundant with execl-toc
function _chmod
    test "$argv[3]" = "recurse" && set -f recurse "-R"
    not test "$mode" = '-' && command chmod -c $recurse "$path"
end

function _chown
    test "$argv[4]" = "recurse" && set -f recurse "-R"
    test "$user" = '-' && set -fe user
    test "$group" = '-' && set -fe group

    if test -n "$user" || test -n "$group"
        command chown -Phc $verbose $recurse "{$user}:{$group}" "$path"
    end
end

function execl-toc
    command execl-toc "-v{$VERBOSITY}" -X {$argv}
end

# Mostly redundant as anyways 66-yeller is bundled in the same package as execl-toc
function oblog
    if test -x (which 66-yeller)
        command 66-yeller {$argv}
    else if test -x (which oblog)
        command oblog {$argv}
    else printf "No 66-yeller/oblog found.\nIt is needed for printing output properly.\nSorry the script can't run\n" && exit 1
    end
end

## The functions "executed" by tmpfiles.d snippets

function f
    _argv_vars $argv
    set -f content "$argv[6]"

    if not test -e "$path"
        touch "$path"
        test "$status" = "0" || set -f RETVAL "$status"
        _chmod "$mode" "$path" "norecurse"
        _chown "$user" "$group" "$path" "norecurse"
        printf "$content" | tee "$path" || set -f RETVAL "$status"
    end

    not test -f "$path" && _wrong_file_format "nooverwrite" || set -f RETVAL "$status"
    not test "$RETVAL" = "0" && set -g _err=1 && oblog "%rIssue%n in file %b$tmpfilesdotdfile%n in line: f {$argv}"
end

function f+
    _argv_vars $argv
    set -f content "$argv[6]"

    if not test -e "$path"
        touch "$path"
        test "$status" = "0" || set -f RETVAL "$status"
        _chmod "$mode" "$path" "norecurse"
        _chown "$user" "$group" "$path" "norecurse"
        printf "$content" | tee "$path" || set -f RETVAL "$status"
    end

    if test -f "$path" && not test "$content" = (cat "$path")
        printf "$content" | tee "$path" || set -f RETVAL "$status"
    end

    not test -f "$path" && _wrong_file_format "nooverwrite" || set -f RETVAL "$status"
    not test "$RETVAL" = "0" && set -g _err=1 && oblog "%rIssue%n in file %b$tmpfilesdotdfile%n line: f+ {$argv}"
end

alias '+f'='f+'

function w
end

function w+
end

alias '+w'='w+'

function d
end

function D
end

function e
end

function v
end

function q
end

function Q
end

function p
end

function p+
end

alias '+p'='p+'

function L
end

function L+
end

alias '+L'='L+'

function L?
end

alias '?L'='L?'

function c
end

function c+
end

alias '+c'='c+'

function b
end

function b+
end

alias '+b'='b+'

function C
end

function C+
end

alias '+C'='C+'

function x
end

function X
end

function r
end

function R
end

function z
end

function Z
end

function t
end

function T
end

function h
end

function H
end

function a
end

function a+
end

alias '+a'='a+'

function A
end

function A+
end

alias '+A'='A+'

## Functions with arbitrary type modifiers;
# Modifiers are '-', '=', '~', '^', '$'
# XXX '^' is NOT SUPPORTED as it is systemd-specific; JUST IGNORED AND ALIASED
# XXX base64-related functions by modifier '~' are LOW PRIORITY

# Usually modifiers just execute the *real* function but
# by checking a condition or by doing a small change,
# internally these modified functions just call the *real* function.
# Some types (functions here) *ignore* the modifiers, they are just aliased to the original.

