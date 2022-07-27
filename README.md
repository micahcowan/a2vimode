# a2vimode

[**Download the disk image here**](https://github.com/micahcowan/a2vimode/releases/) (be sure to expand the "assets" for a release)<br />
[**Try it out in an online emulator here**](http://micah.cowan.name/apple2js/apple2jse.html#vi-mode) (but *READ THESE INSTRUCTIONS* on how to use!)

[**Click the video below to view**<br />
![AppleSoft Autorun ROM Maker shwocase video](https://img.youtube.com/vi/MnlNq-6Dci4/0.jpg)](https://www.youtube.com/watch?v=MnlNq-6Dci4)

## Introducing a2vimode
Hello, and welcome to **a2vimode**, which installs **vi**-inspired prompt-line editing facilities! Created for [HackFest 2022](https://www.kansasfest.org/hackfest/), a part of KansasFest 2022 (an annual Apple \]\[ conference)

Once the `HELLO` program is run (at startup if you boot from the disk), all text prompts that use the standard firmware prompt routine (DOS, Monitor, BASIC, BASIC Input), will start using vi-mode.

With this routine installed, you can:
 * navigate conveniently within the line you are editing
 * insert or delete text in the middle of a line
 * choose between left-arrow/backspace *or* the `DELETE` key for erasing characters.

At the moment, you will also currently give up:
 * including other on-screen text as part of your input
But we hope to add this feature back at some point.

## Design Goals
The primary design goals, which are in fact to some degree in conflict:
 1. Be as similar to vi(/vim) controls as practical
 1. Be as capable of working on an Apple ][+ as an Apple //e
 1. Be written with 80-column support in mind

Because of the limitations of goal #2, there is one major set of differences between our controls, and those in vi: there are no lowercase controls. You are welcome to type your navigation commands out in lowercase, but they will behave exactly the same as typing capitals. For related reasons, many capital-letter commands you may be accustomed to from **vi**, have the behavior of their *lowercase* equivalent.

An even bigger difference: instead of using the `ESC` key to enter "normal" mode, you should instead use the `TAB` key. Actually, the `ESC` key *will work* if you use it, at least in 40-column mode&mdash;but in 80-column mode on an unehnahced Apple \]\[e it *won't*, because the 80-col firmware intercepts it, and it will likely screw up your prompt's display. The *enhanced* Apple //e and the Apple //c do not suffer this issue.

Be sure to read the list of commands from the [Normal Mode](#normal-mode) section.

## Usage

### Insert Mode

After the routine is installed, whenever a prompt is opened, it begins in "insert" mode. This is a mode for typing characters as input into your prompt. If you never touch the `TAB` (or `ESC`) key, your typing experience will be very similar to what you're already familiar with:

 * As you type, characters are visibly added to your input.
 * If you type the left-arrow (backspace) key, characters are removed from input.
 * Typing the `RETURN` key completes your input line and sends it to the running program.
 * Typing `CONTROL-X` will abandon the current line prompt and start a new one.

Some differences you may notice:

 * When you backspace over a character, it is removed, and is no longer visible. Thus, you cannot use the right-arrow key to re-insert just-deleted characters.
 * You may also use the `DEL` key to erase characters.
 * If you type a backspace when you are all the way to the left of your line, the cursor just stops there - it does not reprompt on a new line.

And there are a couple of small, additional features:

 * If you type a Control character that would otherwise be invisibly inserted, **vi-mode** *visibly* inserts it, in inverse-video mode. So, if you are in the monitor and type (e.g.) `6` `CONTROL-P`, you will see the `CONTROL-P` as an inversed-color `P`, visible on the screen.
 * If you type `CONTROL-V` and then any character, the second character will be included literally as input (and displayed on the prompt), even if normally it would have special meaning. So, if you were to type `CONTROL-V` `TAB`, it will include a tab character in your input line (displayed as an inverse-video `I`). This feature can also be used in BASIC to insert carriage-return characters inside your `REM` statements!

## Normal Mode

Normal mode is mainly used for navigating around the line&mdash;going forward and backward by characters or words, or to the beginning or end of the input line, so that you can enter new text mid-line, or delete some bits you don't want.

(Why is it called *normal* mode if the prompt *normally* starts in *input* mode? Because in **vi** it *is* the normal mode, and is called that, and while for our purposes it might be more accurate to call it "command mode" or "movement mode", "normal mode" is still what I expect is the least-confusing way to refer to it.) 🙂

Within Normal Mode, typing a key does *not* insert the corresponding character. To go back to inserting things, you must go back to insert mode by typing the `I` key (which will not be entered); and then you can go back to typing things in as input.

In Normal Mode, the following keys have meaning:
| Key | ~ vi key |  Action |
| --- | --- | --- |
| **H** | **h** | move left one char |
| **L** | **l** | move right one char |
| **W** | **w** | move forward to the start of the next word |
| **E** | **e** | move forward to the end of this or the next word |
| **B** | **b** | move back to the start of this or a previous word |
| **0** | **0** | move to the beginning of input |
| **^** | **^** | move to the first "word character" at the beginning of input |
| **$** | **$** | move to past the end of input |
| **I** | **i** | return to insert mode (start typing into input) |
| **A** | **a** | return to insert mode, inserting *after* the current character |
| **[BS]** | **[BS]** | (left-arrow/backspace, or `DEL`) delete back a character |
| **X** | **x** | delete *forward* a character |
| **S** | **s** | delete forward a character, then enter insert mode. ("substitute") |
| **0-9** | **0-9** | specify a repeat count&mdash;e.g., `3W` moves forward three words. |
| **D***move* | **d***move* | delete to next movement&mdash;`D2B` deletes backwards two words;<br />`D12L` deletes the next 12 characters (`12X` also works) |
| **C***move* | **c***move* | ("change"-movement). Delete to next movement, then enter insert mode.<br />`CE`: type a replacement for the next word |
| **DD** | **dd** | delete the line, remain in normal mode |
| **CC** | **cc** | delete the line and enter insert mode to begin again |
| **^Z** |      | (Control-Z) displays **a2vimode**'s version string. Also works when in insert mode. |

The following common **vi** commands are not available in **a2vimode**, but have available equivalents:

| vi | use instead | explanation |
| --- | --- | --- |
| **D** | **D$** | delete rest of the line
| **C** | **C$** | re-type rest of the line |
| **S** | **CC** | re-type the line from scratch |
| **A** | **$A** | insert at the end of the line |

## Disabling Vi-Mode

To disable **vi-mode**, run `IN#0`.

## 80-Column

**NOTE: at the moment, 80-column mode does not work under ProDOS. It isn't fantastic under DOS either, if you're using specifically the unenhanced Apple \]\[e, but should work provided you follow the instructions below closely. Enhanced Apple //e appears to work better.**

To use vi-mode in 80-column mode, first start 80-column mode with `PR#3`, and then `RUN HELLO` to reconnect **vi-mode**. Do not run the `HELLO` program multiple times with 80-column firmware active - if you want to reboot **vi-mode**, do another `PR#3` followed by `RUN HELLO`.

And don't touch the `ESC` key! Use `TAB` to enter normal mode.

## Why Vi-Like?

**Q: "Micah, why on earth did you choose *vi* as the model? Why not use a single mode for moving *and* inserting?**

A: Because it's *my* hackfest project, and having vi-mode in the prompt is more fun for me! 😉 Plus, I hope to eventually add support for vi's `f`, `t`, `,`, and `;` commands (which a surprising number of vi users appear not to know about, but are among my most-used commands!), and using those definitely warrants having a separate movement mode, in my opinion.

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
