# User Manual for a2vimode

## Introduction

Welcome to **a2vimode**! This software replaces the standard input prompt (called `GetLn` or `GETLN` in source listings of the Apple \]\[ firmware), with a version that offers full, advanced line-editing features, along with conveniences for navigating and coding in AppleSoft.

Its keybindings and featureset are based on the "vi-mode" keybindings available in **bash** and other Bourne shells (support for **set -o vi** is in fact mandated for **sh** by the POSIX standard), which of course are in turn based on the Unix editor known as **vi**.

Often, users find themselves confused or taken aback by **vi**'s "modal editing" paradigm—wherein **vi** separates editing into modes such as **insert**, where typing characters inserts them into the line being input, and so-called **normal** mode, where ordinary key characters like **w** and **h** are used, not to insert themselves as text, but to navigate within the line, or even to make multiple-character deletions or changes to the line. This modal-editing style is unfamiliar to those whoa re accustomed to editors *always* being in "insert" mode, so that typing an **a** virtually always results in an **a** being inserted into the typed line.

But **vi**'s modal editing feature offers some distinct advantages to making the same keys mean the same thing at all times:
 - Because **normal** mode provides an opportunity to use ordinary keys to perform special commands, traditional **vi** (and a shell's vi-mode) tends to avoid the use of key modifiers (like *control-*, *alt-*, or *meta-*) to invoke special functions. This means less stretching-your-fingers to hold down a key with one finger while striking another with another.
 - Since key modifiers are seldom involved, it makes it easier to "chain" commands into each other. For instance, in **vi**'s **normal** mode, the **d** key is used to **d**elete something. But *what* it is that you're deleting is left open, until you chain that **d** into a command that moves the cursor—then the **d** command will delete everything between where the cursor was at the start, to where it moved to in the (sub)command. Command-chaining looks like this: you can type a `w` to move the cursor to the beginning of the next word. You can type `3w` to advance the cursor by *three* word starts. And you can type `d3w` to *delete* to three words ahead.
 - With two keypresses, you can set up the **;** and **,** keys to jump around to the next or previous occurrance of any arbitrary character. In **bash**, this is especially useful for jumping between slash (`/`) characters in a lengthy filepath (this is the main reason why **a2vimode**'s author prefers to use **vi**-mode in his Unix shells); in **a2vimode** it is handy for jumping around to different `,`-separated fields of a `DATA` statement, for different `:`-separate statements on a long line, and (in combination with **d** or **c**) for quickly deleting the space between two double-quote (`"`) characters of a string. See the [Jump-to-Char](#jump-to-char) section for examples and usage information for these commands.

## Design Goals/Differences From Vi

The primary design goals, which are in fact to some degree in conflict:
 1. Be as similar to vi(/vim) controls as practical—or more precisely, to the vi-mode controls in **bash** and other Bourne shells that offer it.
 1. Be as capable of working on an Apple \]\[+ as an Apple //e.
 1. Be written with 80-column support in mind.
 1. Potentially destructive commands should be control-keys, to reduce chances of accidental invocation.

Because of the limitations of goal #2, there is one major set of differences between our controls, and those in vi: there are no lowercase controls. You are welcome to type your navigation commands out in lowercase, but they will behave exactly the same as typing capitals. For related reasons, the majority of  commands you may be accustomed to from **vi** that are expressed by *lowercase letters*, instead use *either* case in **a2vimode**. Many of those keys have, in **vi**, related keys that do slightly different things when expressed in uppercase; in **a2vimode** these modified versions of the commands either don't exist, or use a different key to activate (for instance, the "replace-mode" command in **vi** uses **R**; but in **a2vimode**, `CONTROL-R` is used instead).

An even bigger difference: instead of using the `ESC` key to enter "normal" mode, you should instead use the `TAB` key. Actually, the `ESC` key *will work* if you use it, at least in 40-column mode—but in 80-column mode on an unenhanced Apple \]\[e it *won't*, because the 80-col firmware intercepts it, and it will likely screw up your prompt's display. The *enhanced* Apple //e and the Apple //c do not suffer this issue.

Goal #4 is why `CONTROL-N` and `CONTROL-P` are used to traverse lines of BASIC, instead of `j` and `k`, which would be natural to **vi**. Because of limited memory, **a2vimode** does not maintain buffers that hold editing history, apart from an undeo buffer, and the last line that was completed. So it is not possible to edit a line of BASIC, and traverse upwards to see a different line of BASIC, and then return to the line that was being edited to continue as it was: traversing lines of BASIC *destroys* the line currently being edited, and so activating those commands via `j` and `k` would be inappropriate—*particularly* when their neighboring keys `h` and `l` are used very frequently, to move forward and back by a single character.

Be sure to read the list of commands from the [Normal Mode](#normal-mode) section.

## Insert Mode

### Explanation/Description

**Insert mode** is the name for the mode you are already very familiar with on your Apple \]\[ - the mode where you type things and they are entered into and appear at the prompt. After **a2vimode** is installed, whenever a prompt appears, it begins in "insert" mode. If you never touch the `TAB` (or `ESC`) key (which exits **insert** mode in favor of **normal** mode, your typing experience will be very similar to what you're already familiar with:

 * As you type, characters are visibly added to your input.
 * If you type the left-arrow (backspace) key, characters are removed from input.
 * Typing the `RETURN` key completes your input line and sends it to the running program.
 * Typing `CONTROL-X` will abandon the current line prompt and start a new one.

Some differences you may notice:

 * When you backspace over a character, it is removed, and is no longer visible. Thus, you cannot use the right-arrow key to re-insert just-deleted characters.
 * You may also use the `DEL` key to erase characters.
 * If you type a backspace when you are all the way to the left of your line, the cursor just stops there - it does not reprompt on a new line.
 * Some control characters you may be used to typing in insert mode—notably, `CONTROL-I` and `CONTROL-P`, both of which are used at the prompt in the firmware Monitor program as equivalents to BASIC's `IN#` and `PR#` commands—do not work as you might expect. When **a2vimode** is active, you must first type `CONTROL-V`, and *then* type the other control character you wish to insert.

And there are a couple of small, additional features:

 * If you type a Control character that would otherwise be invisibly inserted (and which doesn't have a special meaning to **a2vimode**), **vi-mode** *visibly* inserts it, in inverse-video mode. **a2vimode** never inserts a character into the prompt that you can't *see* in some way.
 * If you type `CONTROL-V` and then any character, the second character will be included literally as input (and displayed on the prompt), even if normally it would have special meaning. So, if you were to type `CONTROL-V` `TAB`, it will include a tab character in your input line (displayed as an inverse-video `I`). This feature can also be used in BASIC to insert carriage-return characters inside your `REM` statements!

You can happily spend all of your time in **a2vimode**'s **insert** mode, and never venture forth to explore the power and versatility of **normal** mode - all you have to do is never type `ESC`, `TAB`, or any `CONTROL-` characters without first typing a `CONTROL-V` before them. You may possibly find yourself accidentally in **normal** mode anyway - you'll know because the prompt character (`]` if you're at the AppleSoft or DOS/ProDOS prompt) will become a `-` instead. If you see the `-` in place of the prompt, type `$A` (that's dollar sign, followed by the letter "A") to return to your familiar insert mode, with the cursor placed at the end of input.

**NOTE:** This "prompt-character iransformation" does not take place in all situations, because not all prompts have a "prompt character". AppleSoft's "direct mode" uses `]`, and the Monitor uses `*`. But a BASIC program, for example, does not use a "prompt character" for the `INPUT` command. It might *look* like it does, because most of the time the prompt will begin with a `?`, and if you type input that isn't accepted, it'll re-prompt with another `?`. But programatically, `INPUT` sets the prompt character to "empty". One way you can tell the difference is to type `CONTROL-X`: if you see a prompt character again on the next line after a `CONTROL-X`, that's a "real" prompt character. With `INPUT`, you get nothing there. Anyway, in situations like that, **a2vimode** won't replace the prompt character with a temporary `-`, because it can't tell whether there's a character that's appropriate to replace like that.

### Special Keys

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

## Normal Mode

### Intro to Normal Mode

Normal mode is mainly used for navigating around the line—going forward and backward by characters or words, or to the beginning or end of the input line, so that you can enter new text mid-line, or delete some bits you don't want.

(Why is it called *normal* mode if the prompt *normally* starts in *input* mode? Because in **vi** it *is* the normal mode, and is called that, and while for our purposes it might be more accurate to call it "command mode" or "movement mode", "normal mode" is still what I expect is the least-confusing way to refer to it.) 🙂

Within Normal Mode, typing a key does *not* insert the corresponding character. To go back to inserting things, you must go back to insert mode by typing the `I` key (which will not be entered); and then you can go back to typing things in as input.

### Special Keys

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
| **F** | **f** | Read a character from the keyboard, and jump to next instance of it in line. See [Jump-To-Char](#jump-to-char) |
| **T** | **t** | Read a character from the keyboard, and jump to *just before* the next instance of it in line. See [Jump-To-Char](#jump-to-char) |
| **#** |       | jump forward to next number on the line. See [AppleSoft Integration Features](#AppleSoft-Integration-Features) and [Jump-To-Char](#jump-to-char) |
| **;** | **;** | repeat jump-to-char or jump-to-number, forward. See [Jump-To-Char](#jump-to-char) |
| **,** | **,** | repeat jump-to-char or jump-to-number, backward. See [Jump-To-Char](#jump-to-char) |
| **I** | **i** | return to insert mode (start typing into input) |
| **A** | **a** | return to insert mode, inserting *after* the current character |
| **^R** | **R** | **replace**/overwrite mode. See [Replace Mode](#replace-mode) |
| **[BS]** | **[BS]** | (left-arrow/backspace, or `DEL`) delete back a character |
| **X** | **x** | delete *forward* a character |
| **S** | **s** | delete forward a character, then enter insert mode. ("substitute") |
| **R** | **r** | reads a character from the keyboard, and replaces the current character under the cursor with that character. Has no effect (other than reading a keypress) past the end of the line |
| **0-9** | **0-9** | specify a repeat count—e.g., `3W` moves forward three words. See [Counted/Repeated Commands](#countedrepeated-commands) |
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

The following common **vi** commands are not available in **a2vimode**, but have available equivalents:

| vi | use instead | explanation |
| --- | --- | --- |
| **D** | **D$** | delete rest of the line
| **C** | **C$** | re-type rest of the line |
| **S** | **CC** | re-type the line from scratch |
| **A** | **$A** | insert at the end of the line |

## Moving Around in a Line

To move around in the line you're editing (perhaps to start inserting your typing somewhere else, or to fix a typo), you must enter **normal** mode, by pressing `TAB` (or `ESC`, but that is *not recommended* on an unenhanced Apple //e with the 80-column firmware active due to some... "interesting" input firmware differences). You will (in most situations) see the prompt character change to a `-` while in **normal** mode, as a clue that any key you type will not be inserted, but instead perform some special function (if one is assigned to that key).

Once in **normal** mode, you can use the `H` and `L` keys to move backward or forward by one character. If you're not feeling very adventurous and don't wish to learn more about some of the very cool features available within **normal** mode, this information, together with the knowledge that typing the `I` key will return you to **insert** mode to continue typing things into the line, should really be more than enough to get going.

Other movement keys include `W`, which jumps forward to the next start of a **w**ord (in **a2vimode**, a "word" is any contiguous string of text that is made up of letters or numbers), `B` to jump *backward* to the nearest preceding beginning of a word (which might be beginning of the current word, if the cursor is in one), and `E` to jump forward to the nearest *end* of a word. You can use `0` to jump the cursor to the beginning of the line, and `$` to jump to the end of the line. `^` will jump to the first start of a word in the line (skipping over any leading spaces, or punctuation).

## Delete/Change

The **a2vimode** prompt uses the `D` or `C` keys to perform most deletions. The `D` key stands for **d**elete, while the `C` key stands for **c**hange. On their own, they do not specify *what* will be changed; you must follow those keys with a movement key (see the previous section). For instance, `DL` will delete one character forward, and `DW` will delete all text between the cursor, and the start of the next word.

The `C` key works the same as the `D` key, but instead of **d**eleting, it **c**hanges (by deleting, and then entering **insert** mode to type a replacement to whatever was removed. Generally speaking, `C`*move* is equivalent to `D`*move*`I`. It saves a keystroke.

See the next section for a way to get even more power out of the `C` and `D` commands.

## Counted/Repeated Commands

Most (but not all) commands can be repeated multiple times, by typing a number before typing the key for that command.

For example, typing a `W` will move forward by one word; typing `3W` will move forward by three words. Typing `H` will move back by one letter; typing `6H` will move back six letters. `D2B` will delete the preceding two words (as will the equivalent `2DB`.

You can even repeat inserts! If you type `3A` in normal mode, you will move one character forward and enter insert mode (because that's what `A` does). If you then type a `SPACE`, the word `HELLO`, and then type the `TAB` (or `ESC`) key to return to normal mode, it will add two more ` HELLO` words right after the first one (making three total, as requested)!

It will also work in AppleSoft editing with the `CONTROL-P` and `CONTROL-N` commands: Typing `5` before a `CONTROL-P` will edit the program line that's five lines back from the "current" one. (See [AppleSoft Integration Features](#AppleSoft-Integration-Features) for how to use `CONTROL-N` and `CONTROL-P`.)

Note: a single, 8-bit byte is used to track the repeat-count prefix. So, if you type a number that's greater than 255 (say, 300), the repeat counter will overflow, and the actual number of repeats will not be the number that was requested. Please stick to repeat-count prefixes that are less than or equal to 255.

Finally, a "repeat count" before the `CONTROL-A` ("autonumber") command has a special (non-repeat) meaning: it adjusts any current and future auto-incremented line numbers to increment by the specified repeat count. See [AppleSoft Integration Features](#AppleSoft-Integration-Features) for details.

There is no prompt indication to indicate that a repeat-count is in process. So, if you accidentally type a `3` before entering insert mode with `I`, then when you're done typing and return to normal mode, you may be surprised to find your insertion has been repeated! If this occurs, don't panic, just type the `U` (undo) command and type it again. If you suspect you may have typed a digit by accident before a command that you don't want to repeat, you should try typing `TAB` (or `ESC` a few times (harmless when you're already in normal mode) to cancel any repeat count.

Not every command can be repeated. For instance, `CONTROL-Z`, which prints the **a2vimode** versino number, cannot. Nor can `CONTROL-R`, for **replace** (overwrite) mode, despite its similarities to **insert** mode. Nor `U`, "undo". As a general rule of thumb, if the concept of "repeating" a command doesn't make much chance, it probably doesn't accept a repeat count.

## Undo

**a2vimode** supports a single level of undo. If you type `U` in normal mode, it will restore the state of the input buffer from before whatever last change you just made. Which includes an undo - so the "redo" command is the same as "undo": just type `U`.

Now for more detail on what is considered a "single" change. First, if you're in **insert** mode, this entire insertion section up until you type `TAB` (or `ESC`) to enter **normal** mode, will generally be considered a single change. The main exception is that if you use a special key like `CONTROL-G` to load a line from the current AppleSoft program, or `CONTROL-L` to replace the line with the last one that was typed, the current state of input is "saved" for a later undo just prior to executing those commands.

A "save" is performed before a `CONTROL-G`, but *not* before a subsequent `CONTROL-P` (previous BASIC line) or `CONTROL-N` (next BASIC line). If you type `CONTROL-P` or `CONTROL-N` *without* having typed a `CONTROL-G` yet on that prompt, it will "save" before those, but not on subsequent ones. The general idea is that `U` should "undo" to the state the line was in before the user started navigating around to &amp; editing different lines in BASIC.

A count-repeated command is generally a "single" change. If you type the backspace key 5 times, and then in normal mode type a `U`, only the final backspace will be undone, leaving the previous four deleted single characters permanently gone. *However*, if instead of typing backspace five times, you instead type `5` before a single press of backspace (in **normal** mode), then pressing the `U` key to undo the change will undo all 5 backspaces (since they were performed as part of a single repeated-command form). Similarly, if you type `DW`, and then another `DW` in normal mode, **undo** will only undo the most recently-deleted word, while `D2W` (or `2DW`) performs a two-word deletion that can be undone completely.

## Retype Last Line

If you type `CONTROL-L` in either insert or normal mode, the current input line is discarded, and replaced by the last line you entered (but you can undo this change with `U` in normal mode, provided you don't make other intervening changes).

Of course, `CONTROL-L` can *not* restore a line that had been typed *before* **a2vimode** was activated. The line will be blanked in that event.

**WARNING:** In ProDOS, `CONTROL-L` can *not* restore any line that was recognized as a ProDOS command. This is because, when a user presses the `RETURN` key, ProDOS intercepts it, processes the command, and obliterates the line (sometimes filling it with other things before erasing again) before **a2vimode** even gets to see the keypress! This leaves us with no means to save that line aside. ProDOS does not do this with AppleSoft commands. Apple DOS does not suffer from this defect (Apple DOS *also* siezes the line from us, but it does so after *we* emit the carriage return back out to the screen, so we've had a chance to process the input line by then!).

## AppleSoft Integration Features

This software contains a few features that are only available for use when the prompt is recognized as the direct AppleSoft command prompt (where commands, and lines of BASIC code, may be entered):

 - You can [summon any line of the BASIC program](#summoning-basic-lines) to be viewed or edited at the prompt.
 - You can [traverse forward or backward](#traversing-basic), a line at a time, through the BASIC program.
 - You can activate, deactivate, and adjust [auto-incremented line numbers](#auto-incremented-line-numbers).

**NOTE:** Use of these features may expose **a2vimode** to a greater risk of crashing. If the internal structure of the BASIC program listing is corrupted or compromised, using the line-summoning or traversing features could wind up reading arbitrary locations in memory and trying to interpret them inappropriately (of course, the same results would occur by running the AppleSoft `LIST` command as well). In theory, there may also be some risk of the auto-incremented lines feature trigging a math overflow or other error, which would crash and disable **a2vimode**, requiring you to run it again to restore your vi-mode prompt. It is also possible to corrupt or manipulate BASIC's line storage in such a way as to cause **a2vimode** to enter an infinite loop as it tries to summon a line (you can break out with `CONTROL-RESET`, and **a2vimode** would then need to be run again).

### Summoning BASIC lines

To bring a BASIC line into the prompt for editing, just type the desired line number and then `CONTROL-G`. `CONTROL-G` (in both normal and insert mode) will travel to the BASIC line whose number is at or lies immediately before the cursor's current position. If **insert** mode was active, you will be switched to **normal** mode for easier navigation within the line.

Another movement mechanic was designed specifically to pair with this line-summoning feature: if you type the `#` key (in **normal** mode), the cursor will jump forward to the start of the next number within the line. You can then use the `,` key to jump backward to a previous number, and either the `#` key *or* the `;` key to jump forward.

For instance, if you type `100` `CONTROL-G` while in insert mode, it might call up a line like:
```
 ] 100 IF A<>10 THEN GOSUB 500:GOTO 30
```
If the cursor is at the start of the line (on the `1` of the line number `100`), then if you type `#` (you are now in **normal** mode, after summoning the line), the cursor will move to the `10` of `A<>10`. If you type it again, or `;`, then the cursor will move to the `500` of `GOSUB 500`. You could then type `CONTROL-G` again, and the line would again be replaced by a line from the BASIC program; this time, line 500.

If the cursor were at the end of the line, you would still type a `#`. However, the cursor would not hove for this first `#`, because that is a forward-moving command. But if you then follow up by typing `,`. the cursor will move back to the previous start-of-a-number (one or two characters, to the `3` of `GOTO 30`). Typing `,` once more would bring it to the `500` of `GOSUB 500` once more.

If you were to type `CONTROL-G` while the cursor is located at the `10` of `A<>10`, **a2vimode** would *still* attempt to summon line 10 of the program, even though in this context it does not represent a line number. **a2vimode** does not process the syntax of the line in any way—it only recognizes whether or not it is at a number.

**Note:** the `;` and `,` keys have a general meaning of "continue jumping to the thing that was asked for"; when preveded by other commands besides `#` (`T` or `F`), they will jump around to whatever character was specified, and not arbitrary numbers. See the [Jump-To-Char](#jump-to-char) section for more information.

You may wonder why `CONTROL-G` uses actual input in the line, instead of [the "repeat" counter](#countedrepeated-commands), like the autoincrement `CONTROL-A` feature does. Well, one of the reasons is so that you can use the trick we just described with `#`, `;`, and `,`, to choose a new line from a `GOTO` or a `GOSUB`. Another reason is that the command-repeat counter is not *visible* as it is typed, and for a line number it seems worthwhile to see where we are jmping to. Yet another reason is because the repeat counter currently can only be used with numbers whose values are less than 256, and line numbers are frequently much higher than that.

### Traversing BASIC

The `CONTROL-N` and `CONTROL-P` keys are used to move forward or backward through lines of the current BASIC program. If a line of BASIC was summoned to the current prompt, then they will move relative to the summoned line.

If no line was summoned yet into the current prompt, then **a2vimode** will check to see if the last line you typed started with a line number. If it did, then `CONTROL-P` will summon that line back to the prompt, and `CONTROL-N` will summon the line that follows it in the program listing (if there is one).

### Auto-Incremented Line Numbers

If you type `CONTROL-A` (in either mode), a line number will be inserted at the start of the line. By default, the first line number generated would be 10, and then each successive line would be increased by ten.

Each line number is generated based on the last line number that **a2vimode** saw at the start of a line that the user entered at the main AppleSoft prompt. So, if the auto-increment generates a line starting with the number 220, and you delete that number and rewrite it to 512, and then type out the rest of your line followed by `RETURN`, the next prompt will give you a line beginning with line number 520. This example also serves to point out that each new line number is *not* generated by simply adding ten to the last-seen line number: the number will instead be the next number that is a *multiple* of ten (by default).

Automatic line-number generation will continue until
 - `CONTROL-A` is typed again (toggle),
 - a line with no number at the start is typed (commands that are executed by ProDOS are excluded), or
 - a line at a prompt other than the direct-mode AppleSoft prompt is typed.

If you are in **normal** mode, and type a number before executing `CONTROL-A`, then it is handled specially. Normally, prefixing a normal-mode command with a number will repeat that command the specified number of times (for those commands that support it). With `CONTROL-A`, it will instead set the auto-increment interval. For example, if you type `100` `CONTROL-A`, then line numbers will be generated in successive multiples of 100, rather than 10. If this technique is used when the current line already has a line number at the start, that number will be removed, and replaced with one that conforms to the new formula (the replacing number will still be generated based on the last line-number seen on a previously-completed input line).

## Jump-to-Char

In **normal** mode, typing the `F` key followed by another character, will jump forward to the next occurrance of that character (if found). Afterwards, the `;` key will jump forward to the next occurrance after that (without having to retype `F` plus the character), and `,` will jump backwards. In *real* vi, you would use lowercase **f** to move forward and uppervase **F** to move back, with **;** and **,** reversing the direction, but in **a2vimode**, since distinguishing lowercase and uppercase commands is not supported (so that it may run on Apple \]\[+ and prior machines), only the forward direction is supported. zso to search *back* for a character (say, `X`), you must first type `F` and then `X`, and then type `,` once or twice to move back.

There is also the `T` command, which works the same way as `F`: you type `T` and then any other character; but instead of jumping directly to the next character, it jumps to immediately *before* that character. `;` and `,` then move forward and backward to the "just befores" of that character.

This can be particularly useful in combination with the `D` (delete) or `C` (change) commands. For example, with the following line:
```
] PRINT "WELCOME TO YOUR DOOM!!!"
```
If you wish to replace the contents of the string literal (the text between the two double-quotes (`"`)), and the cursor is at the beginning of the prompt, then you could type (in **normal** mode): `WCT"`. The `W` moves the cursor to the next **w**ord-beginning (which in **a2vimode** means string-of-alphanumeric-characters), which is the `W` of `WELCOME`. The `C` means to **c**hange (delete and retype) the text that falls under the next movement, and `T"` moves to just-before the next double-quote. So the line becomes:
```
] PRINT ""
```
with the prompt set to **insert** mode, and the cursor positioned to insert your typed text between the two double-quotes.

Note that, besides `F` and `T`, there is one additional command that affects the behavior of the `;` and `,` keys: the `#` command, which jumps to numbers, in a manner similar to how the `W` and `B` commands jump to words. In this mode, `;` and `,` are jumping to individual characters, but to "words" of digits. See [Summoning BASIC Lines](#summoning-basic-lines) for more information on the `#` command.

## Replace Mode ###

Besides **insert** and **normal** mode, there *is* actually a third mode: `CONTROL-R` (from **normal** mode) for **replace** mode. This is a variant of **insert** mode, but **(a)** anything you enter is typed *over* any existing text, replacing it, **(b)** if you backspace, it will restore the original characters from before you typed over them, and **(c)** you cannot backspace to the left of where the cursor was when you entered **replace** mode. As with insert mode, `TAB` (or `ESC`) will return you to **normal** mode.

Example: if you have text like:
```
] 10 PRINT "********** HANDY-MAN SIMULATOR 9000 **********"
```
If you're in normal mode with the cursor positioned at the first `*`, and you enter five `@`s, the line will then look like:
```
] 10 PRINT "@@@@@***** HANDY-MAN SIMULATOR 9000 **********"
```
(You could *also* use a repeat-command: `5R@`.)

## Other Notes

### Disabling Vi-Mode

To disable **vi-mode**, execute the `IN#0` command.

### 80-Column

**NOTE: at the moment, 80-column mode does not work under ProDOS. It isn't fantastic under DOS either, if you're using specifically the unenhanced Apple \]\[e, but should work provided you follow the instructions below closely. Enhanced Apple //e appears to work better.**

To use vi-mode in 80-column mode, first start 80-column mode with `PR#3`, and then `RUN HELLO` to reconnect **vi-mode**. Do not run the `HELLO` program multiple times with 80-column firmware active - if you want to reboot **vi-mode**, do another `PR#3` followed by `RUN HELLO`.

And don't touch the `ESC` key! Use `TAB` to enter normal mode.
