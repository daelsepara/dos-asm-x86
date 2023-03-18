; Expanded Memory Manager Demo v2.0
;
; Uses EMM Library v2.0, Utils

	LOCALS @@

	TITLE EMMDEMO2

	.MODEL SMALL
	.STACK 0400H				; Increased stack stize

DSEG SEGMENT PARA PUBLIC 'DATA'

NEWLINE	EQU 0AH, 0DH, 00H		; New line
ALLOC	EQU 0100H				; Number of pages to allocate
SENDL	DB NEWLINE
SVERS   DB " EMS Version", NEWLINE
SBASE	DB " Base frame", NEWLINE
SPAGE	DB " Page size in bytes", NEWLINE
STOTAL	DB " Total 16K pages", NEWLINE
SFREE	DB "  Free 16K pages", NEWLINE
SALLOC	DB " Pages allocated", NEWLINE
SNONE	DB "Expanded Memory not available", NEWLINE
SOK     DB "Expanded Memory allocated", NEWLINE
SFAIL	DB "Expanded Memory not allocated", NEWLINE
SFREED	DB "Expanded Memory freed", NEWLINE
SLEAK	DB "Expanded Memory not freed", NEWLINE
SLESS	DB "Not enough expanded memory", NEWLINE
SINIT	DB "Expanded Memory Library not initialized", NEWLINE
SMAPPED	DB "Page 0 mapped", NEWLINE
SNOMAP	DB "Page 0 not mapped", NEWLINE
SUNMAP	DB "Page 0 unmapped", NEWLINE
SFUNMAP	DB "Page 0 failed to unmap:", NEWLINE
BUFFER	DB 06H DUP (' '), 00H	; Buffer for number to string conversion
EMMBASE	DW 0000H				; EMM Page Frame Segment
EMMSIZE	DW 0000H           		; Total number of pages in system
EMMFREE	DW 0000H				; Number of unallocated pages
EMMVERS DB 00H					; EMS Version
EMMHNDL DW 0000H				; Handle
TESTSTR DB "EMMDEMO2"			; Test string to copy to expanded memory page
EMMTEST DB "         read from page 0"	; Buffer string for bytes copied from
        DB NEWLINE				; expanded memory page 0
NULLSTR	DB 08H DUP (00H)		; 8 NULL bytes used to clear expanded memory page 0

DSEG ENDS

CSEG SEGMENT PARA PUBLIC 'CODE'
	ASSUME CS:CSEG, DS:DSEG

;------ EMMDEMO2 ------
;
; Initialized EMM then prints
; Base frame and available
; Expanded memory

	PUBLIC EMMDEMO2

	EXTRN EMM_INIT:FAR, EMM_ALLOC:FAR, EMM_FREE:FAR, EMM_MAP:FAR, EMM_PUT:FAR, EMM_GET:FAR
	EXTRN FILL:FAR, STRLEN:FAR, CONVERT:FAR, PRINT:FAR

EMMDEMO2 PROC FAR

	MOV AX, DSEG            	; Initialize DS
	MOV DS, AX

	MOV AX, OFFSET EMMBASE
	PUSH DS						; Push DSEG:EMMBASE
	PUSH AX						; as parameters to EMM_INIT
	CALL FAR PTR EMM_INIT		; Initialize Expanded Memory Manager
								; and EMM data

	JB @@ABRT00					; Exit on error
	JMP @@MAIN00				; On success:
								; EMM Info in:
								; DSEG:EMMBASE = Page frame
								; DSEG:EMMSIZE = Total pages
								; DSEG:EMMFREE = Unallocated pages
                            	; DSEG:EMMVERS = EMS Version number
@@ABRT00:

	JMP  @@NOEMM				; NOEMM is beyond a SHORT jump
								; ... so we JMP short to @@ABORT
								; ... then JMP to @NOEMM
@@MAIN00:

	CALL @@NEWL

	MOV CX, 10H					; Set conversion to base 16

	MOV AL, DS:[EMMVERS]		; Get version number
	XOR AH, AH					; Clear upper byte
	MOV DX, OFFSET SVERS		; Show version
	PUSH CX						; Push base
	PUSH AX						; Push number
	PUSH DS						; Push caption segment
	PUSH DX						; Push caption offset
	CALL FAR PTR INFO

	MOV AX, DS:[EMMBASE]
	MOV DX, OFFSET SBASE		; Show base frame info
	PUSH CX						; Push base
	PUSH AX						; Push number
	PUSH DS						; Push caption segment
	PUSH DX						; Push caption offset
	CALL FAR PTR INFO

	MOV CX, 0AH					; Set succeeding conversions to base 10

	MOV AX, 4000H
	MOV DX, OFFSET SPAGE		; Show page size 4000H = 16384 (size of page in bytes)
	PUSH CX						; Push base
	PUSH AX						; Push number
	PUSH DS						; Push caption segment
	PUSH DX						; Push caption offset
	CALL FAR PTR INFO

	MOV AX, DS:[EMMSIZE]
	MOV DX, OFFSET STOTAL		; Show total number of pages
	PUSH CX						; Push base
	PUSH AX						; Push number
	PUSH DS						; Push caption segment
	PUSH DX						; Push caption offset
	CALL FAR PTR INFO

	MOV AX, DS:[EMMFREE]
	MOV DX, OFFSET SFREE		; Show free pages
	PUSH CX						; Push base
	PUSH AX						; Push number
	PUSH DS						; Push caption segment
	PUSH DX						; Push caption offset
	CALL FAR PTR INFO

	MOV AX, DS:[EMMFREE]		; Check if we have enough memory
	CMP AX, ALLOC

	JB @@ABRT01
	JMP @@MAIN01

