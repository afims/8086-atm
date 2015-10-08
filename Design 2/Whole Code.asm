.MODEL TINY
.8086
.DATA
; Declaring 8255(#1) ports 
Port_1_A EQU 00h 	
Port_1_B EQU 02h	
Port_1_C EQU 04h	
Port_1_CR EQU 06h


; Declaring 8255(#2) ports 
Port_2_A EQU 80h	
Port_2_B EQU 82h		
Port_2_C EQU 84h	
Port_2_CR EQU 86h



; Defining keys
TABLE DB 077h, 07Bh, 07Dh, 07Eh, 0B7h, 0BBh, 0BDh, 0BEh, 0D7h, 0DBh, 0DDh, 0DEh, 0E7h, 0EBh, 0EDh, 0EEh
; Defining hex codes for key values
TABLE2 DB 007h, 008h, 009h, 080h, 004h, 005h, 006h, 080h, 001h, 002h, 003h, 010h, 080h, 000h, 00Bh, 020h

TEMP DW 0000H
PRES DW 0000H
VOLT DW 0000H
DATA DW 0000H

SUM_TEMP DW 0000H
SUM_PRES DW 0000H
SUM_VOLT DW 0000H


TIME_PERIOD DB ?		; Variable to take the user defined time period   
TOTAL_TIME DB ?
NUM DW 0000H
;------------------------------------------------------------------
; Main function defined here
.CODE
.STARTUP            

; initialising DS
MOV AX,0000H
MOV DS,AX

MOV CL,0000H

MOV AL,80H        ;Moving control word for programming 8255A #1
MOV PORT_1_CR, AL ;control word is 10000000

RESTART:
; taking the time period from user through keyboard

LOOP1: MOV DI, OFFSET DATA
       MOV SI,2				; time to be entered in hours

LOOP2:
    CALL DISPLAY_DATA
    CALL KEYBOARD	; procedure to take the values from keyboard
    CMP AL, 008H
    JE CONT
    MOV [DI], AL 		; corresponding key
    INC DI
    DEC SI
    JZ LOOP3  
    JMP LOOP2
	
	LOOP3:
	    MOV BH,AL
	    MOV AX,0000AH
	    MUL [DI]
	    ADD [DI], BH
        CALL DISPLAY_DATA


; Confirmation by the user of the values entered         
CALL KEYBOARD
CMP AL, 008H
JNZ LOOP1               

CONT:
MOV SI,DI
MOV DI,OFFSET TIME_PERIOD
MOV AX,[SI]
MOV [DI],AX
MOV AX, 6D
MOV SI, OFFSET TIME_PERIOD
MOV BX, [SI]
MUL BX
MOV DI, OFFSET TOTAL_TIME
MOV [DI], BX




AVG:
CALL STEP_AVERAGE
MOV SUM_VOLT, 0000H
MOV SUM_PRES, 0000H
MOV SUM_TEMP, 0000H
MOV NUM, 0001H
MOV CX, 35D

DELAYING: 
CALL DELAY

MOV AL, 80H ;SOUNDING ALARM
OUT 82H, AL

CALL INPUT_T
CONTINUE:
MOV SI,OFFSET DATA
MOV DI,OFFSET VOLT
MOV AX,[SI+1]
MOV [DI],AX
ADD SUM_VOLT,AX
MOV DI,OFFSET PRES
MOV AX,[SI+2]
MOV [DI],AX
ADD SUM_PRES,AX
MOV DI,OFFSET TEMP
MOV AX,[SI+3]
MOV [DI],AX
ADD SUM_TEMP,AX


DEC TOTAL_TIME
JZ HALT

DEC CX
INC NUM 
JNZ DELAYING

CMP TOTAL_TIME, 00H
JNE AVG






;------------------------------------------------------------------
; All functions defined here:
KEYBOARD PROC NEAR
PUSHF                 ; save registers used
PUSH BX
PUSH CX
PUSH DX

MOV AL,083H         ;moving control word to program 8255A #2
OUT PORT_2_CR, AL   ;control word is 10000011

MOV AL, 00          ; send 0's to all rows
OUT 80h, AL          ; send 0's

; Now read the columns to see if a key is pressed
WAIT_PRESS:
			IN AL, 80h                ; read columns
			AND AL, 0Fh           ; mask row bits
			CMP AL, 0Fh            ; see if any key is pressed
			JE WAIT_PRESS

; De bounce key press
MOV CX, 16EAh         ; delay of 20ms
DELAY1: LOOP DELAY1
; read columns to see if key is still pressed
			IN AL, 84h
			AND AL, 0Fh
			CMP AL, 0Fh
			JE WAIT_PRESS

; find the key
			MOV AL, 0FEH    ; initialize a row mask with bit0
			MOV CL, AL         ; low and save the mask
NEXT_ROW:
			OUT 80h, AL         ; send out a low on one row
			IN AL, 84h           ; read columns and check for low
			AND AL, 0Fh       ; mask out row code
			CMP AL, 0Fh        ; if low in one column then
			JNE ENCODE
			ROL CL, 01          ; else rotate mask
			MOV AL, CL       ; look at next row
			JMP NEXT_ROW
; encode the row/column information
ENCODE:
			MOV BX, 0Fh   ; setup BX as a counter
			ROL CL, 4	
            OR AL, CL   ;storing key press in AL as row,columns



TRY_NEXT:
CMP AL, TABLE [BX]   ; compare row/column                                    ; code with table entry 
JE DONE		; hex code in BX
DEC BX            ; point an next table entry
JNS TRY_NEXT
MOV AH, 01     ; pass an error code in AH
JMP EXIT
DONE:
			MOV AL, TABLE2 [BX]       ; hex code for key in AL
			MOV AH, 00        ; put keyvalid code in AH
		


EXIT: 
			POP DX        ; restore calling program registers
			POP CX
			POP BX
			POPF
			RET
KEYBOARD ENDP

;-------------------------
KEY_FUNC PROC NEAR
    MOV AH, 000H
    CMP AL, 010H
    JE DOWN
    CMP AL, 020H
    JE UP
    CMP AL, 080H
    JE CLEAR
    CMP AL, 008H
    JE OVER_F
    MOV BX,AX
    MOV CX, DX
    MOV AL, 00AH
    LOOP X
    X: MUL AL
    MUL DATA[DI]
    ADD AX, BX
    MOV DATA[DI], AX
    JMP OVER_F
    
    DOWN: DEC DI 
    JMP FUNC
    UP : INC DI
    JMP FUNC
    CLEAR: MOV DATA[DI], 0000H
    JMP FUNC
    OVER_F: RET
    
    FUNC: CMP DI,0003H
        JE CALL_T
        CMP DI,0002H
        JE CALL_P
        CMP DI,0001H
        JE CALL_V
        
    CALL_T: CALL INPUT_T
    CALL_P: CALL INPUT_P
    CALL_V: CALL INPUT_V
    
    KEY_FUNC ENDP 
;-------------------------------------
INPUT_T PROC NEAR
      
    MOV DI, 0003H
    MOV DX, 0000H
    MOV BX,DATA[DI]
    MOV DATA,BX
    CALL DISPLAY_DATA
START_T:  CALL KEYBOARD
          CALL KEY_FUNC
          MOV BX,DATA[DI]
    MOV DATA,BX
    CALL DISPLAY_DATA
        
    CMP AL, 008H
    JE OVERT
    INC DX
    JMP START_T
    OVERT: JMP CONTINUE
    INPUT_T ENDP

;-----------------------------------
INPUT_P PROC NEAR
    MOV DI, 0002H
    MOV DX, 0000H
    MOV BX,DATA[DI]
    MOV DATA,BX
    CALL DISPLAY_DATA
START_P:    CALL KEYBOARD
            CALL KEY_FUNC
            MOV BX,DATA[DI]
    MOV DATA,BX
    CALL DISPLAY_DATA
    CMP AL, 008H
    JE OVERT
    INC DX
    JMP START_P
    OVERP: JMP CONTINUE
    INPUT_P ENDP
;-----------------------------------------
INPUT_V PROC NEAR
    MOV DI, 0001H
    MOV DX, 0000H
    MOV BX,DATA[DI]
    MOV DATA,BX
    CALL DISPLAY_DATA
START_V:   CALL KEYBOARD
           CALL KEY_FUNC
           MOV BX,DATA[DI]
    MOV DATA,BX
    CALL DISPLAY_DATA
    CMP AL, 008H
    JE OVERT
    INC DX
    JMP START_V
    OVERV: JMP CONTINUE
    INPUT_V ENDP
;----------------------------------------
CONVERT PROC NEAR

step_average proc near
;-----------------------  
    mov si, offset sum_volt 
    mov ax, word ptr[si]
    call Avg_volt
    call Display_volt
    mov si, offset sum_pres
    mov ax, word ptr[si] 
    call Avg_pres
    call Display_Pres
    mov si, offset sum_temp
    mov ax, word ptr[si] 
    call Avg_temp
    call Display_Temp
step_average endp  
;---------------------
delay proc near 
    push bx
    push cx
 M_count equ 1000d
 Count equ 6480d
 MOV BX, M_count
 REPE : MOV CX, Count
 BACK : NOP
        NOP
        DEC CX
        JNZ BACK
        DEC BX
        JNZ REPE; add your code here
    pop cx
    pop bx
delay endp 

Avg_volt PROC NEAR
    PUSH BX; add your code here
    PUSH DX
    MOV DX,10D 
    MUL DX 
    MOV BX, NUM
    DIV BX ;QUOTIENT IS IN AX CONTAINS AVERAGE VALUE(*10)
    POP DX
    POP BX 
Avg_volt ENDP

Avg_pres PROC NEAR
    PUSH BX; add your code here
    PUSH DX
    MOV DX,10D 
    MUL DX 
    MOV BX, NUM
    DIV BX ;QUOTIENT IS IN AX CONTAINS AVERAGE VALUE(*10)
    POP DX
    POP BX 
Avg_pres ENDP

Avg_temp PROC NEAR
    PUSH BX; add your code here
    PUSH DX
    MOV DX,10D 
    MUL DX 
    MOV BX, NUM
    DIV BX ;QUOTIENT IS IN AX CONTAINS AVERAGE VALUE(*10)
    POP DX
    POP BX 
Avg_temp ENDP 

Display_volt PROC NEAR
    PUSH BX
    PUSH DX
    MOV BL,10d
    DIV BL 
    ADD AL, 40H
    MOV DX,000H
    OUT DX,AL
    ADD AH,80H
    MOV AL,AH
    OUT DX,AL
    POP DX
    POP BX
    RET
Display_volt ENDP

Display_Pres PROC NEAR
    PUSH BX
    PUSH DX
    MOV BL,10d
    DIV BL 
    ADD AL, 40H
    MOV DX,004H
    OUT DX,AL
    ADD AH,80H
    MOV AL,AH
    OUT DX,AL
    POP DX
    POP BX
    RET
Display_Pres ENDP 

Display_temp PROC NEAR
    PUSH BX 
    PUSH SI
    MOV BX,1000d
    DIV BX
    ADD AL,10H
    MOV SI,DX
    MOV DX,002H
    OUT DX,AL
    MOV AX,SI
    MOV BL,100d 
    DIV BL    
    ADD AL,20H
    OUT DX,AL
    MOV AL,AH
    MOV AH,00H
    MOV BL,10d
    DIV BL 
    ADD AL, 40H
    OUT DX,AL
    ADD AH,80H
    MOV AL,AH
    OUT DX,AL
    POP SI
    POP DX
    POP BX
    RET 
Display_temp ENDP     

Display_DATA PROC NEAR
    PUSH DI
    PUSH AX
    MOV DI, OFFSET DATA
    MOV AL,80H            ;Moving control word for porgramming 
    MOV PORT_2_CR,AL      ;Control word is 10000000
    POP AX
    CMP AL,010H
    JE NO_DISP
    CMP AL,020H
    JE NO_DISP
    CMP AL,008H
    JE NO_DISP
    CMP AL,080H
    JNE DISP_D
        
    PUSH AX
    MOV AX, 0000H
    MOV [DI],AX
    
    DISP_D:    
    MOV BL, 08H
    MOV SI, DI
    MOV DX, [SI]
    MOV SI, 1000D
    MOV AL,BL
    OUT PORT_2_A, AL
    MOV AX,DX
    DIV SI
    
    OUT PORT_2_B, AL
    MOV DL,AH
    MOV DH,00H    
    
    MOV SI,100D
    ROR BL, 1d
    MOV AL,BL
    OUT PORT_2_A, AL
    
    MOV AX,DX
    DIV SI
    OUT PORT_2_B, AL
    
    ROR BL, 1D
    MOV AL,BL
    OUT PORT_2_A,AL
    
    MOV AL,AH
    MOV AH,000H
    MOV SI, 10D
    OUT PORT_2_A, AL
    
    ROR BL,1D
    MOV AL,BL
    OUT PORT_2_A, AL
    
    MOV AL,AH
    OUT PORT_2_B, AL
     
       
    NO_DISP:
    POP AX
    POP DI
    RET
    Display_DATA ENDP

HALT:
CALL STEP_AVERAGE
.EXIT
END    


                    BUILD.BAT

@ECHO OFF

ml /c /Zd /Zi sample.asm

link16 /TINY /CODEVIEW sample.obj, sample.com,,,nul.def
