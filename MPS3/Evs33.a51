ORG 0H
LJMP INIT
ORG 03H
LJMP HANDLE_INTERRUPT
INIT:
P4 EQU 0C0h
MOV IE,#10000001b; enable int0
MOV TCON, #1;1/0
WAIT_INTERRUPT:
MOV P4, A;
SJMP WAIT_INTERRUPT
HANDLE_INTERRUPT:
BASEADDRESS_A EQU 00h
BASEADDRESS_B EQU 04h
MOV DPTR,#7FFAh
MOVX A,@DPTR;
MOV R2, A
MOV DPTR, #8000h
JB ACC.4, PROGRAMM_C_1
; C = 0
PROGRAMM_C_0:

ANL A, #00000011b ; read A1A0
MOV R3, #BASEADDRESS_A
ADD A, R3 ; address of element in A array 
MOV DPL, A
MOVX A, @DPTR
MOV R3, A ; A[A1A0]

MOV A, R2 ;read [C,B1,B0,A1,A0]
ANL A, #00001100b; read B1,B0
RR A 
RR A ; get ACC.1 = B1, ACC.0 = B0
MOV R4, #BASEADDRESS_B
ADD A, R4 ; address of element in B array
MOV DPL, A
MOVX A, @DPTR
MOV R4, A ; B[B1B0]

MOV A, R3
; R4 = b, R3 = a
; build 16-bit value in R5 (low 8 bit) and R6(high 8 bit)
; build low bits for R5 in B
MOV C, ACC.7
MOV B.0, C

MOV C, ACC.6
MOV B.2, C

MOV C, ACC.5
MOV B.4, C

MOV C, ACC.4
MOV B.6, C

MOV A, R4

MOV C, ACC.0
MOV B.1, C

MOV C, ACC.1
MOV B.3, C

MOV C, ACC.2
MOV B.5, C

MOV C, ACC.3
MOV B.7, C

MOV R5, B ; R5 = B = b3,a4,b2,a5,b1,a6,b0,a7
;build high bit for R6 in B
MOV A, R3
MOV C, ACC.3
MOV B.0, C

MOV C, ACC.2
MOV B.2, C

MOV C, ACC.1
MOV B.4, C

MOV C, ACC.0
MOV B.6, C

MOV A, R4

MOV C, ACC.4
MOV B.1, C

MOV C, ACC.5
MOV B.3, C

MOV C, ACC.6
MOV B.5, C

MOV C, ACC.7
MOV B.7, C

MOV R6, B; R6 = B = b7,a0,b6,a1,b5,a2,b4,a3
; 16-bit value R6,R5
SEQ  EQU 00010101b
MASK EQU 00011111b
TMP_ADDRESS EQU 20h
MOV 20h,#00h
MOV A, R5
COUNT_CYCLE:
ANL A, #MASK
SUBB A, #SEQ ; check that last bits equal bit sequence
JNZ COUNT_NEXT
MOV A, 20h
INC A
MOV 20h, A
COUNT_NEXT:
CLR C; C = 0
MOV A, R6 ; A = high bits of 16-bit value
RRC A ; right shift of A, after which ACC.7 = 0 (because C = 0), 
      ; ACC.n = ACC.(n + 1) n = 0...6 and new C = ACC.0 (previous ACC.0)
	  ; we have made arithmetic shift where C equals previous ACC.0 
MOV R6, A ;save new high bits
MOV A, R5
RRC A ; the same operation, but there prevous C is ACC.0 from high bits
JZ MOV_RESULT
MOV R5, A ; save new low bits
JMP COUNT_CYCLE

MOV_RESULT:
MOV A, 20h
MOV R1, A
MOV P4, R1

LJMP HANDLE_END
; C = 1
PROGRAMM_C_1:
; r1, r2 - buf registers
;end of interrupt process
HANDLE_END:
MOV P4, R1
RETI
END