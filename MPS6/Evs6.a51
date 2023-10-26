ORG 0000H
P4 EQU 0C0H
ADCON EQU 0C5H
ADCH EQU 0C6H
DELAY EQU 5
CHANNELS_COUNT EQU 8
INDEX_ADDR EQU 20h
PWMP_VAL EQU 9
;IS_READY:
;MOV DPTR, #7ffbh ; address with ready flag
;MOVX A, @DPTR
;ANL A, #01
;JZ IS_READY; wait for ready flag

MOV TMOD, #00000001b; mode 1
MOV INDEX_ADDR, #0; init index, i
MAIN_ADC_PWM_CYCLE:
MOV A, #CHANNELS_COUNT
SUBB A, INDEX_ADDR
JZ END_MAIN_CYCLE
MOV A, INDEX_ADDR; A = i
; read value from channel with index i
ADD A, ADCON
MOV ADCON, A; now ADCON contains index of channel
CHECK_FLAGS_ADCI_ADCS:
MOV A, ADCON
ANL A, #18H ;check flags ADCI and ADCS
JNZ CHECK_FLAGS_ADCI_ADCS

MOV ADCON, #08H ; start ADC
WAIT_ADC: MOV A,ADCON
ANL A, #10H
JZ WAIT_ADC ;wait for ADC read value from channel
MOV A, ADCH ;read result of ADC work
;---work with pwm---
MOV PWM0, #00h
;now lets make delay
MOV B, #DELAY; external cycle
MOV R3, B
MOV A, #027h 		
MOV R2, A; inner cycle seconds R2 = DELAY * B * 0.026
    START: CLR TR0		;reset counter
        MOV TL0, #000h;init value
        SETB TR0		;start count
        CLOCK:JBC TF0, FINISH	
           JMP CLOCK
           FINISH: DJNZ R2, START
            MOV R2, A
            DJNZ R3, START

MOV ADCON, #00h; reset flags
NEXT_INDEX:
MOV A, INDEX_ADDR
INC A
MOV INDEX_ADDR, A
LJMP MAIN_ADC_PWM_CYCLE


;M1: MOV A,ADCON
;ANL A,#18H ;check flags ADCI and ADCS
;JNZ M1
;MOV ADCON,#08H ; start ADC
;MM5: MOV A,ADCON
;ANL A,#10H
;JZ MM5 ;wait for ADC read value from channel 0
;MOV A,ADCH ;read result of ADC work
;SWAP A; ---do smth with A---
;MOV P4,A 
;MOV ADCON,#00H ;reset flags
;LJMP M1

END_MAIN_CYCLE:
END