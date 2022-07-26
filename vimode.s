; Copyright 2022 Micah J Cowan <micah@addictivecode.org>
; MIT license (see accompanying LICENSE.txt)

.macpack apple2

WNDBTM = $23
CH = $24
CV = $25
BASE = $28
INVFLAG = $32
PROMPT = $33
CSW = $36

IN = $200
VTAB = $FC22
VTABZ = $FC24
SCROLL = $FC70
CLREOL = $FC9C
WAIT = $FCA8
RDKEY = $FD0C
KEYIN = $FD1B
CROUT = $FD8E
PRBYTE = $FDDA
COUT = $FDED
COUT1 = $FDF0
SETINV = $FE80
SETNORM = $FE84
BELL = $FF3A

RET_RDCHAR = $FD37
RET_GETLN  = $FD77

;

STAT_BASE = $750 ; line 22
STRC_BASE = $7D0 ; line 23 (last line)

DEBUG=1

.ifndef DEBUG
kMaxLength = $FE
.else
;kMaxLength = $30 ; 48
kMaxLength = $FE
.endif

.org $6000

Input:
    cld
InputRedirFn = * + 1
    ; The address of the following JMP will be _rewritten_
    ; to jump directly to keyboard inputs, when GETLN
    ; has been detected (and replaced). It will be restored
    ; to CheckForGetline once our replacement GETLN routine
    ; has exited (so that future inputs once again check for
    ; GETLN)
    jmp CheckForGetline
    jmp CheckForGetline ; we say it twice, so the bootstrapper
                        ; knows what it should look like :)
RealInput:
    ; keyboard input. This immediate-jmp routine exists
    ; to make it easy to swap the keyboard input for some other
    ; KSW routine, as needed.
    jmp KEYIN
.ifdef DEBUG
PrintState:
    bit StatusBarOn
    bmi @good
    rts
@good:
    stx SaveX

    ; Save screen coordinates, and go to top-left
    lda CH
    sta SavedCH
    lda #0
    sta CH
    lda #<STAT_BASE
    sta BASE
    lda #>STAT_BASE
    sta BASE+1

    lda INVFLAG
    pha
    jsr SETINV

    ; Print X and LL
    ldx SaveX
    txa
    jsr PRBYTE
    lda #$A0
    jsr COUT
    lda LineLength
    jsr PRBYTE
    lda #$BD
    jsr COUT

    ; Print a portion of the buffer
    ldx #0
@lp:lda IN,x
    cpx SaveX
    beq @xPr
    jsr PRBYTE
@sp:lda #$A0
    jsr COUT
    inx
    cpx #$0A ; ten chars of buffer (ignore LL)
    bcc @lp

    pla ; restore whatever inversion state from before
    sta INVFLAG

    ; Restore screen coords and peace out
    lda SavedCH
    sta CH
    ldx SaveX
    jmp VTAB
@xPr:
    pha
    jsr SETNORM
    pla
    jsr PRBYTE
    jsr SETINV
    jmp @sp
StatusBarOn:
    .byte $00 ; off by default
StatusBarSetup:
    ; Ensure the current line is above the status display area
@again:
    lda CV
    cmp #$16
    bcc @setwbt
    sbc #1 ; we already know carry is set (borrow = clear)
    sta CV
    jsr SCROLL ; does VTAB
    jmp @again
@setwbt:
    lda #$16
    sta WNDBTM
    rts
StatusBarCleanup:
    ; We just switched status bar off; go and erase it
    lda CH
    sta SavedCH

    lda #0
    sta CH
    lda #$16
    jsr VTABZ
    jsr CLREOL
    lda #$17
    jsr VTABZ
    jsr CLREOL

    lda SavedCH
    sta CH
    lda CV
    jsr VTABZ
    lda #$18
    sta WNDBTM
    rts
ToggleStatusBar:
    lda StatusBarOn
    eor #$FF
    sta StatusBarOn
    bmi @statusOn
    ; status bar switched off; clean it up
    jmp StatusBarCleanup
@statusOn:
    jmp StatusBarSetup
    ;
PrintStackTraceSuccess:
    jsr StackTraceSetup
    ; indicate that we did detect GETLN
    lda #$D9 ; Y
    jsr COUT
    lda #$C5 ; E
    jsr COUT
    lda #$D3 ; S
    jsr COUT
    lda #$A0 ; SPC
    jsr COUT
    jmp PrintStack
