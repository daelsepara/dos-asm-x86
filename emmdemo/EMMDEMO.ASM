; Expanded Memory Manager Demo
;
; Uses EMM Library

		LOCALS @@
		
		TITLE EMMDEMO
		
		.MODEL SMALL
		.STACK 0100H

DSEG 	SEGMENT PARA PUBLIC 'DATA'

NEWLINE	EQU 0AH, 0DH, 00H		; New line
ALLOC	EQU 0100H				; Number of pages to allocate

SENDL	DB NEWLINE
SBASE	DB " Base frame", NEWLINE
SPAGE	DB " Page size in bytes", NEWLINE
STOTAL	DB " Total 16K pages", NEWLINE
SFREE	DB "  Free 16K pages", NEWLINE
SALLOC	DB " Pages allocated", NEWLINE
SNONE	DB "Expanded Memory not available", NEWLINE
SOK		DB "Expanded Memory allocated", NEWLINE
SFAIL	DB "Expanded Memory not allocated", NEWLINE
SFREED	DB "Expanded Memory freed", NEWLINE
SLEAK	DB "Expanded Memory not freed", NEWLINE
SLESS	DB "Not enough expanded memory", NEWLINE
SMAPPED	DB "Page 0 mapped", NEWLINE
SNOMAP	DB "Page 0 not mapped", NEWLINE
SUNMAP	DB "Page 0 unmapped", NEWLINE
SFUNMAP	DB "Page 0 failed to unmap:", NEWLINE
BUFFER	DB 06H DUP (' '), 00H	; Buffer for number to string conversion
EMMBASE	DW 0000H				; EMM Page Frame Segment
EMMSIZE	DW 0000H           		; Total number of pages in system
EMMFREE	DW 0000H				; Number of unallocated pages
EMMHNDL DW 0000H				; Handle

DSEG ENDS

CSEG    SEGMENT PARA PUBLIC 'CODE'
		ASSUME CS:CSEG, DS:DSEG

;------ EMMDEMO ------
;
; Initialized EMM then prints
; Base frame and available 
; Expanded memory
;
; Uses EMMLIB

		PUBLIC EMMDEMO

		EXTRN EMM_INIT:FAR, EMM_ALLOC:FAR, EMM_FREE:FAR, EMM_MAP:FAR

EMMDEMO	PROC FAR

		MOV AX, DSEG            ; Initialize DS
		MOV DS, AX
		
		CALL FAR PTR EMM_INIT   ; Initialize Expanded Memory Manager
		JC @@ABORT             	; and EMM data. Exit on error
		
		JMP @@MAIN				; On success:
								; AX = Base Frame
								; BX = Free pages
								; DX = Total pages

@@ABORT:
		JMP  @@NOEMM			; NOEMM is beyond a SHORT jump
								; ... so we JMP short to @@ABORT
								; ... then JMP to @NOEMM

