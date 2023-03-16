; Expanded Memory Library V2.0
;
; Library with "High-Level" calling interface

	LOCALS @@
		
	TITLE EMMLIBV2

EMMDSEG SEGMENT PARA PUBLIC 'DATA'
EMMNAME	DB "EMMXXXX0", 00H	; Expanded Memory Manager Driver Name
EMMBASE	DW 0000H			; Base Frame Segment
EMMCODE	DW 0000H			; Error codes: see EMMCONST.INC
EMMDSEG ENDS

INCLUDE EMMCONST.INC

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
;   0000: Expanded Memory Page Frame Segment
;   0002: Total number of pages in system
;   0004: Number of unallocated pages
;   0006: EMM Version
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
	
	CALL EMM_OK				; Check if Expanded Memory Manager is working
	JC @@ERROR

	PUSH AX					; Save registers (**)
	PUSH DX

	MOV AX, [BP + 08H]		; Get user data segment
	MOV DX, [BP + 06H]		; Get user data offset

	PUSH DX					; Pass pointer to user data
	PUSH AX
	CALL EMM_INFO			; Get EMM Info
	
	POP DX					; Restores DX, AX 
	POP AX					; (**) These are not the
							; same values on the
							; call to EMM_INFO
	
	JC @@ERROR				; Check if there were errors
	
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
	
	MOV DX, EMM_NODRV		; Expanded memory driver not loaded

@@CLOSE:

	MOV AX, 3E00H			; Close file handle
	INT 21H
	JC @@EMSERROR
	
	XOR DX, DX
	JMP @@SETCODE

@@EMSERROR:
	
	MOV DX, EMM_DRIVER		; EMS Driver error
	JMP @@SETCODE

@@NOEXPM:
	
	MOV DX, EMM_NOMEM		; No expanded memory present
		
@@SETCODE:
	
	MOV AX, DX
	MOV DS:[EMMCODE], AX	; Set Error Code
	
	POP DX					; Restore DX, BX
	POP BX
	
	OR AX, AX				; Check if there were errors

	POP AX					; Restore remaining registers
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

	RET
		
EMM_TEST ENDP

;------ EMM_OK ------
;
; Tests if Expanded Memory Manager (if present) is working.

	PUBLIC EMM_OK

EMM_OK	PROC FAR

	PUSHF					; Save flags

	PUSH DS					; Save registers
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
	
	MOV AL, AH				; Use EMS Error codes
	XOR AH, AH
	
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

	RET

EMM_OK  ENDP

;------ EMM_INFO ------
;
; Gets Expanded memory information
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
;   0000: Expanded Memory Page Frame Segment
;   0002: Total number of pages in system
;   0004: Number of unallocated pages
;   0006: EMM Version
;
;   On error:
;   
;   CF is set

	PUBLIC EMM_INFO

EMM_INFO PROC FAR

	PUSH BP
	MOV BP, SP

	PUSHF

	PUSH DS
	PUSH ES
	PUSH AX
	PUSH BX
	PUSH DX
	PUSH DI

	MOV AX, [BP + 08H]		; Get user data segment
	MOV DI, [BP + 06H]		; Get user data offset
	MOV ES, AX				; Point ES:DI
							; to user data array
	
	MOV AX, EMMDSEG			; Point DS to EMMLIB
	MOV DS, AX				; Data segment
		
	MOV AH, 41H				; Get Page Frame Segment
	INT 67H
		
	OR AH, AH
	JNZ @@EMSERROR
			
	MOV ES:[DI+OFFBASE], BX	; Set EMM Page Frame Segment
	MOV DS:[EMMBASE], BX		
	
	MOV AH, 42H				; Get Page Counts
	INT 67H
		
	OR AH, AH
	JNZ @@EMSERROR
		
	MOV ES:[DI+OFFSIZE], DX	; Set total number of pages
	MOV ES:[DI+OFFFREE], BX	; Set total number of unallocated pages
	
	MOV AH, 46H
	INT 67H

	OR AH, AH
	JNZ @@EMSERROR

	MOV ES:[DI+OFFVERS], AL	; Set EMM version

	XOR AX, AX				; No error
	
	JMP @@SETCODE

@@EMSERROR:

	MOV AL, AH				; Use EMS error codes
	XOR AH, AH

	XOR BX, BX				; Clear EMM Data
	MOV DS:[EMMBASE], BX
	MOV ES:[DI+OFFBASE], BX
	MOV ES:[DI+OFFSIZE], BX
	MOV ES:[DI+OFFFREE], BX
	MOV ES:[DI+OFFVERS], BL

@@SETCODE:
	
	MOV DS:[EMMCODE], AX

	OR AX, AX				; Check if there were errors
	
	PUSH DI
	PUSH DX
	PUSH BX
	PUSH AX
	PUSH ES
	PUSH DS

	JNZ @ERROR				; Set CF

@ERROR:
	
	POPF
	
	STC						; Set CF = There were errors
	
	JMP @@EXIT

@@OK:
		
	POPF
	
	CLC						; Clear CF = No Error

@@EXIT:

	POP BP

	RET 8
		
EMM_INFO ENDP

EMMCSEG ENDS
	
	END
