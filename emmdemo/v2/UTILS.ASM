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

; BP-indices used to reference parameters on the stack
BUFFOFF EQU [BP+06H] ; Offset address of buffer
BUFFSEG EQU [BP+08H] ; Segment address of buffer
BUFFLEN EQU [BP+0EH] ; Length of the buffer
CONVNUM EQU [BP+0AH] ; Number of convert
CONVBAS EQU [BP+0CH] ; Base to convert CONVNUM in
COUNTCH EQU [BP+0AH] ; number of bytes to fill
CHRFILL EQU [BP+0CH] ; byte used to fill buffer

; ------ FILL ------
;
; Fill buffer
;
; Inputs:
;	FAR PTR to Buffer
;	BP+06 =  OFFSET address of buffer
;	BP+08 = SEGMENT address of buffer
;	BP+0A = Number of characters to clear
;	BP+0C = character used to clear buffer

	PUBLIC FILL

FILL PROC FAR

	PUSH BP
	MOV BP, SP

	PUSHF				; Save registers
	PUSH ES
	PUSH AX
	PUSH CX
	PUSH DI

	MOV AX, BUFFSEG
	MOV ES, AX			; Set ES:DI to
	MOV DI, BUFFOFF		; buffer

	MOV CX, COUNTCH		; Get count
	MOV AX, CHRFILL		; Character to fill buffer

	CLD
	REPZ STOSB

	POP DI				; Restore registers
	POP CX
	POP AX
	POP ES
	POPF

	POP BP

	RET 8

FILL ENDP

;------ CONVERT ------
;
; Convert number to string in buffer
;
; Inputs:
;	BP+06 =  OFFSET address of buffer
;	BP+08 = SEGMENT address of buffer
;	BP+0A = Number to convert
;	BP+0C = Base to convert number to
;	BP+0E = Width of buffer

	PUBLIC CONVERT

CONVERT PROC FAR

	PUSH BP
	MOV BP, SP

	PUSHF				; Save registers
	PUSH ES
	PUSH AX
	PUSH CX
	PUSH DX
	PUSH DI

	MOV AX, BUFFSEG		; Get buffer segment
	MOV ES, AX
	MOV DI, BUFFOFF		; Get buffer offset
	MOV AX, BUFFLEN		; Get buffer width
	DEC AX
	ADD DI, AX			; Point ES:DI
						; to the last byte of
						; the buffer

	MOV AX, CONVNUM		; Get number
	MOV CX, CONVBAS		; Get base

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

	MOV ES:[DI], DL		; Store in buffer then move to next location
	DEC DI

	OR AX, AX			; Check if there are any digits left to convert
	JZ @@END

	JMP @@LOOP

@@END:

	POP DI				; Restore registers
	POP DX
	POP CX
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
;	BP+06 =  OFFSET address of string
;	BP+08 = SEGMENT address of string
;	String must be NULL (00H) terminated
;
; Outputs:
;	AX = string length

	PUBLIC STRLEN

STRLEN PROC FAR

	PUSH BP
	MOV BP, SP

	PUSHF				; Save registers
	PUSH ES
	PUSH CX
	PUSH DI

	MOV AX, BUFFSEG		; get string buffer segment
	MOV DI, BUFFOFF		; get string buffer offset
	MOV ES, AX			; Point ES:DI to string buffer

	XOR AX, AX			; Scan for end of string (NULL = 00H)
	XOR CX, CX			; Initialize string length

	CLD					; Search in Forward direction

@@LOOP:

	SCASB
	JZ @@EXIT

	INC CX				; String length in CX
	JMP @@LOOP

@@EXIT:

	MOV AX, CX			; Copy string length to AX

	POP DI				; Restore registers
	POP CX
	POP ES
	POPF

	POP BP

	RET 4

STRLEN ENDP

;------ PRINT ------
;
; Prints string. Uses DOS's write
; to file service (INT 21H AH=40H)
;
; Inputs:
;	BP+06 =  OFFSET address of string
;	BP+08 = SEGMENT address of string
;	String must be NULL (00H) terminated

	PUBLIC PRINT

STDIN	EQU 0			; Standard Input Device - can be redirected (STDIN)
STDOUT	EQU 1			; Standard Output Device - can be redirected (STDOUT)
STDERR	EQU 2			; Standard Error Device - can be redirected (STDERR)
STDAUX	EQU 3			; Standard Auxiliary Device (STDAUX)
STDPRN	EQU 4			; Standard Printer Device (STDPRN)

PRINT PROC FAR

	PUSH BP
	MOV BP, SP

	PUSHF				; Save registers
	PUSH DS
	PUSH AX
	PUSH BX
	PUSH CX
	PUSH DX

	MOV AX, BUFFSEG		; get string buffer segment
	PUSH AX
	MOV AX, BUFFOFF		; get string buffer offset
	PUSH AX
	CALL FAR PTR STRLEN	; Get string length

	OR AX, AX			; Check if there are
	JZ @@EXIT			; characters to print

	MOV CX, AX			; Copy length to CX
	MOV AX, BUFFSEG		; get string buffer segment
	MOV DX, BUFFOFF		; get string buffer offset
	MOV DS, AX			; Point DS:DX to string buffer

	MOV AH, 40H			; Print using DOS service
	MOV BX, STDOUT		; Print to STDOUT
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
