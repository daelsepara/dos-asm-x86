; Expanded Memory Library V2.0
;
; Library with "High-Level" calling interface

	LOCALS @@
		
	TITLE EMMLIBV2


EMMDSEG SEGMENT PARA PUBLIC 'DATA'
EMMNAME	DB "EMMXXXX0", 00H	; Expanded Memory Manager Driver Name
EMMCODE DW 0000H			; Error codes:
							; 0000 No error
							; 0001 Expanded memory not present
							; 0002 Expanded memory driver not loaded
							; 0003 Expanded memory driver error
							; 0004 Expanded memory driver not ready
							
EMMDSEG ENDS

; Offsets in user-provided array
EMMBASE EQU 0               ; Expanded Memory Page Frame Segment
EMMSIZE EQU 2               ; Total number of pages in system
EMMFREE EQU 4               ; Number of unallocated pages

EMMCSEG SEGMENT PARA PUBLIC 'CODE'
	ASSUME CS:EMMCSEG, DS:EMMDSEG

; Subroutines now follow a PASCAL/STDCALL-like calling convention:
;
; 1. Parameters are passed on stack: Order is from right to left
; 2. All subroutines are FAR addresses
; 3. All modified registers are preserved
; 4. Passed parameters are popped off the stack except:
; 5. When single values need to be returned:
;    a) AX = 16bit value / Near Pointer
;    b) DX:AX = 32bit value / Far pointer

;------ EMM_INIT ------
;
; Initializes EMM data
;
; Inputs:
;   FAR PTR to Destination Array
;   SP+6: SEGMENT address of destination array
;   SP+8:  OFFSET address of destination array
;
; Returns:
;   On success:
;
;   CF is clear
;   
;   FAR PTR contains:
;   -------------------------------------------
;   OFFSET: Description 
;   -------------------------------------------
;   0000-1: Expanded Memory Page Frame Segment
;   0002-3: Total number of pages in system
;   0004-5: Number of unallocated pages
;   0006-7: EMM Version
;
;   On error:
;   
;   CF is set

    PUBLIC EMM_INIT

EMM_INIT PROC FAR

	PUSH BP
	MOV BP, SP
	
	PUSHF					; Save flags

	CALL EMM_TEST			; Check if Expanded Memory Manager is present
	JC @@ERROR
	
	CALL EMM_OK
	JC @@ERROR
	
	JMP @@OK

@@ERROR:
	
	POPF
	
	STC						; Set CF = There were errors
	
	JMP @@EXIT

@@OK:
		
	POPF
	
	CLC						; Clear CF = No Error

@@EXIT:

	POP BP
	
	RET 8

EMM_INIT ENDP

;------ EMM_TEST ------
;
; Tests for Expanded Memory Manager using the
; file open method. If file exists then we
; test if the opened file is a driver and
; not a normal file
		
	PUBLIC EMM_TEST

EMM_TEST PROC FAR

	PUSH BP
	MOV BP, SP

	PUSHF					; Save Flag
	
	PUSH DS					; Save Registers
	PUSH AX
	PUSH BX
	PUSH DX
	
	MOV AX, EMMDSEG
	MOV DS, AX             	; Set DS = Data Segment
		
	MOV AX, 3D00H          	; AH = 3DH Open file, AL = 00H Read mode only
	MOV DX, OFFSET EMMNAME 	; Set DS:DX to EMMNAME in data segment
	INT 21H
	JC @@NOEXPM				; Exit on error
		
	MOV BX, AX             	; File handle in AX after DOS call to 3DH
	MOV AX, 4407H          	; IOCTL - Get Output Status
	INT 21H
	JC @@NOTLOADED			; Close handle on error

	CMP AL, 0FFH			; Check if device driver
	JNZ @@NOTLOADED
	
	JMP @@CLOSE
		
@@NOTLOADED:
	
	MOV DX, 0002H			; Set error code to 2
							; Expanded memory driver not loaded
@@CLOSE:

	MOV AX, 3E00H			; Close file handle
	INT 21H
	JC @@DRVERR
	
	XOR DX, DX
	JMP @@SETCODE

@@DRVERR:
	MOV DX, 0003H			; Driver error
	JMP @@SETCODE

@@NOEXPM:
	MOV DX, 00001H			; No expanded memory present
		
@@SETCODE:
	MOV AX, DX
	
	MOV DS:[EMMCODE], AX	; Set EMMDSEG:[EMMCODE]
	
	POP DX					; Restore DX, BX
	POP BX
	
	OR AX, AX				; Check if there were errors

	POP AX					; Restore remaining registers
	POP DS						

	JZ @@OK

@ERROR:
	
	POPF
	
	STC						; Set CF = There were errors
	
	JMP @@EXIT

@@OK:
		
	POPF
	
	CLC						; Clear CF = No Error

@@EXIT:

	POP BP					; Balance the stack

	RET
		
EMM_TEST ENDP

;------ EMM_OK ------
;
; Tests if Expanded Memory Manager (if present) is working.

	PUBLIC EMM_OK

EMM_OK	PROC FAR

	PUSH BP
	MOV BP, SP

	PUSHF					; Save registers
	PUSH DS
	PUSH AX
								
	MOV AX, EMMDSEG			; Point DS to EMM Data
	MOV DS, AX
		
	MOV AH, 40H				; Get Expanded Memory Manager Status
	INT 67H

	OR AH, AH
	JNZ @@SETERR
	
	XOR AX, AX
	JMP @@SETCODE

@@SETERR:

	MOV AX, 0003H			; 0003 - Driver not ready
	
@@SETCODE:
	
	MOV DS:[EMMCODE], AX	; Set EMMCODE

	OR AX, AX				; Check for errors
	
	POP AX					; Restore registers
	POP DS

	JZ @@OK

@@ERROR:
	
	POPF
	
	STC						; Set CF = There were errors
	
	JMP @@EXIT

@@OK:
		
	POPF
	
	CLC						; Clear CF = No Error

@@EXIT:

	POP BP
	
	RET

EMM_OK  ENDP

EMMCSEG ENDS
	
	END