@@ABRT01:

	JMP @@LESS

@@MAIN01:

	MOV AX, ALLOC				; Allocate pages
	PUSH AX
	CALL EMM_ALLOC

	JB @@ABRT02
	JMP @@MAIN02

@@ABRT02:

	JMP @@FAIL

@@MAIN02:

	MOV DS:[EMMHNDL], AX		; Save handle

	MOV CX, 0AH					; Set base number to 10

	MOV AX, ALLOC
	MOV DX, OFFSET SALLOC		; Show number of pages allocated
	PUSH CX						; Push base
	PUSH AX						; Push number
	PUSH DS						; Push caption segment
	PUSH DX						; Push caption offset
	CALL FAR PTR INFO

	CALL @@NEWL
	MOV DX, OFFSET SOK			; Show allocation success
	PUSH DS
	PUSH DX
	CALL FAR PTR PRINT

	XOR AX, AX
	PUSH AX						; Push Physical Page 0 to stack
	PUSH AX						; Push Logical Page 0 to stack
	MOV AX, DS:[EMMHNDL]		; Get handle
	PUSH AX						; Push handle to stack
	CALL EMM_MAP				; Map logical page 0 to physical page 0

	JB @@ABRT03
	JMP @@MAIN03

@@ABRT03:

	JMP @@NOMAP

@@MAIN03:

	CALL @@NEWL
	MOV DX, OFFSET SMAPPED		; Logical page 0 was mapped to physical Page 0
	PUSH DS
	PUSH DX
	CALL FAR PTR PRINT

@@ABRT04:
@@MAIN04:

	MOV AX, 8
	PUSH AX						; Copy 8 bytes
	XOR AX, AX
	PUSH AX						; Physical Page 0 (destination page)
	MOV AX, OFFSET NULLSTR
	PUSH DS						; Push null string buffer address in (DS:AX)
	PUSH AX						; to stack
	CALL FAR PTR EMM_PUT		; Copies data from conventional memory
								; ... to expanded memory
								; ... one page at a time

	JB @@ABRT05

	MOV AX, 8
	PUSH AX						; Copies 8 bytes of test string to page 0
	XOR AX, AX
	PUSH AX						; Physical Page 0 (destination page)
	MOV AX, OFFSET TESTSTR
	PUSH DS						; Push test string buffer address to stack
	PUSH AX
	CALL FAR PTR EMM_PUT

	JB @@ABRT05
	JMP @@MAIN05

@@ABRT05:

	JMP @@INIT					; EMM Library was not initialized

@@MAIN05:

	MOV AX, 8					; Copy 8 bytes from page 0
	PUSH AX
	XOR AX, AX					; Physical Page 0 (source page)
	PUSH AX
	MOV AX, OFFSET EMMTEST
	PUSH DS						; Push destination array address to stack
	PUSH AX
	CALL FAR PTR EMM_GET		; Copies data from expanded memory
								; ... back to conventional memory
								; ... one page at a time
	JB @@ABRT06
	JMP @@MAIN06

@@ABRT06:

	JMP @@INIT					; EMM Library was not initialized

@@MAIN06:

	CALL @@NEWL
	MOV DX, OFFSET EMMTEST		; Print data copied from page (EMMTEST)
	PUSH DS
	PUSH DX
	CALL FAR PTR PRINT

	XOR AX, AX
	PUSH AX						; Physical page 0
	MOV BX, 0FFFFH				; Unmap Page
	PUSH AX
	MOV AX, DS:[EMMHNDL]		; Get handle
	PUSH AX
	CALL EMM_MAP				; Unmap physical page 0

	JB @@ABRT07
	JMP @@MAIN07

@@ABRT07:

	JMP @@NOUNMAP

@@MAIN07:

	CALL @@NEWL
	MOV DX, OFFSET SUNMAP		; Page 0 was unmapped
	PUSH DS
	PUSH DX
	CALL FAR PTR PRINT

	MOV AX, DS:[EMMHNDL]		; Get handle
	PUSH AX
	CALL EMM_FREE				; Free allocated expanded memory

	JB @@ABRT08
	JMP @@MAIN08

