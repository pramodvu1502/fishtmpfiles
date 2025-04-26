## Personal note from the author
The *correct* way of preparing runtime directories for most services is in the service's startup script itself.
And cleaning it up in the post-stop script itself. NOT in a separate daemon like `systemd-tmpfiles`.
(I don't mean "horrible shell script" when I say "script". Neither do I mean "sysVinit" which is BTW actually "van smoorenburg rc initscripts" and sysVinit is something else.
  Things like `66-tools` (specifically `execl-toc`) and `execline` actually exist. Even `setpriv` is an actual tool. And don't forget systemd's flagship security/sandboxing features which are available in `66-ns` and `unshare`. CGroups though, is not yet fully capitalized/exploited elsewhere.
  And yes, service management suites like `66` already support and use all of this unerneath a systemd-like declarative format.)

- Well, things like `/etc/os-release` always being a specific symlink,
  is something the unknowing won't touch, and the knowing will override by `tmpfiles.d` itself.
- You want to ensure that `/var/spool/cron` and `/var/spool/cron/crontabs` have the *correct* permissions?
  It must be done in the cron daemon's pre-start script (or a common script for all daemons).
- The daemon running under a restricted user needs to create the directory *before* dropping it's root privs.
- `execl-toc -d /run/daemon-runtime.d -m 0644 -u daemon-user -g daemon-group setpriv --reuid daemon-user --regid daemon-group env ENV_VARS="your-value" /usr/bin/my-daemon`
- The above *single* command handles what `tmpfiles.d` is supposed to do, drops the priveleges, and runs the daemon.
- What else? The X11 files? Clearing is done as `/tmp` is cleared anyways; Creating can be done by a single simple boot-time script meant for it.
- `/run` must *always* be populated by `cp -Ra`'ing  a `/{usr/lib,etc}/run-image` directory to `/run`.
- `/var/tmp` is another unnecessary figment. `/var/{lib,cache}` are meant for cache and state and `/tmp` for volatile cache and state meant to be cleared.
- Moreover, things like flatpak, if they want to clear their `/var/tmp/flatpak-cache-*`, need to do that via a bootscript or an internal script called by flatpak-system-helper itself.
- `/run` is a "clean" runtime filesystem, so are `/run/user/${UID}` directories.
  They shouldn't be "cleaned" at timed intervals, rather at certain events like service start-stop, or boot/logout/poweroff.
- `podman`, `ostree` etc.. need pre-created runtime dirs; Use the `run-image` for that!
- HomeDirs in `/var` for SDDM etc... need to be created in package's post-install!
- And a lot more.

### systemd
- systemd is the most extensive user, as it needs to symlink some files from `/usr/lib/systemd` into `/etc/config-dirs`, rather than just shipping them in-package into the right directories.
- This is really bad, as it
    1. Circumvents the user's edits and the package manager's management of configuration file overwrites.
    2. Keeps everything in `/usr/lib/systemd`, and the files are subject to `/usr` handling rather than `/etc` handling.
    3. Basically, some profile snippets to be sourced by your shell, and some SSH configs. You know the consequence of unintended configuration in there. See (1.) for why it's a bigger issue here.
- Also, it makes sure that it's journal logfiles are not CoW'd or whatever, as it's binary format is imperformant.
- Makes sure that the D-Bus machine-id is symlinked to the *global* machine-id. This is the work of D-Bus's pre-start.
- Some random unneeded empty directories (Meant for configuration precedence, but why? They are empty); Like `/run/cryptsetup`
- Making sure some files and directories exist, BUT this is meant to be done by the firstboot program! AND nobody will unwilingly delete just that. (`rm -rf /` will remove even the tmpfiles.d files)
- "Cleaning" `/run` and equivalent "runtime" directories, which shouldn't at all be cluttered at the 1st place. (And exclusions to prevent issues)
- Making sure random directories are of correct permissions; What are package managers for?
- Static device nodes; Handle them in 1 singular script! OR let `devtmpfs` do it.
- Excluding systemd's own tmpfiles.
- And much more

### TL;DR
`tmpfiles.d` is useless, and it's functionality is insignificantly small. Can be done in simpler ways.

systemd, well, is "better than sysVinit horrible shell scripts", and is horrible in it's own way...
`execline`, `66-tools`, `setpriv` (IN `util-linux`), `execl-toc`, `unshare`, `nsenter`, `66-ns`,
  a simple declarative format elsewhere (optionally supporting a mini-script rather than 100 pre-start commands; without much overhead), nothing exist(s).
  Only systemd and sysVinit. systemd is thus the best, it's better than sysVinit. (other suites are out of question;)

Thus `tmpfiles.d`; a full oneshot daemon, is needed for what is not even a separately discrenible task of managing a few files here and there.
It also misuses it to override and force configuration files, including ssh config snippets and shell profile snippets.

(sysVinit is the PID-1, the "init", "service management", etc.. are done by "van smoorenburg rc scripts". *They* are the horrible clunky scripts; sysVinit supported optional supervision but was only ever used for gettys as everything had to go into a single large file `/etc/inittab` to use it)

I am writing `fishtmpfiles` *only* because `systemd-tmpfiles` decides not to run because I have `/` mounted in a non-systemd way.
It will *never* be completed I think, as it is easy to workaround and just use the small bits and pieces of systemd.
It was started just for the purpose of shimming `systemd-tmpfiles` while bootstrapping gentoo, where mounts when not the way systemd likes, will fail `systemd-tmpfiles` and the many small important file-creation tasks.
It might never support cleanup and the other long-term-usable features... (Will it even get past a small incomplete unusable parser script and "personal note"s?)

I have other priorities, sorry, I might not be able to cmplete this to a remotely usable state.
My priorities include: `66`, `66-dbus-launch`, many frontends for it for use in gentoo and alpine.

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
