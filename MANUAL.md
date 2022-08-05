# User Manual for a2vimode

## Design Goals

The primary design goals, which are in fact to some degree in conflict:
 1. Be as similar to vi(/vim) controls as practical
 1. Be as capable of working on an Apple \]\[+ as an Apple //e
 1. Be written with 80-column support in mind

Because of the limitations of goal #2, there is one major set of differences between our controls, and those in vi: there are no lowercase controls. You are welcome to type your navigation commands out in lowercase, but they will behave exactly the same as typing capitals. For related reasons, many capital-letter commands you may be accustomed to from **vi**, have the behavior of their *lowercase* equivalent.

An even bigger difference: instead of using the `ESC` key to enter "normal" mode, you should instead use the `TAB` key. Actually, the `ESC` key *will work* if you use it, at least in 40-column mode&mdash;but in 80-column mode on an unenhanced Apple \]\[e it *won't*, because the 80-col firmware intercepts it, and it will likely screw up your prompt's display. The *enhanced* Apple //e and the Apple //c do not suffer this issue.

Be sure to read the list of commands from the [Normal Mode](#normal-mode) section.

## Usage

### Insert Mode

#### Explanation/Description

**Insert mode** is the name for the mode you are already very familiar with on your Apple \]\[ - the mode where you type things and they are entered into and appear at the prompt. After **a2vimode** is installed, whenever a prompt appears, it begins in "insert" mode. If you never touch the `TAB` (or `ESC`) key (which exits **insert** mode in favor of **normal** mode, your typing experience will be very similar to what you're already familiar with:

 * As you type, characters are visibly added to your input.
 * If you type the left-arrow (backspace) key, characters are removed from input.
 * Typing the `RETURN` key completes your input line and sends it to the running program.
 * Typing `CONTROL-X` will abandon the current line prompt and start a new one.

Some differences you may notice:

 * When you backspace over a character, it is removed, and is no longer visible. Thus, you cannot use the right-arrow key to re-insert just-deleted characters.
 * You may also use the `DEL` key to erase characters.
 * If you type a backspace when you are all the way to the left of your line, the cursor just stops there - it does not reprompt on a new line.
 * Some control characters you may be used to typing in insert mode&mdash;notably, `CONTROL-I` and `CONTROL-P`, both of which are used at the prompt in the firmware Monitor program as equivalents to BASIC's `IN#` and `PR#` commands&mdash;do not work as you might expect. When **a2vimode** is active, you must first type `CONTROL-V`, and *then* type the other control character you wish to insert.

And there are a couple of small, additional features:

 * If you type a Control character that would otherwise be invisibly inserted (and which doesn't have a special meaning to **a2vimode**), **vi-mode** *visibly* inserts it, in inverse-video mode. **a2vimode** never inserts a character into the prompt that you can't *see* in some way.
 * If you type `CONTROL-V` and then any character, the second character will be included literally as input (and displayed on the prompt), even if normally it would have special meaning. So, if you were to type `CONTROL-V` `TAB`, it will include a tab character in your input line (displayed as an inverse-video `I`). This feature can also be used in BASIC to insert carriage-return characters inside your `REM` statements!

You can happily spend all of your time in **a2vimode**'s **insert** mode, and never venture forth to explore the power and versatility of **normal** mode - all you have to do is never type `ESC`, `TAB`, or any `CONTROL-` characters without first typing a `CONTROL-V` before them. You may possibly find yourself accidentally in **normal** mode anyway - you'll know because the prompt character (`]` if you're at the AppleSoft or DOS/ProDOS prompt) will become a `-` instead. If you see the `-` in place of the prompt, type `$A` (that's dollar sign, followed by the letter "A") to return to your familiar insert mode, with the cursor placed at the end of input.

#### Special Keys

The following keys lhave special meaning in **insert** mode. Some of them perform an action and  then, if the action is successful, will switch to **normal** mode (indicated in the **final mode** column). If you wanted to avoid **normal** mode, don't panic! You can always just type `$A` to get back to insert mode again. All of these keys, except `CONTROL-V`, *also* work when you type them in **normal** mode. One of them (`CONTROL-A`/"auto-number") has an additional feature that can only be used when in **normal** mode. You never *need* to use them to make use of **insert** mode, but you may find them useful.

A few of these keys are *destructive*&mdash;they will destroy the current input of the line, replacing it with something else. If you type one of these by accident, try typing `TAB` followed by `U$A`. The `TAB` enters **normal** mode, the `U` activates the **undo** feature, and `$A` repositions the cursor at the end of the line, and re-enters **insert** mode.

| Key | Final Mode | Description |
| --- | --- | --- |
| **^V** | insert | (Control-V) Inserts the next character you type literally as input, without interpreting it specially |
| **^A** | insert | (Control-A) "auto-number". Prefixes line numbers at the current and future input lines. Type again to disable. See the section on [AppleSoft Integration Features](#AppleSoft-Integration-Features) |
| **^X** | insert | (Control-X) Cancel. Discards the current line-in-progress and restarts the prompt. (This feature is also present in the standard Apple \]\[ prompt, when **a2vimode** is not installed.) |
| **^Z** | insert | (Control-Z) Prints **a2vimode**'s version number, for informational purposes. |
| --- | --- | --- |
| **^G** | **normal** | (Control-G) "go to". **Destructive**. If the cursor is at a number, it will throw away the current line contents and replace them with the contents of the line whose number is the same as the one your cursor is on (if it exists). Does not work if we're not at the AppleSoft prompt. See the section on [AppleSoft Integration Features](#AppleSoft-Integration-Features). |
| **^N** | **normal** | (Control-N). **Destructive**. Goes to the program line in AppleSoft that comes after the current one. If **Control-G** was never typed, and the current line has no line number at the start of it, does nothing. Does not work if we're not at the AppleSoft prompt. See the section on [AppleSoft Integration Features](#AppleSoft-Integration-Features). |
| **^P** | **normal** | (Control-P). **Destructive**. Goes to the program line in AppleSoft that precedes the current one. If **Control-G** was never typed, and the current line has no line number at the start of it, does nothing. Does not work if we're not at the AppleSoft prompt. See the section on [AppleSoft Integration Features](#AppleSoft-Integration-Features). |
| **^L** | **normal** | (Control-L). **Destructive**. Replaces the current input line with the contents of the last line that was entered (with a final carriage-return). **ProDOS**: lines containing ProDOS commands are *not saved* and cannot be retyped with `CONTROL-L`. |
| **`TAB`<br />`ESC`<br />^I<br />^\[** | **normal** | Leaves **insert** mode and enters **normal** mode. |

### Normal Mode

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
| **F** | **f** | Read a character from the keyboard, and jump to next instance of it in line. See [Jump To Character](#Jump-To-Character) |
| **T** | **t** | Read a character from the keyboard, and jump to *just before* the next instance of it in line. See [Jump To Character](#Jump-To-Character) |
| **#** |       | jump forward to next number on the line. See [AppleSoft Integration Features](#AppleSoft-Integration-Features) and [Jump To Character](#Jump-To-Character) |
| **;** | **;** | repeat jump-to-char or jump-to-number, forward. See [Jump To Character](#Jump-To-Character) |
| **,** | **,** | repeat jump-to-char or jump-to-number, backward. See [Jump To Character](#Jump-To-Character) |
| **I** | **i** | return to insert mode (start typing into input) |
| **A** | **a** | return to insert mode, inserting *after* the current character |
| **^R** | **R** | **replace**/overwrite mode. See [Replace Mode](#Replace-Mode) |
| **[BS]** | **[BS]** | (left-arrow/backspace, or `DEL`) delete back a character |
| **X** | **x** | delete *forward* a character |
| **S** | **s** | delete forward a character, then enter insert mode. ("substitute") |
| **R** | **r** | reads a character from the keyboard, and replaces the current character under the cursor with that character. Has no effect (other than reading a keypress) past the end of the line |
| **0-9** | **0-9** | specify a repeat count&mdash;e.g., `3W` moves forward three words. |
| **D***move* | **d***move* | delete to next movement&mdash;`D2B` deletes backwards two words;<br />`D12L` deletes the next 12 characters (`12X` also works) |
| **C***move* | **c***move* | ("change"-movement). Delete to next movement, then enter insert mode.<br />`CE`: type a replacement for the next word |
| **DD** | **dd** | delete the line, remain in normal mode |
| **CC** | **cc** | delete the line and enter insert mode to begin again |
| **U** | **u** | undo last change. See [Undo](#Undo). |
| **^A** |   | (Control-A) "auto-number". Prefixes line numbers at the current and future input lines. Type again to disable. Also works in insert mode (and remains in insert). See the section on [AppleSoft Integration Features](#AppleSoft-Integration-Features) for additional uses in normal mode. |
| **^G** |   | (Control-G) "go to". **Destructive**. If the cursor is at a number, it will throw away the current line contents and replace them with the contents of the line whose number is the same as the one your cursor is on (if it exists). Also works in insert mode (leaves in normal mode). Does not work if we're not at the AppleSoft prompt. See the section on [AppleSoft Integration Features](#AppleSoft-Integration-Features). |
| **^N** |   | (Control-N). **Destructive**. Goes to the program line in AppleSoft that comes after the current one. If **Control-G** was never typed, and the current line has no line number at the start of it, does nothing. Also works in insert mode (leaves in normal mode). Does not work if we're not at the AppleSoft prompt. See the section on [AppleSoft Integration Features](#AppleSoft-Integration-Features). |
| **^P** |   | (Control-P). **Destructive**. Goes to the program line in AppleSoft that precedes the current one. If **Control-G** was never typed, and the current line has no line number at the start of it, does nothing. Also works in insert mode (leaves in normal mode). Does not work if we're not at the AppleSoft prompt. See the section on [AppleSoft Integration Features](#AppleSoft-Integration-Features). |
| **^L** |   | (Control-L). **Destructive**. Replaces the current input line with the contents of the last line that was entered (with a final carriage-return). Also works in insert mode (leaves in normal mode). **ProDOS**: lines containing ProDOS commands are *not saved* and cannot be retyped with `CONTROL-L`. |
| **^X** |   | (Control-X) Cancel. Discards the current line-in-progress and restarts the prompt. Also works in insert mode. (This feature is also present in the standard Apple \]\[ prompt, when **a2vimode** is not installed.) |
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
