; Copyright 2022 Micah J Cowan <micah@addictivecode.org>
; MIT license (see accompanying LICENSE.txt)

.macpack apple2

CH = $24
CV = $25
BASE = $28
INVFLAG = $32
PROMPT = $33

IN = $200
VTAB = $FC22
VTABZ = $FC24
CLREOL = $FC9C
RDKEY = $FD0C
KEYIN = $FD1B
PRBYTE = $FDDA
COUT = $FDED
SETINV = $FE80
SETNORM = $FE84
BELL = $FF3A

RET_RDCHAR = $FD37
RET_GETLINE= $FD77

DEBUG=1

.ifndef DEBUG
kMaxLength = $FE
.else
kMaxLength = $30 ; 48
.endif

.org $6000

Input:
InputRedirFn = * + 1
    ; The address of the following JMP will be _rewritten_
    ; to jump directly to keyboard inputs, when GETLINE
    ; has been detected (and replaced). It will be restored
    ; to CheckForGetline once our replacement GETLINE routine
    ; has exited (so that future inputs once again check for
    ; GETLINE)
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
    lda CV
    sta SavedCV
    lda #0
    sta CH
    sta CV
    jsr VTABZ

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
    lda SavedCV
    sta CV

    ldx SaveX

    jmp VTABZ
@xPr:
    pha
    jsr SETNORM
    pla
    jsr PRBYTE
    jsr SETINV
    jmp @sp
StatusBarOn:
    .byte $FF
ToggleStatusBar:
    lda StatusBarOn
    eor #$FF
    sta StatusBarOn
    bmi @done
    ; We just switched status bar off; go and erase it
    lda CH
    sta SavedCH
    lda CV
    sta SavedCV

    lda #0
    sta CH
    sta CV
    jsr VTABZ

    jsr CLREOL

    lda SavedCH
    sta CH
    lda SavedCV
    sta CV
    jsr VTABZ
@done:
    rts
PrintStack:
    ; This is for debugging, but... calling it from within a DOS call
    ; will probably munge things
    sta @SvA
    stx @SvX
    sty @SvY
    lda BASE
    sta @SvBASE
    lda BASE+1
    sta @SvBASE+1
    lda CH
    sta @SvCH
    lda #0
    sta CH
    sta BASE
    lda #$4
    sta BASE+1
    tsx
    inx ; Skip over our own call
    inx
    inx
    ldy #6
@Lp:
    lda #$A0
    jsr COUT
    lda $100,x
    jsr PRBYTE
    inx
    dey
    bne @Lp
    ;
    jsr CLREOL
    lda @SvBASE
    sta BASE
    lda @SvBASE+1
    sta BASE+1
    lda @SvCH
    sta CH
    lda @SvA
    ldx @SvX
    ldy @SvY
    rts
@SvA: .byte 0
@SvX: .byte 0
@SvY: .byte 0
@SvBASE: .word 0
@SvCH:.byte 0
.endif ; DEBUG
CheckForGetline:
    ; Have a peek up our stack to see if our key-input
    ; routine has been called from GETLINE (via RDCHAR, and 
    ; possibly a DOS or ProDOS KSW hook). If it has,
    ; we (a) remove the return to RDCHAR entirely
    ; (it does special ESC-key processing that we wish
    ; to subvert!), and (b) replace the return to GETLINE with
    ; a return back to our GETLINE-replacement routine instead! >:-]

    ; We check for one of two scenarios: either the GETLINE and RDCHAR
    ; return addresses are _immediately_ behind us (no DOS hooks),
    ; or they are two bytes back, with an intervening DOS hook between.
    sta SaveA
    stx SaveX
    tsx
    inx
    jsr FindGetlineHere
    bne TryOneCallBack ; We didn't find it, try a couple bytes back
    ; Found it! with no DOS hooks or indirects
    ; ...just remove the last two returns, and set us up to return
    ;  to _our_ GETLINE
    pla
    pla
    pla
    pla
    lda #>(ViModeEntry-1)
    pha
    lda #<(ViModeEntry-1)
    pha
InitViModeAndGetStarted:
    ;lda SaveA - no, this should always be a space, since we cleared.
    ; We're KSW, but we're returning to restart the prompt with a "real"
    ; KSW. Just load SPACE and return, hopefully the DOS hook doesn't
    ; care the value
    lda #$A0
    rts
TryOneCallBack:
    inx
    inx
    jsr FindGetlineHere
    beq FoundOneBack ; we found it a couple bytes up the stack; handle
    lda SaveA
    ldx SaveX
    jmp RealInput ; we didn't find it, so just do a normal keyboard input
