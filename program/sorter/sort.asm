; init amt_data
; addi r1 r0 4
addi r1 r0 1
slli r1 r1 10

; a and b init
addi r14 r0 1
slli r14 r14 20
addi r15 r0 1
slli r15 r15 20
add  r15 r14 r15

;  section 1
addi r2 r0  2  ; int  batchSize = 2;
addi r3 r14 0  ; int* abSrc     = a;
addi r4 r15 0  ; int* abDes     = b;


; TODO while (batchSize <=  AMT_DATA) 54
.batchSetterLoop

addi r6  r0 0      ;mainStart = 0
add  r7  r6 r2     ;mainStop  = mainStart + batchSize
srli r17 r2 1     ;batchHalf = batchSize >> 1
add  r8  r6 r17    ;mid       = mainStart + batchhalf


; batch iteration

; TODO do branch  while (mainStart < AMT_DATA){ 44

.batchIterloop

addi r10 r6 0    ; int i = mainStart
addi r11 r8 0    ; int j = mid
addi r12 r6 0    ; int rid = 0

; compare loop
; TODO do branch while (i < mid || j < mainStop) 33
.mergeLoop

slt r19 r10 r8     ; i < mid
slt r20 r11 r7     ; j < mainStop

addi r22 r0  0
bne  8   r7 r11    ; j == mainstop   4
addi r22 r0  1     ;

addi r24 r0  0
bne  8   r10 r8    ; true if i == mid
addi r24 r0  1     ;

slli r30 r10 2     ; i << 2   i*4 to match byte
add  r30 r3  r30   ; 4
lw   r26 r30 0

slli r30 r11 2
add  r30 r3  r30
lw   r27 r30 0

.i_good_j_stop; main compare  (i<mid) && (j==mainStop)
and r21 r19 r22
beq .j_good_i_stop r21 r0
addi r29 r26 0
addi r10 r10 1
beq .save_value r0 r0

.j_good_i_stop
and r21 r20 r24
beq .i_good_j_good_sel_i r21 r0
addi r29 r27 0
addi r11 r11 1
beq .save_value r0 r0


.i_good_j_good_sel_i
slt r21 r26 r27
beq .i_good_j_good_sel_j r21 r0
addi r29 r26 0
addi r10 r10 1
beq .save_value r0 r0


.i_good_j_good_sel_j
addi r29 r27 0
addi r11 r11 1

.save_value
; end main compare
; write to destination
slli r13 r12 2
add  r13 r4  r13 ; 3
sw   r13 0   r29
addi r12 r12 1

slt r19 r10 r8     ; DO AGAIN i < mid
slt r20 r11 r7     ; DO AGAIN j < mainStop
or  r21 r19 r20
bne .mergeLoop r21 r0 ; while(i < mid || j < mainStop)

addi r6 r7 0   ;mainStart = mainStop;
add  r7 r6 r2  ;mainStop  = mainStart + batchSize;
add  r8 r6 r17 ;mid       = mainStart  +  (batchSize >> 1);

; todo jump back to branch
slt r21 r6 r1
bne .batchIterloop r21 r0

xor r3 r3 r4 ; swap(abSrc, abDes);
xor r4 r4 r3
xor r3 r4 r3

slli r2 r2 1 ; batchSize << 1;

; todo jump back to branch
slt r21 r1 r2 ; AMT_DATA < batchSize
beq .batchSetterLoop r21 r0

addi r31 r0 1