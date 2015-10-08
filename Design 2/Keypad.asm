.model tiny
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



; Defining keys
TABLE DB 077h, 07Bh, 07Dh, 07Eh, 0B7h, 0BBh, 0BDh, 0BEh, 0D7h, 0DBh, 0DDh, 0DEh, 0E7h, 0EBh, 0EDh, 0EEh
; Defining hex codes for key values
TABLE2 DB 007h, 008h, 009h, 080h, 004h, 005h, 006h, 080h, 001h, 002h, 003h, 010h, 080h, 000h, 00Bh, 020h

SUM_T DW 0000H
SUM_P DW 0000H
SUM_V 

TIME_PERIOD DB ?		; Variable to take the user defined time period   

.CODE
.STARTUP            

; initialising DS
MOV AX,0000H
MOV DS,AX

MOV CL,0000H
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

CALL CONVERT






;------------------------------------------------------------------
KEYBOARD PROC NEAR
PUSHF                 ; save registers used
PUSH BX
PUSH CX
PUSH DX
MOV AL, 00          ; send 0's to all rows
OUT 80h, AL          ; send 0's

WAIT_OPEN:
			IN AL, 84h
			AND AL, 0Fh             ; mask row bits
CMP AL, 0Fh        
JNE WAIT_OPEN    ; wait until no key is pressed
; This is for checking if all the keys are open
; Now read the columns to see if a key is pressed
WAIT_PRESS:
			IN AL, 80h                ; read columns
			AND AL, 0Fh           ; mask row bits
			CMP AL, 0Fh            ; see if any key is pressed
			JE WAIT_PRESS

; De bounce key press
MOV CX, 16EAh         ; delay of 20ms
DELAY: LOOP DELAY
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

