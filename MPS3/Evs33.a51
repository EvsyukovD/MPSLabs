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
; r1, r2 - buf registers

BASEADDRESS_A EQU 00h
BASEADDRESS_B EQU 04h
RES_ADDRESS EQU 20h
INDEX_ADDR EQU 21h ; address for storing index
MOV DPTR,#7FFAh
MOVX A,@DPTR;
MOV R2, A
MOV DPTR, #8000h
JB ACC.4, MET1
JNB ACC.4, PROGRAMM_C_0
MET1:
LJMP PROGRAMM_C_1
; if C = 0
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
RR A ; ACC.1 = B1, ACC.0 = B0
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
NUMBER_OF_ITERS EQU 0Ch ;16 - MASK_LENGTH + 1
MOV INDEX_ADDR, #00h; i = 0
MOV RES_ADDRESS,#00h ;init counter (use for this purpose result address)
COUNT_CYCLE:
MOV A, R5; load low bits
ANL A, #MASK
SUBB A, #SEQ ; check that last bits equal bit sequence
JNZ COUNT_NEXT
MOV A, RES_ADDRESS
INC A
MOV RES_ADDRESS, A
COUNT_NEXT:
CLR C; C = 0
MOV A, R6 ; A = high bits of 16-bit value
RRC A ; right shift of A, after which ACC.7 = 0 (because C = 0), 
      ; ACC.n = ACC.(n + 1) n = 0...6 and new C = ACC.0 (previous ACC.0)
	  ; we have made arithmetic shift where C equals previous ACC.0 
MOV R6, A ;save new high bits
MOV A, R5 ; A = low bits of 16-bit value
RRC A ; the same operation, but there prevous C is ACC.0 from high bits
      ; so we shift our 16-bit value to right and fill higher bits by 0
MOV R5, A ; save new low bits
MOV A, INDEX_ADDR
INC A
MOV INDEX_ADDR, A
MOV A, #NUMBER_OF_ITERS
CLR C; for calculating diff: NUMBER_OF_ITERS - i (without C)
SUBB A, INDEX_ADDR
JNZ COUNT_CYCLE

LJMP MOV_RESULT

; if C = 1
PROGRAMM_C_1:
; lets find maximum value in A array 
ANL A, #00000011b ; read A1A0
MOV R3, A
MOV A, #BASEADDRESS_A
ADD A, R3; upper board for maximum address in A array
MOV R3, A; save this board


MAX_A_ADDR EQU 22h ; address of maximum for A array
MAX_B_ADDR EQU 23h ; address of maximum for A array
; cycle for finding maximum
MOV INDEX_ADDR, #BASEADDRESS_A ; address of i
MOV MAX_A_ADDR, #00h; maximum value in array A
MAXIMUM_SEARCH_CYCLE_A:
MOV A, R3
SUBB A, INDEX_ADDR; check address <= R3
JBC PSW.7, FIND_MAX_ARRAY_B
MOV DPL, INDEX_ADDR
MOVX A, @DPTR; get A[i]
SUBB A, MAX_A_ADDR
JBC PSW.7, NEXT_INDEX_A
MOVX A, @DPTR
MOV MAX_A_ADDR, A; new maximum value
NEXT_INDEX_A:
MOV A, INDEX_ADDR
INC A; increment i
MOV INDEX_ADDR, A; save new i
JMP MAXIMUM_SEARCH_CYCLE_A

FIND_MAX_ARRAY_B:
; lets find maximum value in B array
MOV A, R2
ANL A, #00001100b; read B1, B0
RR A
RR A ; ACC.1 = B1, ACC.0 = B0
MOV R4, A
MOV A, #BASEADDRESS_B
ADD A, R4; upper board for maximum address in B array
MOV R4, A; save this board
; cycle for finding maximum
MOV INDEX_ADDR, #BASEADDRESS_B ; address of i
MOV MAX_B_ADDR, #00h; maximum value in array B
MAXIMUM_SEARCH_CYCLE_B:
MOV A, R4
SUBB A, INDEX_ADDR; check address <= R4
JBC PSW.7, CALCULATE_AND
MOV DPL, INDEX_ADDR
MOVX A, @DPTR; get B[i]
SUBB A, MAX_B_ADDR
JBC PSW.7, NEXT_INDEX_B
MOVX A, @DPTR
MOV MAX_B_ADDR, A; new maximum value
NEXT_INDEX_B:
MOV A, INDEX_ADDR
INC A; increment i
MOV INDEX_ADDR, A; save new i
JMP MAXIMUM_SEARCH_CYCLE_B

CALCULATE_AND:
MOV A, MAX_A_ADDR
ANL A, MAX_B_ADDR
MOV RES_ADDRESS, A

MOV_RESULT:
MOV A, RES_ADDRESS
MOV R1, A
MOV P4, R1

HANDLE_END:
;end of interrupt process
RETI
END