@@ABRT08:

	JMP @@LEAK

@@MAIN08:

	CALL @@NEWL
	MOV DX, OFFSET SFREED		; Expanded memory was freed
	PUSH DS
	PUSH DX
	CALL FAR PTR PRINT

@@OK:

	MOV AX, 4C00H				; Set exit code to 0
	JMP @@EXIT

@@NEWL LABEL NEAR

	MOV DX, OFFSET SENDL		; Prints a newline character
	PUSH DS
	PUSH DX
	CALL FAR PTR PRINT

	RETN

@@LESS:

	CALL @@NEWL
	MOV DX, OFFSET SLESS		; Not enough expanded memory
	PUSH DS
	PUSH DX
	CALL FAR PTR PRINT

	JMP @@ERROR

@@FAIL:

	CALL @@NEWL
	MOV DX, OFFSET SFAIL		; Expanded memory was not allocated
	PUSH DS
	PUSH DX
	CALL FAR PTR PRINT

	JMP @@ERROR

@@NOMAP:

	CALL @@NEWL
	MOV DX, OFFSET SNOMAP		; Physical page not mapped
	PUSH DS
	PUSH DX
	CALL FAR PTR PRINT

	JMP @@ERROR

@@INIT:

	CALL @@NEWL
	MOV DX, OFFSET SINIT		; EMM library not initialized
	PUSH DS
	PUSH DX
	CALL FAR PTR PRINT

	JMP @@ERROR

@@LEAK:

	CALL @@NEWL
	MOV DX, OFFSET SLEAK		; Expanded memory was not freed
	PUSH DS
	PUSH DX
	CALL FAR PTR PRINT

	JMP @@ERROR

@@NOUNMAP:

	CALL @@NEWL
	MOV DX, OFFSET SFUNMAP		; Physical page was not unmapped
	PUSH DS
	PUSH DX
	CALL FAR PTR PRINT

	JMP @@ERROR

@@NOEMM:

	CALL @@NEWL
	MOV DX, OFFSET SNONE		; Expanded memory manager is not available
	PUSH DS
	PUSH DX
	CALL FAR PTR PRINT

@@ERROR:

	MOV AX, 4C01H				; Set exit code to 1

@@EXIT:

	INT 21H

EMMDEMO2 ENDP

;------ CPRINT ------
;
; Converts number then prints string
;
; Inputs:
;	BP+06 = Number to convert
;	BP+08 = Base to convert number to

	PUBLIC CPRINT

CPRINT PROC FAR

	PUSH BP
	MOV BP, SP

	PUSHF						; Save flags
	PUSH DS                     ; Save registers
	PUSH AX

	MOV AX, DSEG                ; Set DS to DSEG
	MOV DS, AX

	MOV AX, ' '
	PUSH AX						; byte used to fill
	MOV AX, 6
	PUSH AX						; fill up to 6 characters
	MOV AX, OFFSET BUFFER
	PUSH DS						; pointer to buffer
	PUSH AX
	CALL FAR PTR FILL           ; clear buffer

	MOV AX, 6
	PUSH AX						; width of buffer
	MOV AX, [BP+08H]
	PUSH AX						; Base
	MOV AX, [BP+06H]
	PUSH AX						; Number to convert
	MOV AX, OFFSET BUFFER
	PUSH DS                     ; pointer to buffer
	PUSH AX
	CALL FAR PTR CONVERT        ; Convert number

	PUSH DS
	PUSH AX
	CALL FAR PTR PRINT          ; Print converted number

	POP AX						; Restore registers
	POP DS
	POPF						; Restore flags

	POP BP

	RET 4

CPRINT ENDP

;------ INFO ------
;
; Converts number, prints it, adds caption/info
;
; Inputs:
;	BP+06 =  OFFSET address of caption string
;	BP+08 = SEGMENT address of caption string
;	BP+0A = Number to convert
;	BP+0C = Base to convert number to

	PUBLIC INFO

INFO PROC FAR

	PUSH BP
	MOV BP, SP

	PUSHF						; Save flags
	PUSH AX						; Save registers

	MOV AX, [BP+0CH]			; Get base
	PUSH AX
	MOV AX, [BP+0AH]			; Get number to convert
	PUSH AX
	CALL FAR PTR CPRINT			; Convert and print number

	MOV AX, [BP+08H]			; segment address of caption string
	PUSH AX
	MOV AX, [BP+06H]			; offset address of caption string
	PUSH AX
	CALL FAR PTR PRINT			; Print caption string

	POP AX						; Restore registers
	POPF						; Restore flags

	POP BP

	RET 8

INFO ENDP

CSEG ENDS

	END EMMDEMO2
