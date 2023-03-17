; Utilities
;
; Library with "High-Level" calling interface

    LOCALS @@
		
    TITLE UTILS

UTILS SEGMENT PARA PUBLIC 'CODE'
    ASSUME CS:UTILS, DS:UTILS, ES:UTILS

; Subroutines now follow a PASCAL/STDCALL-like calling convention:
;
; 1. Parameters are passed on stack: Order is from right to left
; 2. All subroutines require FAR calls
; 3. All modified registers are preserved
; 4. Passed parameters are popped off the stack
; 5. Return values place in:
;    a) AX = 16bit value / Near Pointer
;    b) DX:AX = 32bit value / Far pointer

; ------ CLEAR ------
;
; Clears buffer
;
; Inputs:
;   FAR PTR to Buffer
;   BP+06 =  OFFSET address of buffer
;   BP+08 = SEGMENT address of buffer
;   BP+0A = character used to clear buffer

    PUBLIC CLEAR

CLEAR PROC FAR

    PUSH BP
    MOV BP, SP

	PUSHF				; Save registers
	PUSH ES
	PUSH AX
	PUSH DI

    MOV AX, [BP+08H]
    MOV ES, AX          ; Set ES:DI to
    MOV DI, [BP+06H]    ; buffer

	MOV AL, [BP+0AH]	; Clear buffer

	CLD
	REPZ STOSB
		
	POP DI				; Restore registers
	POP AX
	POP ES
    POPF
		
    POP BP

	RET 5

CLEAR ENDP

;------ CONVERT ------
;
; Convert number to string in buffer
;
; Inputs:
;   BP+06 =  OFFSET address of buffer
;   BP+08 = SEGMENT address of buffer
;   BP+0A = Number to convert
;   BP+0C = Base to convert number to
;   BP+0E = Width of buffer

	PUBLIC CONVERT

CONVERT	PROC FAR

    PUSH BP
    MOV BP, SP

	PUSHF				; Save registers
	PUSH ES
	PUSH AX
	PUSH DX
	PUSH DI

    MOV AX, [BP+08H]    ; Get buffer segment
    MOV ES, AX
    MOV DI, [BP+06H]    ; Get buffer offset
    MOV AX, [BP+0EH]    ; Get buffer width
    DEC AX
    ADD DI, AX          ; Point ES:DI
                        ; to the last byte of
                        ; the buffer

    MOV AX, [BP+0AH]    ; Get number
    MOV CX, [BP+0CH]    ; Get base

@@LOOP:
	
    XOR DX, DX			; Clear upper half of 32bit number in DX:AX
	DIV CX				; Process one digit at a time
		
	CMP DL, 09H			; Check if remainder is not numeric
	JA @@FIX
		
	ADD DL, '0'			; Convert digit to ASCII equivalent
	JMP @@STORE

@@FIX:
	
    ADD DL, 37H			; Convert digit to A-Z
		
@@STORE:                
	
    MOV ES:[DI], DL     ; Store in buffer then move to next location
	DEC DI
	
    OR AX, AX			; Check if there are any digits left to convert
    JZ @@END
	
    JMP @@LOOP
		
@@END:
	
    POP DI				; Restore registers
	POP DX
	POP AX
	POP ES
	POPF

    POP BP

	RET 10

CONVERT ENDP

;------ STRLEN ------
;
; Get string length
;
; Inputs:
;   BP+06 =  OFFSET address of string
;   BP+08 = SEGMENT address of string
;   String must be NULL (00H) terminated
;
; Outputs:
;   AX = string length

    PUBLIC STRLEN
		
STRLEN	PROC FAR

    PUSH BP
    MOV BP, SP

    PUSHF               ; Save registers
	PUSH ES
    PUSH CX
	PUSH DI
		
	MOV AX, [BP+08H]    ; get string buffer segment
	MOV DI, [BP+06H]    ; get string buffer offset
	MOV ES, AX          ; Point ES:DI to string buffer
		
	XOR AX, AX			; Scan for end of string (NULL = 00H)
	XOR CX, CX			; Initialize string length

	CLD                 ; Search in Forward direction

@@LOOP:

	SCASB
	JZ @@EXIT
	
    INC CX				; String length in CX
	JMP @@LOOP

@@EXIT:

    MOV AX, CX          ; Copy string length to AX

	POP DI              ; Restore registers
    POP CX
	POP ES
	POPF
		
	RET 4

STRLEN ENDP

;------ PRINT ------
;
; Prints string. Uses DOS's write
; to file service (INT 21H AH=40H)
;
; Inputs:
;   BP+06 =  OFFSET address of string
;   BP+08 = SEGMENT address of string
;   String must be NULL (00H) terminated

    PUBLIC PRINT

STDIN  EQU 0            ; Standard Input Device - can be redirected (STDIN)
STDOUT EQU 1            ; Standard Output Device - can be redirected (STDOUT)
STDERR EQU 2            ; Standard Error Device - can be redirected (STDERR)
STDAUX EQU 3            ; Standard Auxiliary Device (STDAUX)
STDPRN EQU 4            ; Standard Printer Device (STDPRN)

PRINT	PROC FAR

    PUSH BP
    MOV BP, SP
	
    PUSHF               ; Save registers
    PUSH DS
	PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    
    MOV AX, [BP+08H]    ; get string buffer segment
    PUSH AX
    MOV AX, [BP+06H]    ; get string buffer offset
    PUSH AX
	CALL FAR PTR STRLEN ; Get string length
		
	OR AX, AX			; Check if there are
	JZ @@EXIT			; characters to print

    MOV CX, AX          ; Copy length to CX
    MOV AX, [BP+08H]    ; get string buffer segment
    MOV DX, [BP+06H]    ; get string buffer offset
    MOV DS, AX          ; Point DS:DX to string buffer

	MOV AH, 40H			; Print using DOS service
	MOV BX, STDOUT      ; Print to STDOUT
	INT 21H

@@EXIT:

	POP DX				; Restore registers
	POP CX
    POP BX
	POP AX
    POP DS
    POPF

    POP BP

	RET 4

PRINT ENDP

UTILS ENDS
	
    END
