.model tiny

; Initialization of data segment

.DATA

; Declaring 8255(#1) ports 
Port_1_A EQU 00h 	
Port_1_B EQU 02h	
Port_1_C EQU 04h	
Port_1_CR EQU 06h


; Declaring 8255(#2) ports 
Port_2_A EQU 88h	
Port_2_B EQU 90h		
Port_2_C EQU 92h	
Port_2_CR EQU 94h

; Declaring 8255(#3) ports 
Port_3_A EQU 5OH
Port_3_B EQU 52H
Port_3_C EQU 54H
Port_3_CR EQU 56H

; Defining keys

TABLE DB 077h, 07Bh, 07Dh, 07Eh, 0B7h, 0BBh, 0BDh, 0BEh, 0D7h, 0DBh, 0DDh, 0DEh, 0E7h, 0EBh, 0EDh, 0EEh      
      
TIME_PERIOD DB ?		; Variable to take the user defined time period   

.CODE
.STARTUP            

; initialising DS
MOV AX,0000H
MOV DS,AX

MOV CL,0000H	; CL acts as a counter to count the number of memory locations or Sample values taken	for each parameter			

; Intialisation of 8255(#1) 
; Port A-input port-mode 0	              (input port for digital signal coming from ADC)
; Port B-output port-mode 0  	(output port-PB0, PB1, PB2==for A, B, C==to         select	Signal source.)
; Port C (upper)-output port -mode 0     (C7-giving clock pulse to ADC.////C6-giving OE To ADC////C5-giving ALE=1 to ADC.)
; Port C (lower)-input port-mode 0     (C0-checking for EOC=1)

MOV AL, 91H		   ; CR=10010001
OUT Port_1_CR, AL                 ; PA-O/P, PB-I/P, PCU-I/P, PCL-O/P 

; Intialisation of 8255(#2)
; Port A-output port-mode 0			(output port to seven segment display)
; Port B-output port -mode0			
; Port C (upper) -output port -mode0		(output port for keypad)
; Port C (lower)-input port -mode 0		(input port for keypad)

MOV AL,91H		               ; CR=10010001
OUT Port_2_CR,AL

RESTART:
; taking the time period from user through keyboard

LOOP1:MOV DI, OFFSET TIME_PERIOD
      MOV SI,2				; time to be entered in hours

LOOP2: CALL KEYBOARD	; procedure to take the values from keyboard
    MOV [DI], AL 		; corresponding key
    INC DI
    DEC SI
    JZ LOOP3  
    
; Putting the first 4 bits(D0,D1,D2,D3) of AL into D4,D5,D6,D7 of AL
MOV CL,4
ROL AL,CL
MOV AH,AL
	JMP LOOP1
	LOOP3:
	    ADD AL,AH
	    OUT Port_2_A,AL		;displaying the values entered by the user in the 7segment display

; Confirmation by the user of the values entered         
CALL KEYBOARD
CMP AL, 0DDH		; DDH-- HEX CODE FOR "ENTER"
JNZ LOOP1               

CALL CONVERT_TO_MIN   

; generating a pulse for activating the ADC START of DC VOLTAGE sensor

;setting ALE=1
MOV AL,0BH			;CW=00001011
OUT Port_1_C,AL

;selecting sensor of DC VOLTAGE;(PB0=0;PB1=0;PB2=0)
MOV AL,00H
OUT Port_1_B,AL

CALL INITIALISE_ADC 

;storing values of dc voltage into the memory
IN AL,Port_1_A
MOV [SI],AL

;selecting sensor of TEMPERATURE;(PB0=1;PB1=0;PB2=0)
MOV AL,01H
OUT Port_1_B,AL

CALL INITIALISE_ADC

;storing values of temperature into the memory

IN AL,Port_1_B
MOV [SI+300H],AL

;selecting sensor of  PRESSURE;(PB0=0;PB1=1;PB2=0)
MOV AL,02H
OUT Port_1_B,AL

CALL INITIALISE_ADC

;storing values of PRESSURE into the memory

IN AL,Port_1_B
MOV [SI+600H],AL

;setting ALE=0
MOV AL,0AH			;CW=00001010
OUT Port_1_C,AL


;taking user choice of required output….

RECALL:	CALL KEYBOARD
CMP AX, 0DEH
JZ CALL1
CMP AX,0E7H
JZ CALL2
CMP AX,0EBH
JZ CALL3
		CMP AX,0EDH
		JZ RESTART
		CMP AX,0EEH
		JZ SHUT_DOWN

CALL1: CALL AVG_VOLTAGE
	   JMP RECALL
CALL2: CALL AVG_TEMP
	  JMP RECALL
CALL3: CALL AVG_PRESSURE
	  JMP RECALL   
	  
SHUT_DOWN: JMP LAST


	
       
       
; calculating the average value`s of individual parameters
; calculating for AVERAGE DC VOLTAGE

AVG_VOLTAGE PROC NEAR

MOV CH,CL		; creating a copy of count
MOV BX,0000H	; intialising bx to 0, bx calculates the sum
MOV SI,0000H

LOOP1V:	
ADD BX,[SI]
INC SI
DEC CH
CMP CH,CL
JNZ LOOP1V

MOV AX,BX
DIV CL		; now AL will contain the value average value after performing the    division

;converting the value in AL to a form which is used to interface 7 segment display
MOV AH,0
MOV BL,10

DIV BL;		;now AL will	contain quotient ,,AH will contain remainder
MOV CL,4
ROL AH,CL
ADD AL,AH		;now higher bits of AL will contain higher digit//lower Four bits will contain lower digit.

OUT Port_2_B,AL

RET 
AVG_VOLTAGE ENDP




; calculating for AVERAGE TEMPERATURE

AVG_TEMP PROC NEAR

MOV CH,CL		; creating a copy of count
MOV BX,0000H	; intialising bx to 0, bx calculates the sum
MOV SI,0200H

LOOP1T:	
ADD BX,[SI]
INC SI
DEC CH
CMP CH,CL
JNZ LOOP1T

MOV AX,BX
DIV CL		; now AL will contain the value average value after performing the    division
;converting the value in AL to a form which is used to interface 7 segment display
MOV AH,0
MOV BL,10

DIV BL;		;now AL will	contain quotient ,,AH will contain remainder
MOV CL,4
ROL AH,CL
ADD AL,AH		;now higher bits of AL will contain higher digit//lower Four bits will contain lower digit.

OUT Port_2_B,AL

RET
AVG_TEMP ENDP






; calculating for AVERAGE PRESSURE

AVG_PRESSURE PROC NEAR

MOV CH,CL		; creating a copy of count
MOV BX,0000H	; intialising bx to 0, bx calculates the sum
MOV SI,0400H

LOOP1P:	
ADD BX,[SI]
INC SI
DEC CH
CMP CH,CL
JNZ LOOP1P

MOV AX,BX
DIV CL		; now AL will contain the value average value after performing the        division

;converting the value in AL to a form which is used to interface 7 segment display
MOV AH,0
MOV BL,10

DIV BL;		;now AL will	contain quotient ,,AH will contain remainder
MOV CL,4
ROL AH,CL
ADD AL,AH		;now higher bits of AL will contain higher digit//lower Four bits will contain lower digit.

OUT Port_2_B,AL

RET
AVG_PRESSURE ENDP


; Procedure for taking input from key pad.
; Procedure for knowing which key is pressed       
       
KEYBOARD PROC NEAR
PUSHF                 ; save registers used
PUSH BX
PUSH CX
PUSH DX
MOV AL, 00          ; send 0's to all rows
OUT 70h, AL          ; send 0's

WAIT_OPEN:
			IN AL, 72h
			AND AL, 0Fh             ; mask row bits
CMP AL, 0Fh        
JNE WAIT_OPEN    ; wait until no key is pressed
; This is for checking if all the keys are open
; Now read the columns to see if a key is pressed
WAIT_PRESS:
			IN AL, 72h                ; read columns
			AND AL, 0Fh           ; mask row bits
			CMP AL, 0Fh            ; see if any key is pressed
			JE WAIT_PRESS

; De bounce key press
MOV CX, 16EAh         ; delay of 20ms
DELAY: LOOP DELAY
; read columns to see if key is still pressed
			IN AL, 72h
			AND AL, 0Fh
			CMP AL, 0Fh
			JE WAIT_PRESS

; find the key
			MOV AL, 0FEH    ; initialize a row mask with bit0
			MOV CL, AL         ; low and save the mask
NEXT_ROW:
			OUT 72h, AL         ; send out a low on one row
			IN AL, 70h           ; read columns and check for low
			AND AL, 0Fh       ; mask out row code
			CMP AL, 0Fh        ; if low in one column then
			JNE ENCODE
			ROL CL, 01          ; else rotate mask
			MOV AL, CL       ; look at next row
			JMP NEXT_ROW
; encode the row/column information
ENCODE:
			MOV BX, 0Fh   ; setup BX as a counter
			IN AL, DX	; read row and column from port




TRY_NEXT:
CMP AL, TABLE [BX]   ; compare row/column code with table entry 
JE DONE		; hex code in BX
DEC BX            ; point an next table entry
JNS TRY_NEXT
MOV AH, 01     ; pass an error code in AH
JMP OVER
DONE:
			MOV AL, BL       ; hex code for key in AL
			MOV AH, 00        ; put keyvalid code in AH
OVER: 
			POP DX        ; restore calling program registers
			POP CX
			POP BX
			POPF
			RET
KEYBOARD ENDP    

    ;convert

CONVERT_TO_MIN PROC NEAR

	      MOV SI,0
MOV AL, [SI]
MOV BL, 10        
                  MUL BL                ; for converting hours to minutes
MOV DX, AX

MOV AL, [SI+1]
MOV AH, 0
ADD AX, DX
MOV BL,60
MUL BL
MOV [SI], AX	; storing the value of time period in minutes in the first location
 RET
CONVERT_TO_MIN ENDP        


INITIALISE_ADC PROC NEAR

; intialising 8255 to BSR mode

; setting PC7=0
MOV AL,0EH				; CW=00001110
OUT Port_1_CR,AL

; setting PC7=1
MOV AL,0FH				; CW=00001111
OUT Port_1_CR,AL
CALL DELAY_2MS	; call to a sub- routine which causes a delay     of    2micro seconds
; setting PC7=0
MOV AL,0Eh
OUT Port_1_CR,AL

; reading value from the output of ADC of DC VOLTAGE

CALL DELAY_100MS	; call to a sub-routine which causes a delay of 100	Micro seconds.

; checking whether EOC of ADC of DC VOLTAGE sensor is 1 or 0
;checking whether PC0 =1


LOOP:	IN AL,Port_1_C
ROR AL,1
JNC LOOP


; taking one set of values from the sensors of DC VOLTAGE
; Before taking values enable OE (PC6)

MOV AL,0DH				;CW=00001101
OUT Port_1_C,AL



RET
INITIALISE_ADC ENDP        


DELAY_2MS PROC NEAR 
    MOV CX,500
    X1: NOP  
    LOOP X1    
    RET
DELAY_2MS ENDP   


DELAY_100MS PROC NEAR  
    MOV CX,25000
    X2: NOP 
    LOOP X2
    RET
DELAY_100MS ENDP




LAST:

.exit

END

