.org $300

lda #0
sta $38
lda #$60
sta $39
jmp $3EA ; re-hook-up DOS
