; Copyright 2022 Micah J Cowan <micah@addictivecode.org>
; MIT license (see accompanying LICENSE.txt)

CH = $24
BASE = $28
INVFLAG = $32

IN = $200
CLREOL = $FC9C
RDKEY = $FD0C
KEYIN = $FD1B
PRBYTE = $FDDA
COUT = $FDED
BELL = $FF3A

RET_RDCHAR = $FD37
RET_GETLINE= $FD77

;DEBUG=1

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
RealInput:
    ; keyboard input. This immediate-jmp routine exists
    ; to make it easy to swap the keyboard input for some other
    ; KSW routine, as needed.
    jmp KEYIN
.ifdef DEBUG
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
InitViModeAndDoKeyin:
    jsr InitViMode
    lda SaveA
    ldx SaveX
    jmp RealInput
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
    jmp CLREOL ; ensure that everything on our line is actually
               ; in the input buffer, as well as on screen...
               ; by clearing the line out that we're on.
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
    jmp InitViModeAndDoKeyin
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
    ; We never reach here. But it's here anyway, in case anyone ever
    ; wants to _explicitly_ call our GetLine...
    ; TODO: write the prompt and stuff like GetLine does. 
    ;       Also, set up X-reg.
    jsr InitViMode
    ; fall through to InsertMode
InsertMode:
    ; INSERT MODE.
    jsr RDKEY
ViModeEntry:
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
    jsr TryInsertChar
    jmp InsertMode
ControlChar:
    cmp #$88 ; backspace?
    beq TryDoBS
    cmp #$8D
    beq DoCR
    ; Print and store control chars too
    jsr TryInsertChar
    jmp InsertMode
TryDoBS:
    ; (Fuck what Yoda says, sometimes there is too try.)
    cpx #0 ; Are we trying to BS over the beginning? Wail about it
    bne DoBS
    ;jsr BELL
    jmp InsertMode
DoBS:
    dex
    ; BS-SP-BS to delete char under cursor portably.
    lda #$88
    jsr COUT
    lda #$A0
    jsr COUT
    lda #$88
    jsr COUT
    jmp InsertMode
DoCR:
    pha
    jsr COUT
    ; Restore the check for GETLN
    lda #<CheckForGetline
    sta InputRedirFn
    lda #>CheckForGetline
    sta InputRedirFn+1
    pla
    rts
TryInsertChar:
    ; XXX ensure we don't try inserting when the buffer is too full!
    ; XXX detect if we've rolled over to a new line, and CLREOL if
    ; necessary - keeping in mind we may not be the end of the input
    ; line if we're inserting within it.

    ; If we're here we are definitely inserting.
    inc LineLength
    sta IN,x
    inx
    cmp #$A0
    bcc InsControlChar
    jmp COUT
InsControlChar:
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
SaveA:
    .byte 0
SaveX:
    .byte 0
SaveY:
    .byte 0
SaveSearchX:
    .byte 0
LineLength:
    .byte 0
TmpWord:
    .word 0
