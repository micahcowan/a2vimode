.org $300

; snatch a look at what DOS thinks "real" KSW is, and implant that.
lda $AA56
cmp #$60 ; skip if high byte is $60 (uh, us).
beq Skip
sta $6008
lda $AA55
sta $6007
Skip:
; Ensure it's in check-for-GETLN mode
lda $6004
sta $6001
lda $6005
sta $6002
; Install KSW
lda #0
sta $38
lda #$60
sta $39
jmp $3EA ; re-hook-up DOS
