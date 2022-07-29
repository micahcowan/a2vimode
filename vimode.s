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
LINNUM = $50 ; line number stored here after LINGET parse
CURLIN = $75
LOWTR  = $9B ; FINDLIN puts the pointer to a line here when found
FAC = $9D

CHRGET = $B1
CHRGOT = $B7
TXTPTR = $B8

IN = $200
TOK_TABLE = $D0D0
FNDLIN = $D61A ; finds the location of a line from its number
GETCHR = $D72C ; not to be confused with CHRGET in ZP. Gets chr from (FAC),y
LINGET = $DA0C ; parses a line number from TXTPTR
FLOAT_2 = $EBA0
FOUT = $ED34
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
RET_AS_INLINE = $D532
RET_AS_RESTART = $D443

;

STAT_BASE = $750 ; line 22
STRC_BASE = $7D0 ; line 23 (last line)

PromptNormalChar = $AD ; '-'
PromptCaptureChar= $A3 ; '#'

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
    .byte 0 ; off by default
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
    lda ViPromptIsBasic
    bmi @basic
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
@basic:
    lda #$C2 ; B
    jsr COUT
    lda #$C1 ; A
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
    beq @hiGood
    jmp @checkFailed  ; -> This caller matches none of our criteria. Bail.
@hiGood:
    ; Check the low byte.
    dex
    lda $100,x
    cmp #<RET_RDCHAR
    beq @lowGood
    jmp @checkFailed ; -> Not RDCHAR after all. Bail.
@lowGood:
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
    ; Now, swap it for ours.
    lda #>(ViModeEntry-1)
    sta $100,x
    dex
    lda #<(ViModeEntry-1)
    sta $100,x

    ; Check to see if, additionally, GETLN was called from
    ;  the BASIC program-entry (general) prompt
    inx
    inx
    lda $100,x
    cmp #<RET_AS_INLINE
    bne @notBasic
    inx
    lda $100,x
    cmp #>RET_AS_INLINE
    bne @notBasic
    inx
    lda $100,x
    cmp #<RET_AS_RESTART
    bne @notBasic
    inx
    lda $100,x
    cmp #>RET_AS_RESTART
    bne @notBasic
    ; Congrats! We're direct-mode in BASIC
    lda #$FF
    bne @storeIsBasic
@notBasic:
    lda #$00
@storeIsBasic:
    sta ViPromptIsBasic

.ifdef DEBUG
    ; possibly print the status bar
    lda StatusBarOn ; (may have come here without toggle)
    bpl @nostatus
    jsr PrintStackTraceSuccess
@nostatus:
.endif ; DEBUG
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
    ; Reset whether we're "in BASIC". Only do this when directly
    ;  called by a user. XXX we should have a jump entry for here
    lda #$00
    sta ViPromptIsBasic
ViModeGetlineInternal:
    ; Call to here if you want an explicit call to _our_ GETLN.
    ; Print the prompt...
    lda PROMPT
    jsr COUT
    ; fall through to general initialization, and then on to insert-mode
ViModeEntry:
    lda PROMPT
    sta SavePrompt
    ; Clear any idea of BASIC "current line"
    lda #$00
    sta CurBasicLine
    sta CurBasicLine+1
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
    stx AppendModeFLag ; reset append flag
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
    scrcode "PRINT ",'"',"ALPHA BETA GAMMA DELTA EPSILON IOTA",'"'
.if 0
.repeat 7
.repeat 26, I
    .byte $C1 + I
.endrepeat
.endrepeat
.endif ; (repeat)
    .byte 0
