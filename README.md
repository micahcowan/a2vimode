# a2vimode

[**Download the disk image here**](https://github.com/micahcowan/a2vimode/releases/) (be sure to expand the "assets" for a release)<br />
[**Try it out in an online emulator here**](http://micah.cowan.name/apple2js/apple2jse.html#vi-mode) (but *READ THESE INSTRUCTIONS* on how to use!)

[**Click the video below to view**<br />
![a2vimode showcase video](https://img.youtube.com/vi/MnlNq-6Dci4/0.jpg)](https://www.youtube.com/watch?v=MnlNq-6Dci4)

## Introducing a2vimode
Hello, and welcome to **a2vimode**, which installs **vi**-inspired prompt-line editing facilities! Created for [HackFest 2022](https://www.kansasfest.org/hackfest/), a part of KansasFest 2022 (an annual Apple \]\[ conference)

Once the `HELLO` program is run (at startup if you boot from the disk), all text prompts that use the standard firmware prompt routine (DOS, Monitor, BASIC, BASIC Input), will start using vi-mode.

With this software installed, you can:
 * navigate conveniently within the line you are editing
 * insert or delete text in the middle of a line
 * choose between left-arrow/backspace *or* the `DELETE` key for erasing characters
 * undo the last change you made to the input line
 * easily jump to lines of an AppleSoft BASIC program, to edit at the prompt (see [AppleSoft Integration Features](MANUAL.md#AppleSoft-Integration-Features) in the user manual)

You will also currently *lose* this feature from the standard Apple \]\[ prompt:
 * including other on-screen text as part of your input
The [AppleSoft Integration Features (manual)](MANUAL.md#AppleSoft-Integration-Features), and the "retype last line" command (`CONTROL-L`) are intended to shore up (and surpass) that feature for some use cases, but you may still find yourself missing it for some other situations. We apologize for the inconvenience.

## Usage

For instructions on how to use **a2vimode**, please see the
[manual](MANUAL.md)

instructions are *necessary*&mdash;particularly if you've never used
vi-mode, or the **vi** text editor, before.

## Building notes

If you want to modify or build from these sources, you will need tools from the following projects:

  * The ca65 and ld65 tools from [the cc65 project](https://github.com/cc65/cc65)
  * Vince Weaver's [dos33fsprogs](https://github.com/deater/dos33fsprogs)

NOTE: The **dos33fsprogs** project contains *many* different subprojects, most of which are *not needed* to build `fnord.dsk`. The only subdirectories you must build, are `utils/dos33fs-utils`, `utils/prodos-utils`, and `utils/asoft_basic-utils`.

a2vimode's Makefile assumes all of these tools are accessible from the current `PATH` environment variable.

## Problems and Short-Comings

 * The ability to go and grab content off the screen is lost now.
 * ProDOS support is somewhat fragile, as it doesn't currently know how to protect itself properly from BASIC programs running under ProDOS. On DOS, it sets `HIMEM:` to protect itself.
 * 80-column mode on an *unenhanced* Apple \]\[e is somewhat fragile, and occasionally annoying. This is due chiefly to the fact that 80-col `RDKEY` automatically a number of things that the standard firmware doesn't, and I wish it wouldn't. I may resolve these issues by avoiding `RDKEY` in the future, but for now I'm stuck with it.
 * Due to the way **a2vimode** detects and wrests away control from the firmware `GETLN` routine, there is a small-but-not-zero chance of mistaking some values on the stack for return addresses, that aren't, and consequently breaking some function up the call stack.

## How Does It Work?

**a2vimode** looks at the stack to see if its immediate caller, or one just behind, is `RDCHAR` that in turn has been called by `GETLN`. If it sees them, it disables `RDCHAR` with a return to an `RTS` op, and replaces the return to `GETLN` with a return into our own specialized replacement prompter! 😈

## Why Vi-Like?

**Q: "Micah, why on earth did you choose *vi* as the model? Why not use a single mode for moving *and* inserting?**

A: Because it's *my* hackfest project, and having vi-mode in the prompt is more fun for me! 😉 Plus, I hope to eventually add support for vi's `f`, `t`, `,`, and `;` commands (which a surprising number of vi users appear not to know about, but are among my most-used commands!), and using those definitely warrants having a separate movement mode, in my opinion.
