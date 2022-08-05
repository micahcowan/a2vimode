**Insert Mode Special Keys**

The following keys lhave special meaning in **insert** mode. Some of them perform an action and  then, if the action is successful, will switch to **normal** mode (indicated in the **final mode** column). If you wanted to avoid **normal** mode, don't panic! You can always just type `$A` to get back to insert mode again. All of these keys, except `CONTROL-V`, *also* work when you type them in **normal** mode. One of them (`CONTROL-A`/"auto-number") has an additional feature that can only be used when in **normal** mode. You never *need* to use them to make use of **insert** mode, but you may find them useful.

A few of these keys are *destructive*—they will destroy the current input of the line, replacing it with something else. If you type one of these by accident, try typing `TAB` followed by `U$A`. The `TAB` enters **normal** mode, the `U` activates the **undo** feature, and `$A` repositions the cursor at the end of the line, and re-enters **insert** mode.

| Key | Final Mode | Description |
| --- | --- | --- |
| **^V** | insert | (Control-V) Inserts the next character you type literally as input, without interpreting it specially |
| **^A** | insert | (Control-A) "auto-number". Prefixes line numbers at the current and future input lines. Type again to disable. See the section on [AppleSoft Integration Features](#AppleSoft-Integration-Features) |
| **^X** | insert | (Control-X) Cancel. Discards the current line-in-progress and restarts the prompt. (This feature is also present in the standard Apple \]\[ prompt, when **a2vimode** is not installed.) |
| **^Z** | insert | (Control-Z) Prints **a2vimode**'s version number, for informational purposes. |
| --- | --- | --- |
| **^G** | **normal** | (Control-G) "go to". **Destructive**. If the cursor is at a number, it will throw away the current line contents and replace them with the contents of the line whose number is the same as the one your cursor is on (if it exists). Does not work if we're not at the AppleSoft prompt. See the section on [AppleSoft Integration Features](#AppleSoft-Integration-Features). |
| **^N** | **normal** | (Control-N). **Destructive**. Goes to the program line in AppleSoft that comes after the current one, or after the most recently-typed one. If **Control-G** was never typed, and the last-typed line had no line number, does nothing. Does not work if we're not at the AppleSoft prompt. See the section on [AppleSoft Integration Features](#AppleSoft-Integration-Features). |
| **^P** | **normal** | (Control-P). **Destructive**. Goes to the program line in AppleSoft that comes before the current one, or before the most recently-typed one. If **Control-G** was never typed, and the last-typed line had no line number, does nothing. Does not work if we're not at the AppleSoft prompt. See the section on [AppleSoft Integration Features](#AppleSoft-Integration-Features). |
| **^L** | **normal** | (Control-L). **Destructive**. Replaces the current input line with the contents of the last line that was entered (with a final carriage-return). **ProDOS**: lines containing ProDOS commands are *not saved* and cannot be retyped with `CONTROL-L`. |
| **`TAB`<br />`ESC`<br />^I<br />^\[** | **normal** | Leaves **insert** mode and enters **normal** mode. |

**Normal Mode Keys**

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
| **0-9** | **0-9** | specify a repeat count—e.g., `3W` moves forward three words. See [Counted/Repeated Commands](#Counted-RepeatedCommands) |
| **D***move* | **d***move* | delete to next movement—`D2B` deletes backwards two words;<br />`D12L` deletes the next 12 characters (`12X` also works) |
| **C***move* | **c***move* | ("change"-movement). Delete to next movement, then enter insert mode.<br />`CE`: type a replacement for the next word |
| **DD** | **dd** | delete the line, remain in normal mode |
| **CC** | **cc** | delete the line and enter insert mode to begin again |
| **U** | **u** | undo last change. See [Undo](#Undo). |
| **^A** |   | (Control-A) "auto-number". Prefixes line numbers at the current and future input lines. Type again to disable. Also works in insert mode (and remains in insert). If preceded by a number (<256) will advance line numbers by that amount. See the section on [AppleSoft Integration Features](#AppleSoft-Integration-Features). |
| **^G** |   | (Control-G) "go to". **Destructive**. If the cursor is at a number, it will throw away the current line contents and replace them with the contents of the line whose number is the same as the one your cursor is on (if it exists). Also works in insert mode (leaves in normal mode). Does not work if we're not at the AppleSoft prompt. See the section on [AppleSoft Integration Features](#AppleSoft-Integration-Features). |
| **^N** |   | (Control-N). **Destructive**. Goes to the program line in AppleSoft that comes after the current one, or after the most recently-typed line. If **Control-G** was never typed, and the last-typed line had no line number, does nothing. Also works in insert mode (leaves in normal mode). Does not work if we're not at the AppleSoft prompt. See the section on [AppleSoft Integration Features](#AppleSoft-Integration-Features). |
| **^P** |   | (Control-P). **Destructive**. Goes to the program line in AppleSoft that precedes the current one, or precedes the most recently-typed line. If **Control-G** was never typed, and the last-typed line had no line number, does nothing. Also works in insert mode (leaves in normal mode). Does not work if we're not at the AppleSoft prompt. See the section on [AppleSoft Integration Features](#AppleSoft-Integration-Features). |
| **^L** |   | (Control-L). **Destructive**. Replaces the current input line with the contents of the last line that was entered (with a final carriage-return). Also works in insert mode (leaves in normal mode). **ProDOS**: lines containing ProDOS commands are *not saved* and cannot be retyped with `CONTROL-L`. |
| **^X** |   | (Control-X) Cancel. Discards the current line-in-progress and restarts the prompt. Also works in insert mode. (This feature is also present in the standard Apple \]\[ prompt, when **a2vimode** is not installed.) |
| **^Z** |      | (Control-Z) displays **a2vimode**'s version string. Also works when in insert mode. |
| **C** | **C$** | re-type rest of the line |
| **S** | **CC** | re-type the line from scratch |
| **A** | **$A** | insert at the end of the line |
