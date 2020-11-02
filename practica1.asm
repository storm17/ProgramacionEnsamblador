; Example 1.1:
; Writes "Hello World!" to the text display

	JMP boot

ascii_1:
	DB 0x30				;"0"
	DB 0				; String terminator
ascii_2:
	DB 0x48				;"H"
    DB 0
boot:
	MOV SP, 255			; Set SP
    
	MOV C, ascii_1
	MOV D, 0x2E0		; Output a 0
    MOVB BH, 4
	CALL print
    
    MOV C, ascii_2
    MOV D, 0x2E6
    MOVB BH, 12
    CALL print
    
	HLT				; Halt execution

print:				; Print string
	PUSH A
	MOVB BL, 0
.loop:
	MOVB AL, [C]	; Get character
	MOVB [D], AL	; Write to output
	INC D
    DECB BH
	CMPB BH, BL	; Check if string terminator
	JNZ .loop		; Jump back to loop if not
    
	POP A
	RET
