;F(X3,X2,X1,X0) == 1 <=> 1,4,6,8,9,11,14
ORG 0000h;
BASEADDRESS EQU 0011h;11h
RELATIVEADDRESS EQU 0004h;04h
LJMP MAIN
;ORG 5000
MAIN:
;MOV P0, #0FFh
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
;MOV DPTR, #8001h;
;-- MY ADDITION
MOV B, 20h
ANL B, #00001111b
; -------------
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
MOV DPTR,#7FFBh
mov A, #00h
movx @dptr, A
AJMP MET1;
END