FoundOneBack:
    ; We want to delete the returns to RDCHAR and GETLINE, and
    ; replace with ViModeEntry; but we still want to return to
    ; whatever DOS hook or whatever called us _first_. Then _that_ can
    ; return to ViMode.
    ;
    ; ALSO - it's not safe to actually delete anything from the
    ; callstack - the DOS hook is liable to RESTORE it before it exits!
    ; So instead we replace RDCHAR's return with a reference
    ; directly to a RTS - a return is still there, but RDCHAR
    ; is successfully elided.

    ; First, overwrite the RDCHAR retval with a harmless RTS
    lda #<(KnownRTS-1)
    sta $100,x
    inx
    lda #>(KnownRTS-1)
    sta $100,x
    ; Then overwrite GETLINE return with ours
    inx
    lda #<(ViModeEntry-1)
    sta $100,x
    inx
    lda #>(ViModeEntry-1)
    sta $100,x
    jmp InitViModeAndGetStarted
FindGetlineHere:
    ; trounces A (presumed to be saved), but preserves X
    stx SaveSearchX
    sty SaveY
    ldy #0
@lp:
    lda GetlineID,y
    beq @out ; complete match!
    cmp $100,x
    bne @out ; not a match, exit
    ; match so far, try next byte
    inx
    iny
    bne @lp
@out:
    php
    ldy SaveY
    ldx SaveSearchX
    plp ; preserve Z flag (EQ/NE)
KnownRTS:
    rts
GetlineID:
    ; bytes that represent call-returns to RDCHAR and GETLINE
    .byte $37, $FD, $77, $FD, $00


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
    ; Fill the inbuf with CRs
    lda #$8D
    ldx #0
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
    scrcode "AWEF ", 0, "AWEF AWEF"
    .byte 0
.endif
InsertMode:
.ifdef DEBUG
    jsr PrintState
.endif
    ; INSERT MODE.
    jsr RDKEY
    ; We enter here via return from CheckForGetLine (when GETLN
    ; was found)

    ; Did we get a printable char? Just, ehm, print it.
    cmp #$A0
    bcc ControlChar
    cmp #$FF ; DELETE? treat like backspace
    beq TryDoBS
    ; We're printable! print (and store) us.
    ; TODO: if we're a model that doesn't have lowercase, we should
    ;  upper-bound it too, and force to caps like Apple ][+ does.
    jmp TryInsertChar
ControlChar:
.ifdef DEBUG
MaybeTab:
    cmp #$89 ; Tab?
    bne @nf ;-> try 'nother char
    jsr ToggleStatusBar
    jmp InsertMode
@nf:
.endif
MaybeEsc:
    cmp #$9B ; ESC?
    bne @nf ;-> try 'nother char
    jmp EnterNormalMode
@nf:
MaybeLeftArrow:
    cmp #$88 ; left-arrow?
    bne @nf ;-> try 'nother char
    jsr TryGoLeftOne
    jmp InsertMode
@nf:
MaybeRightArrow:
    cmp #$95
    bne @nf ;-> try 'nother char
    jsr TryGoRightOne
    jmp InsertMode
@nf:
MaybeCtrlX:
    cmp #$98
    bne @nf ;-> try 'nother char
    jsr PrintRestOfLine
    ldx LineLength
    lda #$A0
    jsr COUT
    lda #$DC ; '\'
    jsr COUT
    lda #$8D ; CR
    jsr COUT
    jmp ViModeGetline
@nf:
MaybeCtrlV:
    cmp #$96
    bne @nf ;-> try 'nother char
    ; do a direct read, and insert it, whatever it may be
    jsr RDKEY
    jmp TryInsertChar
@nf:
MaybeCR:
    cmp #$8D
    beq DoCR
    ; Unrecognized: we print and store uncrecognized control chars too
    jmp TryInsertChar
TryDoBS:
    ; (Fuck what Yoda says, sometimes there _is_ try.)
    cpx #0 ; Are we trying to BS over the beginning? Wail about it
    bne DoBS
NoRoomLeft:
NoRoomRight:
    ;jsr BELL
    jmp InsertMode
DoBS:
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
EnterNormalMode:
    lda #$AD ; '-'
    jsr ChangePrompt
    ; fall through to ResetNormalMode
ResetNormalMode:
    ; TODO: reset a command or movement-in-progress
NormalMode:
.ifdef DEBUG
    jsr PrintState
.endif
    jsr RDKEY
    ; in our normal mode, lowercase should be converted to upper.
    cmp #$E0    ; < 'a' ?
    bcc @nocvt  ; -> no
    cmp #$FA    ; >= '{' ?
    bcs @nocvt
    sec
    sbc #$20
@nocvt:
.ifdef DEBUG
NrmMaybeTab:
    cmp #$89 ; Tab?
    bne @nf
    jsr ToggleStatusBar
    jmp ResetNormalMode
@nf:
.endif
NrmMaybeCR:
    cmp #$8D ; CR
    bne @nf
    jmp DoCR
@nf:
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
NrmMaybeI:
    cmp #$C9 ; 'I'
    bne NormalUnrecognized
    ; fall through
EnterInsertMode:
    jsr RestorePrompt
    jmp InsertMode
NormalUnrecognized:
    ;jsr BELL
    jmp NormalMode
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
SaveA:
    .byte 0
SaveX:
    .byte 0
SaveY:
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
