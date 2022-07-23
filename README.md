# a2vimode
## Introducing a2vimode
Hello, and welcome to **a2vimode**, which installs **vi**-inspired prompt-line editing facilities! Created for HackFest 2022, a part of KansasFest 2022 (an annual Apple ][ conference)

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

An even bigger difference: instead of using the `ESC` key to enter "normal" mode, you should instead use the `TAB` key. Actually, the `ESC` key *will work* if you use it, at least in 40-column mode&mdash;but in 80-column mode it *won't*, because the 80-col firmware intercepts it, and it will likely screw up your prompt's display.

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

There is currently no support for the "delete"(-movement), "change"(-movement), "substitute", or "replace" commands found in **vi**; these are planned as future features. For now, you'll have to make do with just left-arrow/`DEL` and `X`.

### 80-Column
## Why Vi-Like?
## Can I use Vi-Mode with ProDOS?
## Problems and Short-Comings
## How Does It Work?
## Missing Features