@@MAIN:		
		MOV DS:[EMMBASE], AX    ; Save values
		MOV DS:[EMMFREE], BX
		MOV DS:[EMMSIZE], DX
		
		MOV CX, 10H             ; Set conversion to base 16
		MOV AX, DS:[EMMBASE]    ; Show base frame info
		MOV DX, OFFSET SBASE    
		CALL FAR PTR INFO
		
		MOV CX, 0AH             ; Set succeeding conversions to base 10
		MOV AX, 4000H           ; Show page size 4000H = 16384 (size of page in bytes)
		MOV DX, OFFSET SPAGE
		CALL FAR PTR INFO
		
		MOV AX, DS:[EMMSIZE]    ; Show total number of pages
		MOV DX, OFFSET STOTAL   
		CALL FAR PTR INFO
		
		MOV AX, DS:[EMMFREE]    ; Show free pages
		MOV DX, OFFSET SFREE
		CALL FAR PTR INFO

		MOV AX, DS:[EMMFREE]	; Check if we have enough memory
		CMP AX, ALLOC
		JB	@@LESS
		
		MOV AX, ALLOC			; Allocate pages
		CALL EMM_ALLOC
		JB @@FAIL

		MOV DS:[EMMHNDL], AX	; Save handle
		
		MOV CX, 0AH				; Show number of pages allocated
		MOV AX, ALLOC
		MOV DX, OFFSET SALLOC
		CALL FAR PTR INFO

		CALL @@NEWL
		MOV DX, OFFSET SOK		; Show allocation success
		CALL FAR PTR PRINT
		
		MOV AX, 0				; Physical Page
		MOV BX, 0				; Logical Page
		MOV DX, DS:[EMMHNDL]	; Get handle
		CALL EMM_MAP
		JB @@NOMAP

		CALL @@NEWL
		MOV DX, OFFSET SMAPPED	; Page mapped
		CALL FAR PTR PRINT
		
		MOV BX, 0FFFFH			; Unmap
		MOV DX, DS:[EMMHNDL]	; Get handle
		CALL EMM_MAP
		JB @@NOUNMAP

		CALL @@NEWL
		MOV DX, OFFSET SUNMAP	; Page unmapped
		CALL FAR PTR PRINT
		
		MOV AX, DS:[EMMHNDL]	; Get handle
		CALL EMM_FREE			; Free memory
		JB @@LEAK
				
		CALL @@NEWL
		MOV DX, OFFSET SFREED	; Memory freed
		CALL FAR PTR PRINT
		
@@OK:
		MOV AX, 4C00H           ; Set exit code to 0
		JMP @@EXIT

@@NEWL	LABEL NEAR
		MOV DX, OFFSET SENDL	; start on new line
		CALL FAR PTR PRINT
		RETN

@@LESS:
		CALL @@NEWL
		MOV DX, OFFSET SLESS	; Not enough expanded memory
		CALL FAR PTR PRINT
		JMP @@ERROR

@@FAIL:
		CALL @@NEWL
		MOV DX, OFFSET SFAIL	; Expanded memory not allocated
		CALL FAR PTR PRINT
		JMP @@ERROR

@@LEAK:
		CALL @@NEWL
		MOV DX, OFFSET SLEAK	; Expanded memory not freed
		CALL FAR PTR PRINT
		JMP @@ERROR

@@NOMAP:
		CALL @@NEWL
		MOV DX, OFFSET SNOMAP	; Physical page not mapped
		CALL FAR PTR PRINT
		JMP @@ERROR

@@NOUNMAP:
		CALL @@NEWL
		MOV DX, OFFSET SFUNMAP	; Physical page not unmapped
		CALL FAR PTR PRINT
		JMP @@ERROR
				
@@NOEMM:
		CALL @@NEWL
		MOV DX, OFFSET SNONE    ; Expanded memory manager is not available
		CALL FAR PTR PRINT

@@ERROR:		
		MOV AX, 4C01H           ; Set exit code to 1

@@EXIT:         
		INT 21H

EMMDEMO	ENDP

;------ CLEAR ------
;
; Clears buffer
;
; Inputs:
;		ES:DI = Pointer to buffer
;		CX = Size of buffer in bytes

		PUBLIC CLEAR

CLEAR	PROC FAR
		
		PUSHF					; Save registers
		PUSH ES
		PUSH AX
		PUSH DI
		
		MOV AL, ' '				; Clear buffer
		CLD
		REPZ STOSB
		
		POP DI					; Restore registers
		POP AX
		POP ES
		POPF
		
		RET

CLEAR	ENDP

;------ CONVERT ------
;
; Convert number to string in buffer
;
; Inputs:
;		AX = Number
;       CX = Base
;		ES:DI = Pointer to end of buffer

		PUBLIC CONVERT

CONVERT	PROC FAR
		
		PUSHF					; Save registers
		PUSH DS
		PUSH ES
		PUSH AX
		PUSH DX
		PUSH DI
		
