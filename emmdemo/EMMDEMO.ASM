; Expanded Memory Manager Demo
;
; Uses EMM Library

		LOCALS @@
		
		TITLE EMMDEMO
		
		.MODEL SMALL
		.STACK 0100H

DSEG SEGMENT    PARA PUBLIC 'DATA'
SBASE	DB " Base frame",0AH,0DH,"$"
SPAGE	DB " Page size in bytes",0AH,0DH,"$"
STOTAL	DB " Total 16K pages",0AH,0DH,"$"
SFREE	DB "  Free 16K pages",0AH,0DH,"$"
SNONE	DB "Expanded Memory not available",0AH,0DH,"$"
BUFFER	DB 6 DUP ('0'), "$"
EMMBASE	DW 0H					; EMM Page Frame Segment
EMMSIZE	DW 0H           		; Total number of pages in system
EMMFREE	DW 0H					; Number of unallocated pages
DSEG ENDS

CSEG    SEGMENT PARA PUBLIC 'CODE'
		ASSUME CS:CSEG

;------ EMMDEMO ------
;
; Initialized EMM then prints
; Base frame and available 
; Expanded memory
;
; Uses EMMLIB

		PUBLIC EMMDEMO

		EXTRN EMM_INIT:FAR

EMMDEMO	PROC FAR

		MOV AX, DSEG            ; Initialize DS
		MOV DS, AX
		
		CALL FAR PTR EMM_INIT   ; Initialize Expanded Memory Manager
		JC @@ERROR              ; and EMM data. Exit on error

								; On success:
								; AX = Base Frame
								; BX = Free pages
								; DX = Total pages
		
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
				
		MOV AX, 4C00H           ; Set exit code to 0
		JMP @@EXIT

@@ERROR:
		MOV DX, OFFSET SNONE    ; Expanded memory manager is not available
		CALL FAR PTR PRINT
		
		MOV AX, 4C01H           ; Set exit code to 1

@@EXIT:         
		INT 21H

EMMDEMO	ENDP

;------ CLEAR ------
;
; Clears buffer
;
		PUBLIC CLEAR

CLEAR	PROC FAR
		
		PUSHF
		PUSH ES
		PUSH AX
		PUSH CX
		PUSH DI
		
		MOV AX, DSEG
		MOV ES, AX
		XOR AX, AX
		MOV DI, OFFSET BUFFER
		MOV CX, 3
		CLD
		REPZ STOSW
		
		POP DI
		POP CX
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
		
		PUSHF
		PUSH DS
		PUSH ES
		PUSH AX
		PUSH DX
		PUSH DI
		
		CALL FAR PTR CLEAR

@@LOOP:
		XOR DX, DX
		DIV CX
		
		CMP DL, 09H
		JA @@FIX
		
		ADD DL, '0'
		JMP @@STORE

@@FIX:
		SUB DL,0AH
		ADD DL,'A'
		
@@STORE:                
		MOV [DI], DL
		DEC DI
		OR AX, AX
		JZ @@END
		JMP @@LOOP
		
@@END:
		POP DI
		POP DX
		POP AX
		POP ES
		POP DS
		POPF

		RET

CONVERT ENDP

;------ PRINT ------
;
; Prints string. Uses DOS's print ($-terminated)
; string service
;
; Inputs:
;
;		DS:DX = Offset to string ($-terminated)

		PUBLIC PRINT

PRINT	PROC FAR
		
		PUSHF
		PUSH AX
		
		MOV AH, 09H
		INT 21H
		
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

		PUSHF
		PUSH DS
		PUSH ES
		PUSH DX
		PUSH DI

		PUSH AX					; Save number in stack
		MOV AX, DSEG
		MOV DS, AX				; Point DS:DX to buffer
		MOV DX, OFFSET BUFFER
		MOV ES, AX				; Point ES:DI to end of buffer
		MOV DI, DX
		ADD DI, 05H			
		POP AX					; Restore number in ax
		
		CALL CONVERT            ; Do conversion
		CALL PRINT				; ... then print
		
		POP DI
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
		
		CALL CPRINT				; Convert and print number
		CALL PRINT				; Print caption

		RET

INFO	ENDP

CSEG    ENDS

		END EMMDEMO
