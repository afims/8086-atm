.model tiny

org 100h   

.data
	segTable db 3fh,06h,5bh,4fh,66h,6dh,7dh,07h,7fh,67h,00h
	keyTable db 73h,76h,0B3h,0B5h,0B6h,0D3h,0D5h,0D6h,0E3h,0E5h,0E6h,75h
		
	ledVal dw 0AAAAh
	ledCount db 00h
    portA equ 0000h
    portB equ 0002h
    portC equ 0004h
    ctrlR equ 0006h


.code
    .startup
    
    ;init control reg 1-00-0-0-0-0-1
    mov al,81h
    out ctrlR,al
	
    X0:
	mov dl,0EEh
	mov cl,0Ch
    S1: mov al,dl
        out portA,al
        mov dl,al
        rol dl,1
        
        mov ax,ledVal;	1234h
		shl ax,cl;		0123h
		and al,0fh;		--03h
		lea bx,segTable
		xlat
		out portB,al
		cmp cl,00h
		jnz x1
		mov cl,10h
		X1:sub cl,04h
    
        in al,portC
        cmp al,07h
        jz S1
		
	and dl,0f0h
	or al,dl
	lea si,keyTable
	dec si
	mov cl,0Ch
	X2:	dec cl
		inc si
		cmp al,[si]
		jnz X2
		
	mov al,cl
	sub cl,0Ah
	jc X3
	mov ledVal,0AAAAh
	jmp X0
	X3:	
	inc BYTE PTR ledCount;0		2
	mov cl,ledCount;	1		3
	shl cl,2;			4		12
	mov ah,00h;			0009h	0009h
	ror ax,cl;			9000h	0090h
	mov dx,0fff0h;		fff0h	fff0h
	ror dx,cl;			0fffh	ff0fh
	and dx,ledVal;		0AAAh	120Ah
	or ax,dx;			9AAAh	129Ah
	mov ledVal,ax;
	cmp ledCount,04h
	jnz X0