.endif ; DEBUG
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
MaybeCtrlG:
    cmp #$87 ; C-G
    bne @nf
    ; Fetch a line of BASIC (_if_ we're a BASIC prompt)
    ;  from the number at the start of the buffer
    jsr MaybeFetchBasicLine
    jmp EnterNormalMode ; land in normal mode, for Ctrl-P/Ctrl-N
@nf:
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
    jmp ViModeGetlineInternal
MaybeCtrlXOut:
;
MaybeCtrlV:
    cmp #$96
    bne @nf ;-> try 'nother char
    ; do a direct read, and insert it, whatever it may be
    jsr MyRDKEY
    jmp TryInsertChar
@nf:
MaybeCtrlZ:
    cmp #$9A
    bne @nf ;-> try 'nother char
    jsr ShowVersion
    jmp InsertMode
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
EmitYCntAReg:
    cpy #$0
    beq @doneBk
@lpBk:
    jsr COUT
    dey
    bne @lpBk
@doneBk:
    rts
EmitYCntSpaces:
    lda #$A0
    bne EmitYCntAReg
    ; ^ eventual RTS.
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
    jsr CLREOL
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
    jmp COUT
PrintControlChar:
    sta SaveA
    lda INVFLAG
    pha
    lda #$3F ; control chars show as inverse text
    sta INVFLAG
    lda SaveA
    and #$1F
    ora #$C0
    jsr COUT
    pla
    sta INVFLAG
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
    lda #PromptNormalChar ; '-'
    jsr ChangePrompt
    lda AppendModeFLag
    bpl @appFlagUnset
    lda #$0
    sta AppendModeFLag
    jsr TryGoLeftOne
@appFlagUnset:
    ; We just entered; make sure we're not capturing
    lda #$0
    sta CaptureFlag
    ; ...or repeating
    sta RepeatCounter
    ; fall through to ResetNormalMode
ResetNormalMode:
    ;; Check for an active repeat count
    lda RepeatCounter
    beq @checkCapture
    ; Yes, we have a repeat count. Repeat it!

    ; TODO: at some future point we may wish to have the individual
    ;  commands handle the repeat count. Certainly going to be more
    ;  efficient.
    dec RepeatCounter
    beq @checkCapture ; we don't do the last one, because one was done
                      ; before we could start counting down
    lda NrmLastKey
    jmp NrmCmdExec

    ;; Process a captured move (delete or change)
@checkCapture:
    lda CaptureFlag
    bne @capturing
    jmp @notCapturing
@capturing:
    ; If we're here, we need to handle a movement that's just been
    ; captured.
    stx PostCapturePos ; save post-move X-reg away
    txa                ;  and move it to Y-reg
    tay
    ldx CapturePos ; Restore pre-mov location to X-reg
    cpx PostCapturePos
    bcc @calc ; -> CapturePos < PostCapturePos, no initial backspacing needed
    ; Deleting backwards: first backspace to where the mvmt landed us
    lda CapturePos
    ; sec -- is guaranteed
    sbc PostCapturePos
    sta PosDiff ; save the positions' difference
    tay
    jsr EmitYCntBsp
    ; now swap CapturePos and PostCapturePos (make it equivalent to a
    ; move-back-and-delete-forward)
    ldx PostCapturePos
    ldy CapturePos
    stx CapturePos
    sty PostCapturePos
    jmp @skipCalc
@calc:
    lda PostCapturePos
    sec
    sbc CapturePos
    sta PosDiff
@skipCalc:
    ;; Delete forward by copying char-at-Y to char-at-X until
    ;;  we've reached LineLength
@copyBackLoop:
    cpy LineLength
    beq @deleteDone
    lda IN,y
    sta IN,x
    inx
    iny
    bne @copyBackLoop
@deleteDone:
    lda #$8D ; we don't really need to terminate with a CR here,
    sta IN,y ; but what the heck.
    ; subtract from LineLength
    lda LineLength
    sec
    sbc PosDiff
    sta LineLength
    ;; Now update the screen - print the rest of the line, and
    ;; spaces over the previous line-tail
    ldx CapturePos
    jsr PrintRestOfLine
    ldy PosDiff
    jsr EmitYCntSpaces
    ;; Now back up again to where the cursor should be
    ; first back up to end of the line
    ldy PosDiff
    jsr EmitYCntBsp
    ; now back up the rest of the way to the cursor
    lda LineLength
    sec
    sbc CapturePos
    tay
    jsr EmitYCntBsp
    ; Were we a c-movement capture?
    lda CaptureFlag
    cmp #$C3 ; 'C'
    bne @notC
    jmp EnterInsertMode
@notC:
    ; turn off movement-capture; we did it.
    lda #$0
    sta CaptureFlag
    ; restore normal-mode prompt
    lda #PromptNormalChar
    jsr ChangePrompt

    ; fall through
@notCapturing:
NormalMode:
.ifdef DEBUG
    jsr PrintState
.endif
    jsr MyRDKEY
    sta NrmLastKey
    ; in our normal mode, lowercase should be converted to upper.
    cmp #$E0    ; < 'a' ?
    bcc @nocvt  ; -> no
    cmp #$FA    ; >= '{'  
    bcs @nocvt
    sec
    sbc #$20
@nocvt:
NrmCmdExec:
    bit CaptureFlag ; Are we capturing a movement instead of moving?
    bpl NrmUnsafeCommands   ; -> no, check all commands
    jmp NrmSafeCommands     ; -> yes, skip modifying commands
; START of line-modifying/not-just-movement commands
NrmUnsafeCommands:
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
    sta AppendModeFLag ; so exiting insert mode drops cursor back one char
    jsr TryGoRightOne
@atEnd:
    jmp EnterInsertMode
@nf:
NrmMaybeDorC:
    cmp #$C4 ; 'D'
    beq @doCapture
    cmp #$C3 ; 'C'
    bne @nf
@doCapture:
    sta CaptureFlag ; indicate that we're capturing for a delete
    stx CapturePos
    lda #PromptCaptureChar
    jsr ChangePrompt
    jmp NormalMode ; do NOT reset, because we're capturing now.
@nf:
NrmMaybeSorX:
    cmp #$D3 ; 'S'
    beq @doIt
    cmp #$D8 ; 'X'
    bne @nf
@doIt:
    ; equivalent to forward-one-then-BS, unless at end of line
    cpx LineLength
    beq @fail
    inx
    lda #$A0 ; SP - just print anything at all for position's sake,
             ; we're about to BS over it anyhow
    jsr COUT
    jsr Backspace
@fail:
    lda NrmLastKey
    cmp #$D3 ; 'S'
    beq @doSubst
    jmp ResetNormalMode ; X
@doSubst:
    ; Yes, we do this even if deleting forward failed (= we're EOL)
    jmp EnterInsertMode
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
NrmMaybeCtrlG:
    cmp #$87 ; C-G
    bne @nf
    ; Fetch a line of BASIC (_if_ we're a BASIC prompt)
    ;  from the number at the start of the buffer
    jsr MaybeFetchBasicLine
    ; Kill any current repeat
    lda #0
    sta RepeatCounter
    jmp ResetNormalMode
@nf:
NrmMaybeCtrlN:
    cmp #$8E ; C-N
    bne @nf
    ; Go to next line of BASIC (if we're already in one)
    lda CurBasicLine+1
    beq @bad ; -> we're not in a line of BASIC right now. BELL.
    ; (If there's a "current line of BASIC", we don't have to check if
    ;  we're "in BASIC")
    lda CurBasicLine
    sta LOWTR
    lda CurBasicLine+1
    sta LOWTR+1
    ldy #1
    ; Check high byte of "next line" link
    lda (LOWTR),y
    beq @bad ; -> no next line. BELL.
    ; "Next" link is good, copy to LOWTR
    sta @saveHack
    dey
    lda (LOWTR),y
    sta LOWTR
@saveHack = *+1
    lda #$00 ; MODIFIED above
    sta LOWTR+1
    ; Now check the new "next" link.
    ldy #1
    lda (LOWTR),y
    beq @bad ; Empty "next" link; we're past the last line (bad).
    jsr DetokenizeLine
    ; NOTE: repeats are _allowed_ (when successful).
    jmp ResetNormalMode
@bad:
    jsr BELL
    ; don't repeat if we hit the end, so we don't spam BELLs
    lda #0
    sta RepeatCounter
    jmp ResetNormalMode
@nf:
NrmMaybeCtrlX:
    cmp #$98
    bne @nf ;-> try 'nother char
    ; XXX - if EnterInsertMode does cleanup, we should do that
    ;  here as well, as we're leaving NormalMode
    jmp DoAbortLine
@nf:
NrmMaybeCtrlZ:
    cmp #$9A
    bne @nf ;-> try 'nother char
    lda #$0
    sta RepeatCounter ; Don't repeat version shows
    jsr ShowVersion
    jmp ResetNormalMode
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
NrmMaybeNumForward:
    cmp #$A3 ; # ?
    bne NumForwardSkip
    ; Mark the search
    lda #$FF
    sta AmSearchingNums
NumForward:
    stx SaveA ; never mind name
    jsr MoveForwardNumber
    bit CaptureFlag
    bmi @skipPr
    jsr PrintForwardMoveFromSaveA
@skipPr:
    jmp ResetNormalMode
NumForwardSkip:
NrmMaybeSemicolon:
    cmp #$BB ; semicolon (;) ?
    bne @nf
    bit AmSearchingNums
    bmi NumForward
    jmp ResetNormalMode
@nf:
NrmMaybeComma:
    cmp #$AC ; ','
    bne @nf
    bit AmSearchingNums
    bpl @notSrchNums
    stx @origPos
    jsr MoveBackNumber
    bit CaptureFlag
    bmi @skipPr
    ; update the cursor on the line if not capturing the movement
    stx @newPos
@origPos = * + 1
    lda #$00 ; OVERWRITTEN
    sec
@newPos = * + 1
    sbc #$00 ; OVERWRITTEN
    tay
    jsr EmitYCntBsp
@skipPr:
@notSrchNums:
    jmp ResetNormalMode
@nf:
;; Check for "CC" and "DD"
NrmMaybeLineKill:
    bit CaptureFlag
    bpl @nf ; -> Not capturing, skip
    cmp CaptureFlag
    bne @nf ; -> Not repeated capture character, skip
    jsr BackspaceToStart ; Backspace to beginning
    ldx #$0
    stx CapturePos ; Overwrite "original position" to beginning
    ldx LineLength ; And set our current position to the end.
    jmp ResetNormalMode
@nf:
NrmMaybeZero:
    cmp #$B0 ; 0
    bne @nf
    lda RepeatCounter
    beq @notCtr
    lda #$0
    beq NrmHandleDigit ; if we're actively counting repeats, go there
@notCtr:
    ; Otherwise we're going to the beginning of the line.
    bit CaptureFlag
    bmi @skipPr
    jsr BackspaceToStart
@skipPr:
    ldx #0
    jmp ResetNormalMode
@nf:
NrmMaybeDigit:
    ; Check to see if a repeat counter is being typed.
    ; Note that we check for 0 here, but 0 also gets checked just above
    ; us. That's okay - if it detects an active counter, it redirects
    ; to us.
    cmp #$B0
    bcc NrmMaybeDigitOut ; < '0', don't handle
    cmp #$BA
    bcs NrmMaybeDigitOut ; > '9' (>= ':'), don't handle
NrmHandleDigit: ; the "other" '0'-handler redirects here
    and #$0F ; we just want the digit value now
    pha
        lda RepeatCounter
        beq @skipMul
        ; Multiply the existing count by ten, since we're tacking
        ;  on a new digit
        asl
        pha
            ; A * 8 ...
            asl
            asl
            sta RepeatCounter
        pla
        ; ... + A * 2 ...
        clc
        adc RepeatCounter
        sta RepeatCounter
@skipMul:
    ; ... + new digit.
    pla
    clc
    adc RepeatCounter
    sta RepeatCounter
    ;
    jmp NormalMode ; NOT reset - we collect digits until a real command
                   ;  is typed.
NrmMaybeDigitOut:
NrmMaybeEol:
    cmp #$A4 ; $
    bne @nf
    bit CaptureFlag
    bmi @skipPr
    jsr PrintRestOfLine
@skipPr:
    ldx LineLength
    jmp ResetNormalMode
@nf:
NrmMaybeCarat:
    cmp #$DE ; '^'
    bne @nf
    bit CaptureFlag
    bmi @skipPr
    jsr BackspaceToStart
@skipPr:
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
    bit CaptureFlag
    bmi @skipPr
    jsr PrintForwardMoveFromSaveA
@skipPr:
    jmp ResetNormalMode
NrmMaybeWOut:
;
NrmMaybeB:
    cmp #$C2 ; 'B'
    bne @nf
    stx SaveA ; nevermind the name...
    jsr MoveBackWord
    bit CaptureFlag
    bmi @skipPr
    ; update the cursor on the line if not capturing the movement
    stx SaveX
    lda SaveA
    sec
    sbc SaveX
    tay
    jsr EmitYCntBsp
@skipPr:
    jmp ResetNormalMode
@nf:
NrmMaybeE:
    cmp #$C5 ; 'E'
    bne @nf
    stx SaveA ; nevermind the name...
    jsr MoveForwardWordEnd
    bit CaptureFlag
    bmi @skipPr
    jsr PrintForwardMoveFromSaveA
@skipPr:
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
    ; If we have an active repeat going, save us some trouble
    ; and kill the loop.
    lda #$0
    sta RepeatCounter
    ;jsr BELL
    jmp ResetNormalMode
CaptureFlag:
    .byte $00
CapturePos:
    .byte $00
PostCapturePos:
    .byte $00
PosDiff:
    .byte $00 ; the positive positional difference in a movement
RestorePrompt:
    lda PROMPT
    ; fall through
ChangePrompt:
    cmp #$80 ; New prompt NUL?
    beq CPbail
    pha
        lda PROMPT
        cmp #$80 ; Official prompt NUL?
        beq CPbail2
    pla

    sta SavePrompt
    jsr BackspaceToStart
    ; one more BS gets us onto the prompt.
    lda #$88
    jsr COUT
SavePrompt = * + 1
    lda #$DC
    jsr COUT
    jmp PrintStartToX
CPbail2:
    pla
CPbail:
    rts
TryGoLeftOne:
    ; Try to go left.
    cpx #0
    bne @skipRts
    rts
@skipRts:
    ; go left!
    dex

    bit CaptureFlag
    bpl @update
    rts
@update:
    lda #$88
    jmp COUT ; emit BS
TryGoRightOne:
    ; Try to go right.
    cpx LineLength
    beq @rts
    cpx #kMaxLength
    beq @rts
    bit CaptureFlag
    bmi @skipPr
    lda IN,x
    ; go right! print the current char to move.
    jsr ViPrintChar
@skipPr:
    inx
@rts:
    rts
GetIsWordOrNum:
    cmp #$AD ; dash (-) ?
    beq GiwcRts
    cmp #$AE ; period (.) ?
    beq GiwcRts
GetIsWordChar:
    ; Exits with carry set if Areg is a word char
    ;
    ; XXX crude version, ignores some kinds of punctuation.
    ; Should be: word is everything that's not punctuation, space, or control
    ; (leaving alphanum).
    ; XXX is: word is everything >= #$C1
    cmp #$C1
    bcs GiwcAlphaArea ; -> we _might_ be an alphabetic character
    ; We're in the non-alpha section. Are we a number?
GetIsDigit:
    cmp #$B0 ; >= '0' ?
    bcc GiwcRts ; -> No. We can't be a word char, then.
    cmp #$BA ; > '9' (>= ':')?
GiwcReverseCarryAndReturn:
    rol
    eor #$01
    ror
GiwcRts:
    rts
GiwcAlphaArea:
    and #$DF ; get rid of any lowercase bit
    cmp #$DB ; > 'Z' (>= '[')?
    jmp GiwcReverseCarryAndReturn
;
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
MoveBackNumber:
    stx @saveX
    jsr MoveBackWhileNotDigit
    cpx #0
    beq @giveUp ; give up if there was only non-digit space to back over
    jmp MoveBackWhileDigit
@giveUp:
@saveX = * + 1
    ldx #$00 ; OVERWRITTEN
    rts
MoveBackWord:
    stx @privSave
    jsr BackWhileNotWord
    cpx #0
    beq @giveUp ; give up if there was only non-word space to back over
    jmp BackWhileWord
@giveUp:
@privSave = * + 1
    ldx #$00 ; OVERWRITTEN
    rts
MoveBackWhileNotDigit:
    lda #$B0
    bne MoveBackWhileDigit_
MoveBackWhileDigit:
    lda #$90
MoveBackWhileDigit_:
    sta @op
    cpx #0
    beq @rt
@lp:
    dex
    lda IN,x
    jsr GetIsDigit
@op = *
    bcc @notDigit ; OPCODE may get overwritten!
    cpx #0
    bne @lp
@rt:
    rts ;
@notDigit:
    inx
    rts
MoveWhileDigit:
@lp:
    cpx LineLength
    beq @done
    lda IN,x
    jsr GetIsDigit
    bcc @done
    inx
    bne @lp
@done:
    rts
MoveWhileNotDigit:
@lp:
    cpx LineLength
    beq @done
    lda IN,x
    jsr GetIsDigit
    bcs @done
    inx
    bne @lp
@done:
    rts
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
MoveForwardNumber:
    stx @saveX
    jsr MoveWhileDigit
    jsr GetIsDigit
    bcs @bail ; -> we never escaped a number we were in; we failed
    jsr MoveWhileNotDigit
    jsr GetIsDigit
    bcc @bail ; -> we never reached a new number; we failed
    rts ; SUCCESS!
@bail:
@saveX = * + 1
    ldx #$00 ; OVERWRITTEN
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
    bit CaptureFlag ; Capture mode changes word end to _past_ the word
    bmi @done
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

    ; Augh! What do we do here? We can't RTS and keep processing as
    ; usual (we could have come from ReadDelay, for instance),
    ; but neither can we just jmp to ViModeGetline - we have an unknown
    ; number of call returns on the stack between us and it.
    ; Could do like DOS, and save stack position on ViModeEntry?
    ; .... yeah, think we'll go with that.
    ldx SaveS
    txs
    jsr CROUT ; Send a CR, as GETLN would
    jmp ViModeGetlineInternal
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
ShowVersion:
    stx @mySaveX
    ;; Erase the visible line
    jsr BackspaceToStart
    lda LineLength
    tay
    jsr EmitYCntSpaces
    ;; Return cursor to start of prompt
    ldx LineLength
    jsr BackspaceToStart
    ;; Print the version string, including final backslash and CR
    ldy #0
@versLp:
    lda ViModeVersion,y
    beq @versDone
    jsr COUT
    iny
    bne @versLp
@versDone:
    ;; Restart the prompt (which prompt depending what mode
    ;;   we were, as well as what "real" prompt is ($80 gets no prompt))
    lda PROMPT
    cmp #$80
    beq @skipPrompt
    lda SavePrompt
    jsr COUT
@skipPrompt:
    ;; Redraw the line
    ldx #0
    jsr PrintRestOfLine
    ;; Replace cursor where it belongs
    lda LineLength
    sec
    sbc @mySaveX
    tay
    jsr EmitYCntBsp
    ldx @mySaveX
    rts
@mySaveX:
    .byte 0
LineNumberToLow:
    txa
    tay
@lp:
    lda IN,y
    and #$7F
    cmp #$20
    beq @st
    cmp #$30
    bcc @rt ; A < '0' and != SPC? done
    cmp #$3A
    bcs @rt ; A > '9' (>= ':') and != SPC? done
@st:
    sta IN,y
    iny
    bne @lp
@rt:
    rts
LineNumberToHigh:
    txa
    tay
@lp:
    lda IN,y
    bmi @rt
    ora #$80
    sta IN,y
    iny
    bne @lp
@rt:
    rts
MaybeFetchBasicLine:
    stx @saveX
    ; Are we in BASIC?
    bit ViPromptIsBasic
    bpl @bel
    ; Are we on or just after a number?
    lda IN,x
    jsr GetIsDigit
    bcs @haveDig
    cpx #0
    beq @bel
    dex
    lda IN,x
    jsr GetIsDigit
    bcc @bel
@haveDig:
    jsr MoveBackWhileDigit
    ; Unset low bits from start of line to first non-space, non-digit
    jsr LineNumberToLow
    ; Set up TXTPTR to input buffer
    txa
    clc
    adc #<IN
    sta TXTPTR
    lda #>IN
    adc #0
    sta TXTPTR+1
    jsr CHRGOT
    bcs @bel ; > bail, the first char in input buffer isn't a digit...
    jsr LINGET
    jsr FNDLIN
.if 1
    bcc @bel ; bail, no such line number
.else
    ;; I wrote this, but immediaely abandoned it for "go to line at
    ;;  cursor", as otherwise one may mistakenly believe we successfully
    ;;  followed a dangling line number reference

    ; Whether it succeeded in finding "the" number or not, it will have
    ; left the line after it in LOWTR; let's get that one instead
    ldy #1
    lda (LOWTR),y
    beq @bel ; ->Ah! no... it was higher than the last line. Bell and bail.
.endif
    ;; Yes! We found it! Now run our custom detokenizer to fill the line
@saveX = * + 1
    ldx #$00 ; OVERWRITTEN
    jmp DetokenizeLine
@bel:
    jsr BELL
    ; Reset the hight bits of things again
    jsr LineNumberToHigh
    ldx @saveX
    rts
DetokenizeLine:
    ;; Clear out the existing line (and its display)

    ; Er, we could wait to clear out until we've refilled it, and then
    ; spew out extra spaces if we need to fill out the rest of the
    ; previous display, but... meh.
    jsr BackspaceToStart
    txa
    pha ; pulled up at end of DetokenizeLine
    ldx #0
    ldy LineLength
    jsr EmitYCntSpaces
    ldy LineLength
    jsr EmitYCntBsp
    stx LineLength
    ;; Make a note of our currently-edited BASIC line, for Ctrl-P and Ctrl-N
    lda LOWTR
    sta CurBasicLine
    lda LOWTR+1
    sta CurBasicLine+1
    ;; Get the line number into the buffer
    ; First, copy the (raw) line number into FAC
    ;  (stored in reverse order)
    ldy #2
    ldx #0
    lda (LOWTR),y
    sta FAC+2
    iny
    lda (LOWTR),y
    sta FAC+1
    txa
    pha
        ldx #$90 ; exponent = 2^16
        sec
        jsr FLOAT_2 ; XXX can I depend on this location?
        jsr FOUT
    pla
    tax
    ldy #0
@lnumLp:
    lda $100,y
    beq @lnumDn
    ora #$80
    sta IN,x
    inx
    iny
    bne @lnumLp
@lnumDn:
    lda #$A0
    sta IN,x
    sta DetokLastC
    inx
    ;; Skip the "next" pointer and line number
    lda LOWTR
    clc
    adc #4
    sta LOWTR
    lda LOWTR+1
    adc #0
    sta LOWTR+1
    ldy #0
@lineLoop:
    ;; Grab the next token
    lda (LOWTR),y
    bne :+
    jmp @finishUp
:
    sta DetokCurT
    bmi @handleToken; -> token code, process it
    ora #$80
    sta DetokCurC
    jsr DetokMaybeInsertSpace
    cpx kMaxLength
    bne :+
    jmp @outOfRoom
:
    lda DetokCurC
    sta IN,x
    inx
    cpx kMaxLength
    bne @loopIter
    jmp @outOfRoom ; Line too long: truncate.
@handleToken:
    stx SaveX
    sty SaveY
    ;; Go searching for the token
    sec
    sbc #$7F ; convert token -> table idx (+1, for initial dex)
    tax      ;  and store that in X-reg
    ; Set up FAC to be a pointer to the token table (no one else is
    ;  using it, and anyway this is how LIST does it)
    ldy #<TOK_TABLE
    sty FAC
    ldy #(>TOK_TABLE)-1 ; first GETCHR will bump
    sty FAC+1
    ldy #$FF ; Y-reg is our scanner
@fndTokLp:
    dex
    beq @fndTokDn
@skipTok:
    jsr GETCHR
    bpl @skipTok
    bmi @fndTokLp
@fndTokDn:
    ldx SaveX
    ;; Print out the token
    jsr GETCHR ; Get first char
    sta SaveA
    ora #$80 ; char -> printable
    sta DetokCurC
    jsr DetokMaybeInsertSpace ; now that we have the char to compare
    cpx kMaxLength
    beq @outOfRoom
    lda DetokCurC
    sta IN,x
    inx
    cpx kMaxLength
    beq @outOfRoom
    lda SaveA ; restore with original high bit
    bmi @lastDone
    ; second char
@insTokNextChar:
    jsr GETCHR
    sta SaveA
    ora #$80
    sta IN,x
    inx
    cpx kMaxLength
    beq @outOfRoom
    lda SaveA
    bpl @insTokNextChar
@lastDone:
    sta DetokCurC ; for next token's maybe-insert-space
    ldy SaveY
@loopIter:
    lda DetokCurC
    sta DetokLastC
    lda DetokCurT
    sta DetokLastT
    iny
    jmp @lineLoop
@finishUp:
    lda #$8D
    sta IN,x
    stx LineLength
    ldx #0
    jsr PrintRestOfLine
    ldy LineLength
    jsr EmitYCntBsp
    ;; Restore original cursor pos
    ;;  (and update screen)
    pla ; restore original cursor pos
    tay
    cpy LineLength
    bcc :+
    ldy LineLength
:
    jsr PrintYNextChars
    tya
    tax
    rts
@outOfRoom:
    ; XXX: retry without added spaces? garbage the line #?
    ;  print special chars at end to flag the truncation?
    ;  beep?
    beq @finishUp
DetokMaybeInsertSpace:
    lda DetokLastT
    ora DetokCurT
    ; If both the current and prev char were ordinary chars,
    ;  we MUST NOT emit a space. Could be in a string literal, or REM!
    bpl @no
@atLeastOneTok:
    lda DetokCurC
    cmp #$A0
    beq @no ; -> No. We're _about_ to emit a space.
    lda DetokLastC
    cmp #$A0
    beq @no ; -> Last char was already a space. Bail.
    jsr GetIsWordChar
    bcc @no ; -> No space. Never need a space after punctuation.
    lda DetokLastT
    ; No matter what, never emit a space after REM. One will be included
    ;  if desired.
    cmp #$B2 ; REM ?
    beq @no
    ;
    lda DetokCurC
    jsr GetIsWordOrNum
    ; When at least one is a token, and both are word chars,
    ;  ALWAYS emit a space.
    bcs @yes
    ; If we're here, preceding token ended with word char, and
    ;  current char is non-word
    lda DetokCurC
    cmp #$BA ; colon (:) ?
    beq @no ; colons never need a space.
    cmp #$BD
    beq @no ; no spaces before =, either
@lastWasTok:
    ; is prev a math fn, and we're a left-paren?
    cmp #$A8 ; '(' ?
    bne @yes ; anything else gets a space before its argument (or
             ;  before random garbage)
    ; We're a left-paren. Was prev a function?
    lda DetokLastT
    cmp #$D2
    bcs @no ; Yes; we don't need a space.
    ; Otherwise, we do.
@yes:
    lda #$A0
    sta IN,x
    inx
@no:
    rts
DetokCurC: ; current char (screen code)
    .byte 0
DetokCurT: ; last-emitted tok
    .byte 0
DetokLastC: ; last-emitted char (screen code)
    .byte 0
DetokLastT: ; last-emitted tok
    .byte 0
CurBasicLine:
    .word 0
RepeatCounter:
    .byte 0
NrmLastKey:
    .byte 0
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
AppendModeFLag:
    .byte 0
AmSearchingNums:
    .byte 0
SearchChar:
    .byte 0
ViPromptIsBasic:
    .byte 0

; The generated version string
.include "version.inc"

