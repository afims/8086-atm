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






