# fishtmpfiles
**NOTE:** IT IS NOT YET IN A USABLE STATE; UNDER CONSTRUCTION
An alternate tmpfiles.d parser script written in fish
It uses execl-toc for most of the work,
  and implements the rest internally.
It uses 66-yeller/oblog for output.
It also uses execline components in certain pieces.

# Compatibility
- It only supports f,f+, and 2-3 more identifiers for now...
- No support for cleanup yet; Not even acquiring the files' atimes, mtimes etc...
- No callable command yet, only an internal script...
- Specifiers like `%w` etc...
- `$` (dollar) modifier; It will be interpreted as a variable in fish; Need to solve this somehow.
- (systemd-specific; questonable requirement) No support for `^` (caret) modifier which needs "credentials" concept specific to systemd's PID-1
- (Complex; requirement questionable and not yet found) The `~` modifier which does base64 en-/de-coding of the arguments isn't supported

# Installation
Depends on `66-tools` for `execl-toc` and `66-yeller`.
Also depends on `execline` for certain execline commands.

No `make` or whatever yet...
Not even a simple makeshift installation script...
(Basically the software itself is not in a usable state yet)
So no installation yet...

# Internal machinery
- (Obviously) It is scripted in fish
- The "command" script processes all the arguments passed to it, and sets environment variables accordingly.
- It builds a list of files in the 3 `tmpfiles.d` directories, omitting files of lower precendence if higher precedence files exist.
- It sources the "[TODO]" internal script to define the functions
- It sources the tmpfiles.d files defined in the built-up list one after the another. (Actual work happens here)
- [TODO] It also sources the separate "[TODO]" internal "cleanup" script to clean the directories as per the tmpfiles.d files.
### "parsing" the tmpfiles.d files
- The "command" script calls the "internal" scripts to do the actual work.
- A particular script "[TODO]" defines the identifiers 1st column "Type" as internal executable functions.
- The functions accept arguments from the other "columns".
- Example: A line `f /file/to/create 0770  user group - content` is calling function `f` with the arguments.
- The function will be defined to do as per the tmpfiles.d specification.
- Except modifiers `$`, `^` and  `~`, all combination of modifiers are defined, and aliased to other orders of modifiers; `f!` is an alias to `!f`.
### execl-toc (What does the actual work)
- [execl-toc](https://web.obarun.org/software/66-tools/0.1.1.0/execl-toc/) is a small simple tool which handles various types of files.
- It checks if a file exists, is of the correct permissions, and creates the file, or changes it's permissions, as necessary.
- It supports almost all types like regular files, directories, sockets, fifos, block devices, character devices, symlinks, and many more...
- Basically *every* creation, deletion and modification except automatic timed cleanup is handled by this very tool.
- Some small bits and pieces need to be scripted manually, but are however trivial.
- Of course, the script just "parses" (i.e. "sources") the tmpfiles.d files and calls this `execl-toc` tool to do the actual work.
### Logging and output
- It uses `66-yeller` (AKA `oblog`) for printing messages out.
- `66-yeller` is a capable and featureful tool to print messages out.
- It respects verbosity, etc... via internally-set environment variables.
- It thus makes logging much easier compared to scripting `printf` and `echo` with all the details and verbosity checks etc...
- Sorry, no internal support for special protocols like syslog or the systemd-journal.
- However, you can use `logger` utility in order to log to syslog.
- For systemd, if run as a systemd service, it handles the output into the journal. To redirect output from external calls of the script use `systemd-cat`.
