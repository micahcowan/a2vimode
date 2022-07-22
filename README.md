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

Be sure to read the list of commands from the [Usage](#Usage) section.

## Usage

After the routine is installed, whenever a prompt is opened, it begins in "insert" mode. This is a mode for typing characters as input into your prompt. If you never touch the `TAB` (or `ESC`) key, your typing experience will be very similar to what you're already familiar with:

 * As you type, characters are visibly added to your input.
 * If you type the left-arrow (backspace) key, characters are removed from input.
 * Typing the `RETURN` key completes your input line and sends it to the running program.
 * Typing `Ctrl-X` will abandon the current line prompt and start a new one.

Some differences you may notice:
 * When you backspace over a character, it is removed, and is no longer visible.
 * You may also use the `DEL` key to erase characters.
 * If you type a backspace when you are all the way to the left of your line, the cursor just stops there - it does not reprompt on a new line.

### 80-Column
## Why Vi-Like?
## Can I 
## Problems
## How Does It Work?
## Missing Features
