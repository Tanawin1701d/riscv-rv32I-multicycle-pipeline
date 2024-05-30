; this is a comment


addi r1 r1 -1
addi r2 r2 2
addi r3 r3 2
addi r0 r0 0

beq 8 r2 r3 ; 10
addi r20 r0 1 ; 14
bne 8 r1 r2 ;18
addi r21 r0 1 ; 1C
blt 8 r1 r2 ; 20
addi r22 r0 1 ; 24
bge 8 r2 r1 ; 28
addi r23 r0 1 ; 2C
bLTu 8 r1 r2 ; 30
addi r24 r0 1 ; 34
bGEU 8 r1 r2 ; 38
addi r25 r0 1 ; 3C