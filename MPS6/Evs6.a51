ORG 0000H
P4 EQU 0C0H
ADCON EQU 0C5H
ADCH EQU 0C6H
PWM0 EQU  0FCH
PWM1 EQU 0FDH
PWMP EQU 0FEH
DELAY EQU 01h
CHANNELS_COUNT EQU 8
INDEX_ADDR EQU 20h
PWMP_VAL EQU 9
BASE EQU 0Ah; base=10
PWMX_VALS_BASE_ADDR EQU 21h
;calculate PWMx value for any S = T/t1, T = t0 + t1, t0/t1 = PWMx / (255 - PWMx)
PWMX_VAL_FOR_S_0 EQU 0FFh
PWMX_VAL_FOR_S_1 EQU 00h
PWMX_VAL_FOR_S_2 EQU 080h
PWMX_VAL_FOR_S_3 EQU 0AAh
PWMX_VAL_FOR_S_4 EQU 0BFh
PWMX_VAL_FOR_S_5 EQU 0CCh
PWMX_VAL_FOR_S_6 EQU 0D5h
PWMX_VAL_FOR_S_7 EQU 0DBh
PWMX_VAL_FOR_S_8 EQU 0DFh
PWMX_VAL_FOR_S_9 EQU 0E3h
PWMX_VAL_FOR_S_10 EQU 0E6h
PWMX_VAL_FOR_S_11 EQU 0E8h
PWMX_VAL_FOR_S_12 EQU 0EAh
PWMX_VAL_FOR_S_13 EQU 0EBh
PWMX_VAL_FOR_S_14 EQU 0EDh	
PWMX_VAL_FOR_S_15 EQU 0EEh
;--write PWMx values as array in internal memory
MOV R0, #PWMX_VALS_BASE_ADDR
MOV @R0, #PWMX_VAL_FOR_S_0
MOV A, R0
INC A
MOV R0, A
MOV @R0, #PWMX_VAL_FOR_S_1
MOV A, R0
INC A
MOV R0, A
MOV @R0, #PWMX_VAL_FOR_S_2
MOV A, R0
INC A
MOV R0, A
MOV @R0, #PWMX_VAL_FOR_S_3
MOV A, R0
INC A
MOV R0, A
MOV @R0, #PWMX_VAL_FOR_S_4
MOV A, R0
INC A
MOV R0, A
MOV @R0, #PWMX_VAL_FOR_S_5
MOV A, R0
INC A
MOV R0, A
MOV @R0, #PWMX_VAL_FOR_S_6
MOV A, R0
INC A
MOV R0, A
MOV @R0, #PWMX_VAL_FOR_S_7
MOV A, R0
INC A
MOV R0, A
MOV @R0, #PWMX_VAL_FOR_S_8
MOV A, R0
INC A
MOV R0, A
MOV @R0, #PWMX_VAL_FOR_S_9
MOV A, R0
INC A
MOV R0, A
MOV @R0, #PWMX_VAL_FOR_S_10
MOV A, R0
INC A
MOV R0, A
MOV @R0, #PWMX_VAL_FOR_S_11
MOV A, R0
INC A
MOV R0, A
MOV @R0, #PWMX_VAL_FOR_S_12
MOV A, R0
INC A
MOV R0, A
MOV @R0, #PWMX_VAL_FOR_S_13
MOV A, R0
INC A
MOV R0, A
MOV @R0, #PWMX_VAL_FOR_S_14
MOV A, R0
INC A
MOV R0, A
MOV @R0, #PWMX_VAL_FOR_S_15
IS_READY:
MOV DPTR, #7ffbh ; address with ready flag
MOVX A, @DPTR
ANL A, #01
JZ IS_READY; wait for ready flag

MOV PWMP, #0ffh; increment pwm counter each 256 tick [optional, can be 0]
MOV A, #00h
MOVX @DPTR, A; reset flag
MOV TMOD, #00000001b; mode 1
MOV INDEX_ADDR, #0; init index, i
MAIN_ADC_PWM_CYCLE:
MOV A, #CHANNELS_COUNT
SUBB A, INDEX_ADDR
JZ IS_READY
MOV ADCON, #00000000b; reset ADCON
; read value from channel with index i
MOV A, INDEX_ADDR; A = i
SETB ACC.3
MOV ADCON, A; now ADCON contains index of channel
WAIT_ADC: MOV A,ADCON
ANL A, #10H
JZ WAIT_ADC ;wait for ADC read value from channel
MOV A, ADCH ;read result of ADC work
;-- lets extract digits from ADCH value
DIGITS_EXTRACTING_CYCLE:
MOV R4, A;save A in R4
MOV B, #BASE
DIV AB; divide A on BASE and receive A = BASE * z + r, where A = z and B = r (r from {0,..,BASE - 1})
;---work with pwm---
MOV A, #PWMX_VALS_BASE_ADDR
ADD A, B; calc addres of PWMx value
MOV R1, A
MOV PWM0, @R1
MOV R3, #01h; sleep for 1 second
ACALL SLEEP
MOV A, R4
SUBB A, B
MOV B, #BASE
DIV AB
JNZ DIGITS_EXTRACTING_CYCLE
MOV PWM0, #PWMX_VAL_FOR_S_0
MOV R3, #DELAY
ACALL SLEEP
LJMP NEXT_INDEX
;delay function:
SLEEP:
; R3 (as param) contains delay 		
MOV R2, #064h
    START: CLR TR0		;reset counter
        MOV TH0, #HIGH(-10000);init value 
		MOV TL0, #LOW(-10000); load to T0 value 10000 (it means that processor will work for 10 ms = 0.01 sec if freq is 12 MHz)
		CLR TF0
        SETB TR0		;start count
        CLOCK:
		   JNB TF0, CLOCK
           FINISH: DJNZ R2, START
            MOV R2, #064h
            DJNZ R3, START
RET
NEXT_INDEX:
MOV A, INDEX_ADDR
INC A
MOV INDEX_ADDR, A
LJMP MAIN_ADC_PWM_CYCLE

END_MAIN_CYCLE:
END