PrintStackTraceFailed:
    jsr StackTraceSetup
    ; indicate that we did NOT detect GETLN
    lda #$CE ; N
    jsr COUT
    lda #$CF ; O
    jsr COUT
    lda #$A0 ; SPC
    jsr COUT
    lda #$A0 ; SPC
    jsr COUT
    jmp PrintStack
StackTraceSetup:
    ; save position
    lda BASE
    sta StSvBASE
    lda BASE+1
    sta StSvBASE+1
    lda CH
    sta StSvCH
    ; set position
    lda #0
    sta CH
    lda #<STRC_BASE
    sta BASE
    lda #>STRC_BASE
    sta BASE+1
    ; force direct screen output for COUT -
    ;   we don't want to be re-entering DOS hooks...
    ; (but save away existing CSW first)
    lda CSW
    sta StSvCSW
    lda CSW+1
    sta StSvCSW+1

    lda #<COUT1
    sta CSW
    lda #>COUT1
    sta CSW+1
    rts
PrintStack:
    ; This is for debugging, but... calling it from within a DOS call
    ; will probably munge things
    tsx
    inx ; Skip over PrintStack's own call (heh)
    inx
    inx
    ldy #$0A ; print 10 bytes of stack
@Lp:
    lda #$A0
    jsr COUT
    lda $100,x
    jsr PRBYTE
    inx
    dey
    bne @Lp
    ; cleanup
    jsr CLREOL
    lda StSvBASE
    sta BASE
    lda StSvBASE+1
    sta BASE+1
    lda StSvCH
    sta CH
    lda StSvCSW
    sta CSW
    lda StSvCSW+1
    sta CSW+1
    rts
