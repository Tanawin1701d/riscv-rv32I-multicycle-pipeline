 ; this is a comment
addi r1 r1 1
slli r2 r1 15
slli r3 r1 31
ori  r4 r4 128
or   r4 r4 r2
or   r4 r4 r3
addi r10 r0 1024
; store
sb r10  -4 r4
sh r10  0 r4
sW r10  4 r4
; load for test load
lb r20 r10 4
lh r21 r10 4
lw r22 r10 4
    ; load with unsign
lbu r27 r10 4
lhu r28 r10 4
; load for test store
lw r25 r10 -4
lw r26 r10 0
