# Design Notes for a2vimode

This document covers the basic "How It Works" of a2vimode, and also a number of pitfalls encountered, on different hardware and DOS platforms, and the workarounds to them.

**Note:** throughout this document, references are made to ProDOS wrapping `KSW`, or calling the `GetLn` prompt, or modifying the AppleSoft prompt. In actuality, the core ProDOS software does not use the AppleSoft prompt, nor does it provide `KSW` or `CSW` wrappers—this functionality is provided by `BASIC.SYSTEM`, which is an optional system file provided as part of the ProDOS software package. Not all instances of ProDOS will have `BASIC.SYSTEM` installed, and so those instances will not in fact behave as described in this document. However, since ProDOS in those instances will also not be using a prompt to query the user for ProDOS commands, a ProDOS instance that does not include `BASIC.SYSTEM` will also not be using **a2vimode** (though, it could be used to run a program that does use it). Therefore, wherever you see ProDOS mentioned in this document, what we're really referring to is `BASIC.SYSTEM` running on ProDOS.

## Basic Theory

### Checking For GetLn

When a2vimode is started, a routine is installed to the Standard Input hook, `KSW` (or more accurately, the DOS or ProDOS "inner" equivalent to `KSW`). When this routine is called, it looks at call-return values on the stack (the addresses to which the `PC` register is set, on successive 6502 `RTS` operations), to determine if it's being called from the firmware's line-prompt facility, known as `GetLn` or `GETLN`. Specifically, it looks for (most-recent caller):

 - An optional return to a DOS or ProDOS `KSW` wrapper routine (this return can be any word less than `$C000`)
 - A return to the `RdChar` routine (which is called by `GetLn` to check for and handle `Esc` keyrpesses, for transposing the cursor to somewhere else on the screen; the expected return value is normally `$FD37`, but on the Apple //c specifically it will instead be a sequence of 2 or 3 words in the `$Cxxx` range, so those are accepted instead.
 - Finally, it must find the expected return to the `GetLn` routine (always `$FD77`)

(Note: if you want to verify for yourself where those return addresses arrive at, please remember that `RTS` will *add one to the value on the stack* before setting the program counter, so although the routine checks for a return address of `$FD77`, the real location of the actual instruction that would be returned to, is `$FD78` (and the `JSR` instruction that (eventually) got to us, is 3 bytes earlier at `$FD75` (2 bytes less than the address on the stack). None of these, of course, are the *starts* of the routines, they are simply the point in the routine where a `JSR` operation called us (or called a routine that called us, etc).)There is no practical way to distinguish this situation from a real call from `GetLn`, but thankfully it is a very unlikely scenario.

These call-stack values are correct for every known model of Apple II running the official firmware ROMs, plus also the ROM 4X on the Apple //c. It is unknown whether these values will work on unofficial Apple II *clones*, and may not work with customized ROMs. In such cases, it would be necessary to modify **a2vimode**'s call-check routine in order for it to work on that platform.

### If We Are In GetLn

If the check succeeds, we know we are currently "in" the firmware prompt. We then *edit* the stack, replacing the call-return for `GetLn` (`$FD77`) with an address that instead "returns" into our special prompt-replacement routine—the routine that handles all the special vi-mode bindings and commands. We then immediately return with the space character (`$A0`) in the accumulator, just to let us wind our way back up the stack, through whatever DOS wrapper, and `RdChar`, until it "returns" into our prompt replacement (which just ignores the returned char, and prompts for a new one).

An early development version of this software didn't immediately return a space, but instead served as a prompt for the first character that would be received by our prompt-replacement routine. We would edit the stack so as to remove `RdChar` from the return-sequence (so that the DOS or ProDOS KSW hook would skip the return to `RdChar`, and return instead directly into our prompt replacement). However, DOS tends to be sensitive to stack size changes, since it does manipulations of its own, and did not respond well to our removing a call frame from the stack. So we leave the stack the same size, and leave `RdChar` in place, and return a dummy space character so there's no possibility of `RdChar` seeing an `Esc` from user input, and handling it specially.)

Note that, since the stack can hold arbitrary values that were pushed onto the stack, and not merely call-returns, it is entirely possible that a program could push just the right (or wrong) values onto the stack, prior to calling our Standard-Input hook routine, and trick it into believing it was called from `GetLn` via `RdChar`, when in fact it was not. This could cause a crash when returning from our replacement prompt routine, but fortunately this scenario is unlikely enough that it shouldn't happen under typical circumstances. If it should happen, the solution would be to avoid using **a2vimode** together with whatever program happens to like pushing those values on the stack just prior to invoking `KSW`. 

### Additional AppleSoft Check

After a successful check for `GetLn`, when we already know we're going to replace `GetLn` with our replacement prompt routine, we do an additional check to see if that `GetLn` was in turn called from AppleSoft's main ("direct mode") user prompt. Specifically, it checks for:

 - A call-return to `InLine` (the AppleSoft routine that calls `GetLn`, and then converts the input buffer to "real" ASCII codes, terminated by a `NUL` (`#$00`) instead of a carriage return (`#$8D`) - stack value `$D532`). This routine is in turn called from:
 - A call-return to `Restart` (`D443`)

If this secondary check succeeds, a flag is set so that the replacement prompt knows that it's being used in AppleSoft's direct mode - this will enable features like auto-increment line numbers, and summoning lines of BASIC to the prompt (which are not permitted in other prompt situations).

### If We Are *Not* In GetLn

If the check fails, then we were not called from `GetLn`, and so we just jump to the firmware's "grab a keypress" routine, to do what a Standard-Input routine is normally expected to do.

## Apple //c Quirks

As mentioned, the call signature through `RdChar` looks different on an Apple //c from on any other Apple II systems. Apple //c `RdChar` is written differently, and `JMP`s to enhanced-firmware routines in the `$Cxxx` range. All of the official Appl ROMs have the same two-call signature in that range, after `GetLn`'s call signature; the popular fan-made //c ROM "4X" has a third call in that range. The //c+ ROMs 5 and 5X were not tested.

The initial release of **a2vimode** at HackFest 2022 (part of KansasFest) did not function on an Apple //c, because it had been developed and tested via emulation on an Apple \]\[+, \]\[e, and "enhanced" //e... but not on //c until immediately prior to release. It was fixed a day or two later.

## Unenhanced Apple //e Quirks

On most Apple \]\[ machines, the built-in Standard Input routine at the `KSW` hook does not process the `Esc` key specially (that is, you should not be able to move the cursor around the screen for a simple "read-the-keyboard" call).

However, on the unenhanced Apple \]\[e, and if the 80-column firmware is active (whether or not the screen is actually in 80-column mode), the `Esc` key *is* handled specially, and the user can use it to move the cursor around the screen even though it was supposed to be an ordinary keyboard check. This is *particularly* undesirable for **a2vimode**, because it relies on the cursor position remaining stable within the prompt, so that it can update the prompt properly when new input is typed, or characters are deleted. As long as the 80-column firmware's `KSW` routine (`$C305`) is used, there is no way to prevent `Esc` from being specially interpreted, before the prompt has the chance to intercept it.

The workaround so far has been to provide the `Tab` key as an alternate "normal mode" key instead of `Esc`, and recommend its use instead. Of course, an original Apple \]\[ or \]\[+ does not have a `Tab` key, so on such systems one should still use `Esc`.

A future version of **a2vimode** will probably check if the current machine is an unenhanced Apple //e with the 80-column firmware active, and if so, use a custom replacement "keyboard check" routine instead of the standard one, and so avoid the `Esc` problem.

## DOS Quirks

## ProDOS/BASIC.SYSTEM Quirks