StSvBASE: .word 0
StSvCSW: .word 0
StSvCH:.byte 0
.endif ; DEBUG
    CheckForGetline:
    ; The vi-mode prompt works by detecting and *replacing* what had
    ; been a call from the firmware `GETLN` routine at `$FD78`.  `GETLN`
    ; isn't hookable, so instead we hook into `KSW` (the input routine),
    ; and *look back at the stack* to see if it looks like we were
    ; called, indirectly, from `GETLN`. If we find `GETLN`'s address
    ; (minus 1) on the stack, with the right chain of calls appearing to
    ; lead from it to us, then we replace `GETLN`'s return address with
    ; one of our own choosing, thus automatically replacing `GETLN`
    ; every time it's called, with our vi-mode substitute.
    ;
    ; The notion of "looks like we were called indiretly from GETLN" is
    ; a bit involved. We don't want to just find `GETLN`'s address in
    ; the last ~8 bytes of stack, because it could just be there through
    ; happenstance: an old stack value that's been abandoned due to a
    ; `RESET` perhaps, or even `PHA TYA PHA` would put it there, if the
    ; `A` and `Y` registers have just the right values. Too risky.
    ;
    ; But there are also multiple ways that `GETLN` can lead to calling
    ; the `KSW` hook routine. On the original Apple II, `GETLN` just
    ; calls `RDCHAR`, which calls `KSW`. At least under emulation, the
    ; Apple II+, unenhanced Apple IIe, and enhanced Apple IIe, all look
    ; the same as original Apple II.
    ;
    ; *But*. On an Apple //c, things get "fancy". The firmware location
    ; for `RDCHAR` is a placeholder that jumps to the "real" location,
    ; in `$Cxxx` ROM space somewhere, which then calls 'KSW'. This is true
    ; for all original ROMs I could find (from ROM 255 to the "memory
    ; enhanced" models).  So instead of looking for `RDCHAR`'s return
    ; address, we need to look for a different one Then, on the
    ; unofficial/user-created ROM 4X, there's yet *another* caller
    ; address within the `$Cxxx` ROM space that's involved!
    ;
    ; So... to find a "real" indirect call from (eventually) `GETLN`,
    ; what we look for on the stack is (first = nearest):
    ;
    ;   ????? { `RDCHAR` *or* either one or two $Cxxx addresses } `GETLN`
    ;
    ; That is, we optionally skip one irrelevant address (presumed to be
    ; a DOS or ProDOS wrapper), and recognize either the return address
    ; from `RDCHAR` (`$FD37`), or else either one or two address in
    ; the `$Cxxx` range, and finally (always) the return address from
    ; `GETLN`, `$FD77`. (We don't accept *any* address for the optional
    ; first/throwaway caller - it can't have $FD or $Cx in the high
    ; byte; we assume DOS hooks wouldn't come from there.)

    sta SaveA
    stx SaveX
    sty SaveY

.ifdef DEBUG
    clc
    sec
    bcs @skipUninstall
    ; We never reach here.
    ; This code is here for us to hack,
    ; if we want to insert BRKs to see what's being reached.
    ; You can't type into the monitor if you're using the same
    ; input function you're debugging...
    lda #<RealInput
    sta InputRedirFn
    lda #>RealInput
    sta InputRedirFn+1
@skipUninstall:
.endif ; DEBUG

    tsx ; get stack pointer
    inx ;  and point at first byte of caller above us

    ;;; Look at the high byte of our immediate caller
    inx
    lda $100,x
    cmp #$C0
    bcc @firstCaller ; -> this caller is < #$C000, it's a "freebie" we
                     ;    don't count; check next caller as the "real" first
    ; >= #$C00
    cmp #$D0
    bcc @secondCaller ; -> this caller is our first of up to two #$Cxxx
                      ;    callers; head to the next.
    cmp #>RET_RDCHAR
    bne @checkFailed  ; -> This caller matches none of our criteria. Bail.
    ; Check the low byte.
    dex
    lda $100,x
    cmp #<RET_RDCHAR
    bne @checkFailed ; -> Not RDCHAR after all. Bail.
    inx
    jmp @maybeGetln ; this was RDCHAR, so next must be GETLN to pass.

@firstCaller:
    ; If we reach here, we're on the high byte of the first caller after
    ; what we assume to have been some DOS's wrapper routine, and skipped.
    ; to proceed, this has to be the known RDCHAR return, or something
    ; from $Cxxx (presumed to be some ROM's RDCHAR).
    inx
    inx ; move to high byte of first "real" caller.
    lda $100,x
    cmp #>RET_RDCHAR
    bne @firstMaybeCx ; -> Wasn't (known) RDCHAR; maybe a $Cxxx?
    ; matched high byte of RDCHAR - does it match low?
    dex
    lda $100,x
    cmp #<RET_RDCHAR
    bne @checkFailed ; -> Not RDCHAR. Bail.
    inx
    jmp @maybeGetln ; this was RDCHAR, so next must be GETLN to pass.
@firstMaybeCx:
    cmp #$C0
    bcc @checkFailed ; -> Not RDCHAR, not $Cxxx. Match fails.
    ; is >= #$C000. Is it < #$D000?
    cmp #$D0
    bcs @checkFailed ; -> Not RDCHAR, too high to be $Cxxx. Match fails.
@secondCaller:
    ; we're the first of up to two $Cxxx callers. Check to see if
    ; there's another.
    inx
    inx
    lda $100,x
    cmp #$C0
    bcc @checkFailed ; -> Not $Cxxx, and too low to be GETLN. Failed.
    ; is >= #$C000. Is it < #$D000?
    cmp #$D0
    bcc @maybeGetln ; -> Is $Cxxx. Next one must be GETLN.
    ; not $Cxxx. THIS must be GETLN to pass, so back up to re-check this
    ;   caller.
    dex
    dex
@maybeGetln:
    ; if we get here, we're at the byte before what needs to be GETLN
    ; to successfully match.
    inx ; check the low byte first
    lda $100,x
    cmp #<RET_GETLN
    bne @checkFailed
    ; so far so good...
    inx
    lda $100,x
    cmp #>RET_GETLN
    bne @checkFailed

    ; Eureka! We have it.
.ifdef DEBUG
    ; possibly print the status bar
    lda StatusBarOn ; (may have come here without toggle)
    bpl @nostatus
    stx SaveA ; never mind the name...
    jsr PrintStackTraceSuccess
    ldx SaveA
@nostatus:
.endif ; DEBUG
    ; Now, swap it for ours.
    lda #>(ViModeEntry-1)
    sta $100,x
    dex
    lda #<(ViModeEntry-1)
    sta $100,x

    ; ...and return.
    ;
    ; ...We're going to land in "our" ViMode, so why don't we go ahead
    ; and prompt for the first character?
    ;
    ; Two reasons. (1) RDCHAR will interpret special characters like
    ; ESC, and let the cursor go and wander off. We don't want that -
    ; we want to return immediaely to our prompt, which never calls
    ; RDCHAR (though even normal RDKEY will process ESC, on a //c or in
    ; 80-column mode :( )
    ; (2) Cosmetic. the RDCHAR above us will have already
    ; stored the visible character our cursor was on, if there was text
    ; present before the prompt was issued. It winds up looking kinda
    ; tacky in some situations.
    ;
    ; So we just return a "harmless" SPACE character, which we've
    ; arranged for our ViMode prompt to ignore and re-take the first
    ; "real" character.
    ldx SaveX
    ldy SaveY
    lda #$A0
    rts

@checkFailed:
    ; Just do an absolutely ordeinary input fetch.
.ifndef DEBUG
    lda SaveA
    ldx SaveX
    ldy SaveY
    jmp RealInput
.else
@reread:
    ; DEBUG mode.
    ; We only check for one key: Ctrl-\ to enable the debug status bar.
    ; Then we print the stack info we just rejected, and check
    ; keypresses again.
    lda StatusBarOn
    bpl @done
    jsr PrintStackTraceFailed
    lda SaveA
    ldx SaveX
    ldy SaveY
    jsr RealInput
    sta SaveA
    stx SaveX
    sty SaveY
    cmp #$DC ; \
    bne @done
    ; \ pressed
    jsr ToggleStatusBar
    jmp @reread
@done:
    lda SaveA
    ldx SaveX
    ldy SaveY
    rts
.endif ; DEBUG

InitViModeAndGetStarted:
    ;lda SaveA - no, this should always be a space, since we cleared.
    ; We're KSW, but we're returning to restart the prompt with a "real"
    ; KSW. Just load SPACE and return, hopefully the DOS hook doesn't
    ; care the value
    lda #$A0
    rts

ViModeGetline:
    ; Call to here if you want an explicit call to _our_ GETLN.
    ; Print the prompt...
    lda PROMPT
    jsr COUT
    ; fall through to general initialization, and then on to insert-mode
ViModeEntry:
InitViMode:
    ; Install direct keyin fn (no GETLN check)
    lda #<RealInput
    sta InputRedirFn
    lda #>RealInput
    sta InputRedirFn+1
    ; Save our stack position - we need it to help dodge a dirty trick
    ; from ProDOS (see comments for MyRDKEY).
    tsx
    stx SaveS
    ; Fill the inbuf with CRs
    lda #$8D
    ldx #0
    stx appendModeFlag ; reset append flag
@lp:
    sta IN,x
    inx
    bne @lp
    ; Set the current line length
    stx LineLength
    jsr CLREOL ; ensure that everything on our line is actually
               ; in the input buffer, as well as on screen...
               ; by clearing the line out that we're on.
.ifdef DEBUG
    ; Pre-fill the buffer when we enter for the first time, to
    ; present an easy playground that tests our latest features
PrefillFlag = * + 1
    lda #$FF
    bpl @dbail

    ldx #0
    ldy #0
    stx SaveX
    dey
@dlp:
    iny
    lda DbgPrefill,y
    beq @dlpdn ; terminating NUL?
    cmp #$80   ; X-save flag?
    bne @dprnt
    ; flag to put X here.
    stx SaveX
    jmp @dlp
@dprnt:
    sta IN,x
    sty SaveY
    jsr ViPrintChar
    ldy SaveY
    inx
    bne @dlp
@dlpdn:
    stx LineLength
    ldx SaveX
    jsr BackspaceFromEOL

    lda #$00
    sta PrefillFlag ; make sure we don't do this again at the next prompt
@dbail:
    jmp InsertMode
DbgPrefill:
    ; used to pre-fill the buffer when we first enter
    scrcode "HELLO, WORLD!"
    .byte 0
.endif
InsertMode:
.ifdef DEBUG
    jsr PrintState
.endif
    ; INSERT MODE.
    jsr MyRDKEY
    ; We enter here via return from CheckForGetLine (when GETLN
    ; was found)

    ; Did we get a printable char? Just, ehm, print it.
    cmp #$A0
    bcc ControlChar
@PrinableOrDEL:
    cmp #$FF ; DELETE? treat like backspace
    bne @Printable
    jsr Backspace
    jmp InsertMode
@Printable:
    ; We're printable! print (and store) us.
    ; TODO: if we're a model that doesn't have lowercase, we should
    ;  upper-bound it too, and force to caps like Apple ][+ does.
    jmp TryInsertChar
ControlChar:
.ifdef DEBUG
MaybeCtrlBackslash:
    cmp #$9C ; C-\ ?
    bne @nf ;-> try 'nother char
    jsr ToggleStatusBar
    jmp InsertMode
@nf:
.endif
MaybeCtrlL:
    cmp #$8C ; C-L ?
    bne @nf
    jsr ReadWait
    jmp InsertMode
@nf:
MaybeEsc:
    cmp #$89 ; Tab? (workaround for ESC, in 80-col mode)
    beq @yes
    cmp #$9B ; ESC?
    bne @nf ;-> try 'nother char
@yes:
    jmp EnterNormalMode
@nf:
MaybeLeftArrow:
    cmp #$88 ; left-arrow (backspace)?
    bne @nf ;-> try 'nother char
    ;jsr TryGoLeftOne - no, bc ][+ doesn't have DELETE, only BS
    jsr Backspace
    jmp InsertMode
@nf:
;MaybeRightArrow:
;    cmp #$95
;    bne @nf ;-> try 'nother char
;    jsr TryGoRightOne
;    jmp InsertMode
;@nf:
MaybeCtrlX:
    cmp #$98
    bne MaybeCtrlXOut ;-> try 'nother char
DoAbortLine:
    jsr PrintRestOfLine
    ldx LineLength
    lda #$A0
    jsr COUT
    lda #$DC ; '\'
    jsr COUT
    lda #$8D ; CR
    jsr COUT
    jmp ViModeGetline
MaybeCtrlXOut:
;
MaybeCtrlV:
    cmp #$96
    bne @nf ;-> try 'nother char
    ; do a direct read, and insert it, whatever it may be
    jsr MyRDKEY
    jmp TryInsertChar
@nf:
MaybeCR:
    cmp #$8D
    beq DoCR
IMUnrecognizedControl:
    ; Unrecognized: we print and store uncrecognized control chars too
    jmp TryInsertChar
NoRoomLeft:
NoRoomRight:
    ;jsr BELL
    jmp InsertMode
DoCR:
    jsr PrintRestOfLine ; jump to end
    ldx LineLength
    lda #$8D ; CR
    sta IN,x ; make damn sure we're locked off with a CR
    jsr COUT ; ...and emit one, as GETLN would.
    ; Restore the check for GETLN
    lda #<CheckForGetline
    sta InputRedirFn
    lda #>CheckForGetline
    sta InputRedirFn+1
    lda #$8D
    rts
BackspaceFromEOL:
    ; Now backspace back again to where we actually are, so next input
    ; prompts in the right place
    stx SaveX
    lda LineLength
    sec
    sbc SaveX
    tay
EmitYCntBsp:
    lda #$88
    cpy #$0
    beq @doneBk
@lpBk:
    jsr COUT
    dey
    bne @lpBk
@doneBk:
    rts
TryInsertChar:
    ; Check to see if there's room for the char
    sta SaveA
    lda LineLength
    cmp #kMaxLength
    bcs NoRoomRight ; No more space left!

    ; If we're here we are definitely inserting
InsertOk:
    ; First, make some space in the buffer
    stx SaveX
    ldx LineLength
    inx
@lp:
    dex
    lda IN,x
    inx
    sta IN,x
    dex
    cpx SaveX
    bne @lp
    ; Increase line length
    inc LineLength
    ; Insert the character to buffer
    lda SaveA
    sta IN,x
    inx
    ; Now print the character
    jsr ViPrintChar
    ; Print the rest of the line out after the new char
    jsr PrintRestOfLine
    ; need to backspace back again
    jsr BackspaceFromEOL
    jmp InsertMode
PrintRestOfLine:
    stx SaveX
    cpx LineLength
    beq @out
@lp:lda IN,x
    jsr ViPrintChar
    inx
    cpx LineLength
    bne @lp
@out:
    ldx SaveX
    rts
PrintYNextChars:
    stx SaveX
    cpy #0
    beq @done
    sty SaveY
@lp:
    lda IN,x
    jsr ViPrintChar
    inx
    dec SaveY
    bne @lp
@done:
    ldx SaveX
    rts
BackspaceToStart:
    txa
    tay
    jmp EmitYCntBsp
PrintStartToX:
    stx SaveX
    ldy #0
    cpy SaveX
    beq @done
@lp:lda IN,y
    jsr ViPrintChar
    iny
    cpy SaveX
    bne @lp
@done:
    rts
ViPrintChar:
    cmp #$A0
    bcc PrintControlChar
    jmp CoutRowCheck
PrintControlChar:
    sta SaveA
    lda INVFLAG
    pha
    lda #$3F ; control chars show as inverse text
    sta INVFLAG
    lda SaveA
    and #$1F
    ora #$C0
    jsr CoutRowCheck
    pla
    sta INVFLAG
    rts
CoutRowCheck:
    pha
    lda CV
    sta SavedCV
    pla
    pha
    jsr COUT
    lda CV
    cmp SavedCV
    beq @skipClr
    tya
    pha
    jsr CLREOL
    pla
    tay
@skipClr:
    pla
    rts
Backspace:
    cpx #0
    bne @cont
    ;jsr BELL
    rts ; nothing to do.
@cont:
    ; First, emit the backspace character to screen
    lda #$88
    jsr COUT
    ; decrement line length
    dec LineLength
    ; Now, loop over each forward character, moving it back one,
    ;  and also emitting it to screen
    dex
    stx SaveX
@lp:
    cpx LineLength
    beq @done
    inx
    lda IN,x
    dex
    sta IN,x
    jsr ViPrintChar
    inx
    bne @lp ; always (hopefully)
@done:
    ; Store a CR at the end
    lda #$8D
    sta IN,x
    ; Restore X-reg
    ldx SaveX
    ; Emit a final space, and then backspace, to delete final character
    lda #$A0
    jsr COUT
    lda #$88
    jsr COUT
    jsr BackspaceFromEOL
    rts
EnterNormalMode:
    lda #$AD ; '-'
    jsr ChangePrompt
    ; fall through to ResetNormalMode
ResetNormalMode:
    ; TODO: reset a command or movement-in-progress
    lda appendModeFlag
    bpl @appFlagUnset
    lda #$0
    sta appendModeFlag
    jsr TryGoLeftOne
@appFlagUnset:
NormalMode:
.ifdef DEBUG
    jsr PrintState
.endif
    jsr MyRDKEY
    ; in our normal mode, lowercase should be converted to upper.
    cmp #$E0    ; < 'a' ?
    bcc @nocvt  ; -> no
    cmp #$FA    ; >= '{' 
    bcs @nocvt
    sec
    sbc #$20
@nocvt:
; START of line-modifying/not-just-movement commands
NrmMaybeI:
    cmp #$C9 ; 'I'
    bne NrmMaybeIOut
    ; 'I'? fall through
EnterInsertMode:
    jsr RestorePrompt
    jmp InsertMode
NrmMaybeIOut:
;
NrmMaybeA:
    cmp #$C1 ; 'A'
    bne @nf
    cpx LineLength
    beq @atEnd
    lda #$FF
    sta appendModeFlag ; so exiting insert mode drops cursor back one char
    jsr TryGoRightOne
@atEnd:
    jmp EnterInsertMode
@nf:
NrmMaybeX:
    cmp #$D8 ; 'X'
    bne @nf
    ; equivalent to forward-one-then-BS, unless at end of line
    cpx LineLength
    beq @fail
    inx
    lda #$A0 ; SP - just print anything at all for position's sake,
             ; we're about to BS over it anyhow
    jsr COUT
    jsr Backspace
@fail:
    jmp ResetNormalMode
@nf:
NrmMaybeDELorBS:
    cmp #$FF ; DEL
    beq @eq
    cmp #$88 ; LeftArrow/BS
    bne @nf
@eq:
    jsr Backspace
    jmp ResetNormalMode
@nf:
NrmMaybeCtrlX:
    cmp #$98
    bne @nf ;-> try 'nother char
    ; XXX - if EnterInsertMode does cleanup, we should do that
    ;  here as well, as we're leaving NormalMode
    jmp DoAbortLine
@nf:
NrmMaybeCR:
    cmp #$8D ; CR
    bne @nf
    jmp DoCR
@nf:
NrmSafeCommands:
; END of line-modifying commands
.ifdef DEBUG
NrmMaybeCtrlBackslash:
    cmp #$9C ; C-\ ?
    bne @nf
    jsr ToggleStatusBar
    jmp ResetNormalMode
@nf:
.endif
NrmMaybeEol:
    cmp #$A4 ; $
    bne @nf
    jsr PrintRestOfLine
    ldx LineLength
    jmp ResetNormalMode
@nf:
NrmMaybeZero:
    cmp #$B0 ; 0
    bne @nf
    jsr BackspaceToStart
    ldx #0
    jmp ResetNormalMode
@nf:
NrmMaybeCarat:
    cmp #$DE ; '^'
    bne @nf
    jsr BackspaceToStart
    ldx #0
    lda IN,x
    jsr GetIsWordChar
    bcc NrmWordFwd
    jmp ResetNormalMode
@nf:
NrmMaybeW:
    cmp #$D7 ; 'W'
    bne NrmMaybeWOut
NrmWordFwd:
    stx SaveA ; nevermind the name...
    jsr MoveForwardWord
    jsr PrintForwardMoveFromSaveA
    jmp ResetNormalMode
NrmMaybeWOut:
;
NrmMaybeB:
    cmp #$C2 ; 'B'
    bne @nf
    stx SaveA ; nevermind the name...
    jsr MoveBackWord
    stx SaveX
    lda SaveA
    sec
    sbc SaveX
    tay
    jsr EmitYCntBsp
    jmp ResetNormalMode
@nf:
NrmMaybeE:
    cmp #$C5 ; 'E'
    bne @nf
    stx SaveA ; nevermind the name...
    jsr MoveForwardWordEnd
    jsr PrintForwardMoveFromSaveA
    jmp ResetNormalMode
@nf:
NrmMaybeH:
    cmp #$C8 ; 'H'
    bne @nf
    jsr TryGoLeftOne
    jmp ResetNormalMode
@nf:
NrmMaybeL:
    cmp #$CC ; 'L'
    bne @nf
    jsr TryGoRightOne
    jmp ResetNormalMode
@nf:
NormalUnrecognized:
    ;jsr BELL
    jmp ResetNormalMode
RestorePrompt:
    lda PROMPT
    ; fall through
ChangePrompt:
    sta @CPSaveA
    cmp #$80 ; New prompt NUL?
    beq @bail
    lda PROMPT
    cmp #$80 ; Official prompt NUL?
    beq @bail

    jsr BackspaceToStart
    ; one more BS gets us onto the prompt.
    lda #$88
    jsr COUT
@CPSaveA = * + 1
    lda #$DC
    jsr COUT
    jmp PrintStartToX
@bail:
    rts
TryGoLeftOne:
    ; Try to go left.
    cpx #0
    bne @skipRts
    rts
@skipRts:
    ; go left!
    dex
    lda #$88
    jmp COUT ; emit BS
TryGoRightOne:
    ; Try to go right.
    cpx LineLength
    beq @rts
    cpx #kMaxLength
    beq @rts
    lda IN,x
    ; go right! print the current char to move.
    jsr ViPrintChar
    inx
@rts:
    rts
GetIsWordChar:
    ; Exits with carry set if Areg is a word char
    ;
    ; XXX crude version, ignores some kinds of punctuation.
    ; Should be: word is everything that's not punctuation, space, or control
    ; (leaving alphanum).
    ; XXX is: word is everything >= #$C1
    cmp #$C1
    rts
BackWhileWord:
@lp:
    cpx #0
    beq @done
    dex
    lda IN,x
    jsr GetIsWordChar
    bcs @lp
    inx ; keep on the word char
@done:
    rts
BackWhileNotWord:
@lp:cpx #0
    beq @done
    dex
    lda IN,x
    jsr GetIsWordChar
    bcc @lp
    inx ; keep on the non-word char
        ; we, uh, probably don't need this in reality,
        ; given that as far as I know we only ever
        ; follow BackWhileNotWord with BackWhileWord
@done:
    rts
MoveBackWord:
    stx @privSave
    jsr BackWhileNotWord
    cpx #0
    beq @giveUp ; give up if there was only non-word space to back over
    jmp BackWhileWord
@giveUp:
    ldx @privSave
    rts
@privSave:
    .byte 0
MoveWhileWord:
@lp:
    cpx LineLength
    beq @done
    lda IN,x
    jsr GetIsWordChar
    bcc @done
    inx
    bne @lp
@done:
    rts
MoveWhileNotWord:
@lp:
    cpx LineLength
    beq @done
    lda IN,x
    jsr GetIsWordChar
    bcs @done
    inx
    bne @lp
@done:
    rts
MoveForwardWord:
    stx @privSave0
    jsr MoveWhileWord
    lda IN,x
    jsr GetIsWordChar
    bcs @giveUp     ; give up if we never managed to leave a word
    jsr MoveWhileNotWord
    cpx LineLength  ; give up if we're past the end
    beq @giveUp
    lda IN,x
    jsr GetIsWordChar
    bcc @giveUp     ; or if we're not at a new word
    ; We made it!
    rts
@giveUp:
    ldx @privSave0
    rts
@privSave0:
    .byte 0
MoveForwardWordEnd:
    stx @privSave0
    lda IN,x
    jsr GetIsWordChar
    bcc @start
    cpx LineLength
    beq @start
    inx ; Ensure we move at least one caracter,
        ; so if we're already at the end of one word
        ; we find the next
@start:
    jsr MoveWhileNotWord
    lda IN,x
    jsr GetIsWordChar
    bcc @giveUp     ; give up if we never managed to enter a word
    jsr MoveWhileWord
    lda IN,x
    jsr GetIsWordChar
    bcs @done ; ensure cursor is on the last word character
              ; XXX: inappropriate during delete-movement
    dex
@done:
    rts
@giveUp:
    ldx @privSave0
    rts
@privSave0:
    .byte 0
PrintForwardMoveFromSaveA:
    stx SaveX
    txa
    pha
        sec
        sbc SaveA ; newX - origX
        tay
        ldx SaveA
        jsr PrintYNextChars
    pla
    tax
    rts
ReadWait:
    jsr MyRDKEY
    sec
    and #$7F ; char ranges from $80 - $FF, make it range from $00 - $FE
    clc
    asl
    pha
    ; WAIT, but a bunch'a times (up to ~2 secs)
    ldy #$0A
@lp:
    jsr WAIT
    pla
    pha
    dey
    bne @lp
    pla
    rts
.if 1
MyRDKEY:
    ; ProDOS is a silly bully, and plays games with us that it
    ; shouldn't.
    ; Of course, we can hardly complain, since we're playing a silly
    ; trick on _it_, by replacing its call to GETLN, which ProDOS
    ; knows how to abuse, with our replacement, which ProDOS does not
    ; know.
    ;
    ; But anyway, when the RETURN key is pressed by a user while it's in
    ; ProDOS's KSW handler, ProDOS pre-emptively inserts a CR at
    ; IN,x - which we don't want because the x-reg isn't necessarily at
    ; the end of the line, in our case. If the line buffer contains a
    ; ProDOS command, then ProDOS - before even returning control to us
    ; so we can tell it what the typed command was! - ProDOS clears the
    ; rest of the line, executes its command, sets the X-reg to 0
    ; (thinking that this will fool us into thinking the user never
    ; typed anything yet in the first place - as that's what GETLN would
    ; think), and returns a backspace character, which would cause GETLN
    ; to re-issue the prompt.
    ;
    ; To work around this, we do two things: We save the X-reg away and
    ; set it to the end of the line (without touching CH, so the cursor
    ; is still displayed in the right place). This also makes it totally
    ; okay if ProDOS sticks a CR there - it's already supposaed to be a
    ; CR. Then, we watch and see if the X-reg was _reset to zero_ and we
    ; got a backspace; in which case we restart the prompt - ProDOS has
    ; _already_ processed our current command, so throw it away like it
    ; tried to make us do.
    ;
    ; The one issue that isn't solved by this technique, is that if the
    ; user hit RETURN while still in the *middle* of a ProDOS command,
    ; ProDOS will delete the end of the line that's showing on the
    ; screen (even though, by setting X-reg to the end, we ensure the
    ; stored command is safe). Not much we can do about that, really,
    ; since it happens before we're even allowed to know about it.
    stx SaveX
    ldx LineLength
    jsr RDKEY
    pha
        lda LineLength
        bne @nonzero
    ; LineLength was 0, so we don't have to worry about ProDOS
    ; having played any tricks.
    pla
@out:
    ldx SaveX ; (not needed if we fell through from above)
    rts
@nonzero:
    pla
    cmp #$88 ; backspace?
    bne @out ; -> no, just return it then
    cpx #0   ; X-reg got reset?
    bne @out
    ; We got played! ...Go ahead and play along, restart the prompt.

    ; XXX what do we do here? We can't RTS and keep processing as
    ; usual (we could have come from ReadDelay, for instance),
    ; but neither can we just jmp to ViModeGetline - we have an unknown
    ; number of call returns on the stack between us and it.
    ; Could do like DOS, and save stack position on ViModeEntry?
    ; .... yeah, think we'll go with that.
    ldx SaveS
    txs
    jsr CROUT ; Send a CR, as GETLN would
    jmp ViModeGetline
.else
MyRDKEY:
    lda $38
    pha
    lda $39
    pha
        lda #<KEYIN
        sta $38
        lda #>KEYIN
        sta $39
        jsr RDKEY
        sta SaveA
    pla
    sta $39
    pla
    sta $38
    lda SaveA
    rts
.endif
SaveA:
    .byte 0
SaveX:
    .byte 0
SaveY:
    .byte 0
SaveS:
    .byte 0
SavedCH:
    .byte 0
SavedCV:
    .byte 0
SaveSearchX:
    .byte 0
LineLength:
    .byte 0
TmpWord:
    .word 0
appendModeFlag:
    .byte 0
