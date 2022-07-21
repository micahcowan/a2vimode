.org $300

; snatch a look at what DOS thinks "real" KSW is, and implant that.
lda $AA56
cmp #$60 ; skip if high byte is $60 (uh, us).
beq Skip
sta $6005
lda $AA55
sta $6004
Skip:
lda #0
sta $38
lda #$60
sta $39
jmp $3EA ; re-hook-up DOS