@@LOOP:
		XOR DX, DX				; Clear upper half of 32bit number in DX:AX
		DIV CX					; Process one digit at a time
		
		CMP DL, 09H				; Check if remainder is not numeric
		JA @@FIX
		
		ADD DL, '0'				; Convert digit to ASCII equivalent
		JMP @@STORE

@@FIX:
		ADD DL, 37H				; Convert digit to A-Z
		
@@STORE:                
		MOV [DI], DL			; Store in buffer then move to next location
		DEC DI
		OR AX, AX				; Check if there are any digits left to convert
		JZ @@END
		JMP @@LOOP
		
@@END:
		POP DI					; Restore registers
		POP DX
		POP AX
		POP ES
		POP DS
		POPF

		RET

CONVERT ENDP

;------ STRLEN ------
;
; Get string length
;
; Inputs:
;
;		DS:DX = Offset to string (00H terminated)
;
; Outputs:
;
;		CX = String Length

		PUBLIC STRLEN
		
STRLEN	PROC FAR

		PUSH ES					; Save registers
		PUSH AX
		PUSH DI
		PUSHF
		
		MOV AX, DS				; Copy DS:DX into ES:DI
		MOV ES, AX
		MOV DI, DX
		
		XOR AX, AX				; Scan for end of string (NULL = 00H)
		XOR CX, CX				; Initialize stringt length

		CLD						; Search in Forward direction

@@LOOP	LABEL NEAR

		SCASB
		JZ @@EXIT
		INC CX					; String length in CX
		JMP @@LOOP

@@EXIT:

		POPF
		POP DI
		POP AX
		POP ES
		
		RETF

STRLEN	ENDP

;------ PRINT ------
;
; Prints string. Uses DOS's print (00H terminated)
; string service
;
; Inputs:
;
;		DS:DX = Offset to string (00H terminated)

		PUBLIC PRINT

PRINT	PROC FAR
		
		PUSHF					; Save registers
		PUSH AX
		PUSH BX
		PUSH CX
		
		CALL FAR PTR STRLEN		; Get string length into CX
		
		OR CX, CX				; Check if there is
		JZ @@EXIT				; text to print
		
		MOV AH, 40H				; Print using DOS service
		MOV BX, 0001H			; Print to STDOUT
		INT 21H

@@EXIT:
		
		POP CX					; Restore registers
		POP BX
		POP AX
		POPF
		
		RET

PRINT	ENDP

;------ CPRINT ------
;
; Converts number then prints string
;
; Inputs:
;
;		AX = Number to convert
;       CX = Base

		PUBLIC CPRINT

CPRINT	PROC FAR

		PUSHF					; Save Registers
		PUSH DS
		PUSH ES
		PUSH DX
		PUSH DI

		PUSH AX					; Save number in stack
		MOV AX, DSEG
		MOV DS, AX				; Point DS:DX to buffer
		MOV DX, OFFSET BUFFER
		MOV ES, AX				
		MOV DI, DX				; Point ES:DI to start of buffer
		
		PUSH CX					; Clear buffer (6 characters)
		MOV CX, 06H
		CALL FAR PTR CLEAR
		
		POP CX					; Restore base number in CX
		ADD DI, 05H				; Point ES:DI to end of buffer
		POP AX					; Restore number in AX
		
		CALL FAR PTR CONVERT	; Do conversion
		CALL FAR PTR PRINT		; ... then print
		
		POP DI					; Restore registers
		POP DX
		POP ES
		POP DS
		POPF
		
		RET

CPRINT	ENDP

;------ INFO ------
;
; Converts number, prints it, adds caption/info
;
; Inputs:
;
;		AX = Number to convert
;		CX = Base
;       DS:DX = Caption string

		PUBLIC INFO

INFO	PROC FAR
		
		CALL FAR PTR CPRINT		; Convert and print number
		CALL FAR PTR PRINT		; Print caption

		RET

INFO	ENDP

CSEG    ENDS

		END EMMDEMO
