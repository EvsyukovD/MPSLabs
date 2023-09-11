;F(X3,X2,X1,X0) == 1 <=> 1,4,6,8,9,11,14
ORG 0000h;
BASEADDRESS EQU 11h
RELATIVEADDRESS EQU 04h
LJMP MAIN
;ORG 5000h
MAIN:
;MOV P0, #0FFh
P4 EQU 0C0h
MOV A,  #01010010b
MOV DPTR, #8000h
MOVX  @DPTR, A		;0-7 truth table in ex memory
MOV DPTR, #8001h
MOV A,  #01001011b
MOVX  @DPTR, A		;8-15 truth table in ex memory
CLR P4.0;
SETB P4.1;
MET1:
MOV DPTR,#7FFBh	;adres flaga gotovnosti
gotovnost:		;check flag gotovnost
MOVX A,@DPTR	;read flag
ANL A,#01h		;vibor 0 bita
JZ gotovnost
MOV DPTR,#7FFAh	;adres nomera nabora
MOVX A,@DPTR	;zapis v A nomera nabora
MOV 20h, A		;peremenniye nabora v 0, 1, 2, 3 biti pamyati
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
; zagruzka etalona
JB 3, SECOND	;esli nabor >7
MOV DPTR, #8000h;
; -- MY ADDITION
MOVX A, @DPTR
MOV B, 20h
ANL B, #00000111b
;--------
AJMP NEXT;
SECOND:
MOV DPTR, #8001h;
;-- MY ADDITION
MOVX A, @DPTR
MOV B, 20h
ANL B, #00001111b
; -------------
NEXT:
;MOVX A, @DPTR	; A = half of truth table
;MOV B, 20h;
;ANL B, #00000111b; zapis v B 3 mladshih bita;
XCH A, B		; A = schetchik
JZ END_OF_CYCLE	; if count = 0
XCH A, B		; A = half of truth table, B = count
cycle:
RR A;
DJNZ B, cycle;
END_OF_CYCLE:
MOV B, A;
MOV C, B.0		;bit iz tablici
CPL C			; it inverted
MOV P4.1, C		; P4.1 = inverted bit iz tablici
MOV DPTR,#7FFBh
MOV A, 00h
AJMP MET1;
END