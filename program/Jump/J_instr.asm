; this is a comment

addi r1 r1 1024
addi r2 r2 512
sw r1 0 r2 ; addr 1024 with value = 512


lui   r25 8192   ;
auipc r26 8192   ;
jal   r27 8      ; 5
addi  r30 r30 48 ; 6   do not use r30
jalr  r28 r1 0   ; 7
addi  r31 r31 48 ; 8    do not use r31