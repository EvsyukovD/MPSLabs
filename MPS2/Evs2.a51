;F(X3,X2,X1,X0) == 1 <=> 1,4,6,8,9,11,14
ORG 0000h;
BASEADDRESS EQU 0011h;11h
RELATIVEADDRESS EQU 0004h;04h
LJMP MAIN

MAIN:
; init values for timer in every case: 1...5 sec wait
MOV 40H, #5 ;0;  make "table" for number of seconds for each tuple (x3,x2,x1,x0)
MOV 41H, #2 ;1
MOV 42H, #1 ;2
MOV 43H, #1 ;3
MOV 44H, #1 ;4
MOV 45H, #3 ;5
MOV 46H, #3 ;6
MOV 47H, #1 ;7
MOV 48H, #5;8
MOV 49H, #4;9
MOV 4AH, #1;10
MOV 4BH, #2;11
MOV 4CH, #1;12
MOV 4DH, #1;13
MOV 4EH, #1;14
MOV 4FH, #1;15
P4 EQU 0C0h
MOV DPTR, #8000h
MOV A,#04h ;0004h - relative address OFFSET
MOVX @DPTR, A 
MOV DPTR,#8004h
MOV A, #11h; 0011h - base address OFFSET
MOVX @DPTR, A
MOV A,  #01010010b
MOV DPTR, #8011h
MOVX  @DPTR, A		;0-7 truth table in ex memory
;MOV DPTR, #8001h
MOV A,  #01001011b
MOV DPTR, #8012h
MOVX @DPTR, A ;8-15 truth table in ex memory
CLR P4.0;
SETB P4.1;
MET1:
MOV DPTR,#7FFBh	;address isReady flag
isReady:		;check flag isReady
MOVX A,@DPTR	;read flag
ANL A,#01h		;select 0 bit
JZ isReady
MOV DPTR,#7FFAh	;addres of (x3,x2,x1,x0) tuple
MOVX A,@DPTR	;write tuple to A
MOV 20h, A		;write x3,x2,x1,x0 to 20h
; F(x3,x2,x1,x0) = ^x0 & x2 & x1 v ^x3 & ^x0 & x2 v ^x2 & ^x1 & x0 v x3 & ^x2 & (x0 v ^x1)
;X3 - 3, X2 - 2, X1 - 1, X0 - 0

MOV C, ACC.0 ;C = X0
CPL C;C = ^X0
ANL C, ACC.2; C = ^X0 & X2
ANL C, ACC.1; C = ^X0 & X2 & X1
MOV 20h.4, C; 03 = ^X0 & X2 & X1 -- 1

MOV C, ACC.3;C = X3
ORL C, ACC.0; C = X3 V X0
CPL C; C = ^X3 & ^X0
ANL C, ACC.2; C = ^X3 & ^X0 & X2
ORL C, 20h.4; C = ^x0 & x2 & x1 v ^x3 & ^x0 & x2
MOV 20h.4, C; 03 = ^x0 & x2 & x1 v ^x3 & ^x0 & x2 -- 2

MOV C, ACC.2;C = X2
ORL C, ACC.1; C = X2 V X1
CPL C; C = ^X2 & ^X1
ANL C, ACC.0; C = ^X2 & ^X1 & X0
ORL C, 20h.4; C = ^x0 & x2 & x1 v ^x3 & ^x0 & x2 v ^x2 & ^x1 & x0
MOV 20h.4, C; 03 = ^x0 & x2 & x1 v ^x3 & ^x0 & x2 v ^x2 & ^x1 & x0 -- 4

MOV C, ACC.1; C = X1
CPL C; C = ^X1
ORL C, ACC.0; C = X0 V ^X1
CPL C; C = ^X0 & X1
ORL C, ACC.2; C = X2 V (^X0 & X1)
CPL C; C = ^X2 & (X0 V ^X1)
ANL C, ACC.3; C = X3 & ^X2 & (X0 V ^X1)
ORL C, 20h.4; C = ^x0 & x2 & x1 v ^x3 & ^x0 & x2 v ^x2 & ^x1 & x0 v x3 & ^x2 & (x0 v ^x1)
MOV	P4.0,C	;res:=F
; LOADING IDEALS
JB ACC.3, SECOND	;IF CASE >7
MOV DPTR, #8000h
MOVX A, @DPTR; A = RELATIVE ADDRESS
MOV  DPL, A
MOVX A, @DPTR;A = BASE ADDRESS
MOV DPL, A
MOVX A, @DPTR; A = IDEALS
MOV B, 20h
ANL B, #00000111b
;--------
AJMP NEXT;
SECOND:
MOV DPTR, #8000h
MOVX A, @DPTR; A = RELATIVE ADDRESS
MOV DPL, A
MOVX A, @DPTR; A = BASE ADDRESS
ADD A,#0001h
MOV DPL, A
MOVX A, @DPTR; A = IDEALS
MOV B, 20h
ANL B, #00001111b
NEXT:
XCH A, B		; A = counter
JZ END_OF_CYCLE	; if count = 0
XCH A, B		; A = half of truth table, B = count
cycle:
RR A;
DJNZ B, cycle;
END_OF_CYCLE:
MOV B, A;
MOV C, B.0		;bit from table
CPL C			; invert c
MOV P4.1, C		; P4.1 = inverted bit from table

;timer - sleep
; duration of 1 cycle ~ 0.071 sec
; num of cycles which duration not lower than 1 sec is =>15
MOV A, 20h		; A = X3X2X1X0
ANL A, #00001111b; clear high half
ADD A, #40h		;address of number
MOV R1, A
MOV A, @R1		; seconds from address (40h + tuple_number)
MOV TMOD,#00000001b	; mode 1
MOV B, #001h;#0C8h ; 1 external circle
MOV R3, B
MOV B, #00Fh;#014h ;number of iterations = 15
MUL AB			; inner circle seconds: 0.071 * B * A
MOV R2, A; inner circle seconds R2 = A * B * 0.071

    START: CLR TR0		;reset counter
        MOV TL0, #000h;#01Ah	;init value
        SETB TR0		;start count
        CLOCK:JBC TF0, FINISH	;250ms
           JMP CLOCK
           FINISH: DJNZ R2, START	;inner circle end 20*seconds = A
            MOV R2, A; inner circle 25020*seconds
            DJNZ R3, START

;next tuple
MOV DPTR, #7FFAh
MOVX A, @DPTR
ADD A, #1
JNB ACC.4, WRITE
SET_ZERO:
MOV A, #0000h
WRITE:
MOVX @DPTR, A

; set isReadyBit = 0
MOV DPTR,#7FFBh
MOV A, #00h
MOVX @DPTR, A
AJMP MET1;
END