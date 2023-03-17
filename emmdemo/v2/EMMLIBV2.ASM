; Expanded Memory Library V2.0
;
; Library with "High-Level" calling interface

	LOCALS @@
		
	TITLE EMMLIBV2

EMMDSEG SEGMENT PARA PUBLIC 'DATA'
EMMNAME	DB "EMMXXXX0", 00H	; Expanded Memory Manager Driver Name
EMMBASE	DW 0000H			; Base Frame Segment
EMMCODE	DW 0000H			; DOS/EMM Error Codes
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
;   BP+06 =  OFFSET address of destination array
;   BP+08 = SEGMENT address of destination array
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
	JB @@ERROR
	
	CALL EMM_OK				; Check if Expanded Memory Manager is working
	JB @@ERROR

	PUSH AX					; Save registers (**)
	PUSH DX

	MOV AX, [BP+08H]		; Get user data segment
	MOV DX, [BP+06H]		; Get user data offset

	PUSH DX					; Pass pointer to user data
	PUSH AX
	CALL EMM_INFO			; Get EMM Info
	
	POP DX					; Restores DX, AX 
	POP AX					; (**) These are not the
							; same values on the
							; call to EMM_INFO
	
	JNB @@OK				; Check if there were errors
	
@@ERROR:
	
	POPF
	
	STC						; Set CF = There were errors
	
	JMP @@EXIT

@@OK:
		
	POPF
	
	CLC						; Clear CF = No Error

@@EXIT:

	POP BP
	
	RET 4

EMM_INIT ENDP

;------ EMM_CHECK ------
;
; Tests for Expanded Memory Manager using the
; driver name compare method in interrupt vector
; segment.

	PUBLIC EMM_CHECK

EMM_CHECK PROC FAR

	PUSHF					; Save flags

	PUSH DS					; Save registers
	PUSH ES
	PUSH AX
	PUSH BX
	PUSH CX
	PUSH SI
	PUSH DI

	MOV AX, EMMDSEG
	MOV DS, AX             	; Set DS = Data Segment
	MOV SI, OFFSET EMMNAME	; Set DS:SI = EMM Device Driver Name
		
	MOV AX, 3567H          	; AH = 35H Get interrupt vector
	INT 21H                	; AL = 67H Expanded Memory Manager
							; Returns ES:BX = Address of interrupt vector
								
	MOV DI, 000AH			; Device driver name starts at ES:000AH
	MOV CX, 0008H     	    ; Compare up to 8 characters
	
	CLD                     ; Compare in forward direction
	REPZ CMPSB              ; Compare DS:SI to ES:DI
	JNZ @@EMSERROR			; EMM is not present if names do not match
		
	XOR AX, AX             	; Set error code = 0, EMM driver present
	JMP @@SETCODE

@@EMSERROR:
	
	MOV AX, 0080H			; EMS error

@@SETCODE:
	
	MOV DS:[EMMCODE], AX	; Set Error Code
	
	OR AX, AX				; Check if there were errors

	POP DI					; Restore registers
	POP SI
	POP CX
	POP BX
	POP AX
	POP ES
	POP DS

	JZ @@OK					; Set CF

@@ERROR:
	
	POPF
	
	STC						; Set CF = There were errors
	
	JMP @@EXIT

@@OK:
		
	POPF
	
	CLC						; Clear CF = No Error

@@EXIT:

	RET
		
EMM_CHECK ENDP

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
	JB @@DOSERROR			; Exit on error
		
	MOV BX, AX             	; File handle in AX after DOS call to 3DH
	MOV AX, 4407H          	; IOCTL - Get Output Status
	INT 21H
	JB @@ERRORCLOSE			; Close handle on error

	CMP AL, 0FFH			; Check if EMS device driver
	JNZ @@NOTEMS
	
	JMP @@CLOSE

@@NOTEMS:
	MOV AL, 05H				; DOS Error code for
							; Access Denied

@@ERRORCLOSE:

	MOV DX, AX				; Set DOS ERROR Code
	XOR DH, DH

@@CLOSE:

	MOV AX, 3E00H			; Close file handle
	INT 21H
	JB @@DOSERROR
	
	XOR DX, DX
	JMP @@SETCODE

@@DOSERROR:
	
	MOV DX, AX				; Set DOS ERROR Code
	XOR DH, DH

@@SETCODE:
	
	MOV AX, DX
	MOV DS:[EMMCODE], AX	; Set Error Code

	OR AX, AX				; Check if there were errors

	POP DX					; Restore registers
	POP BX
	POP AX
	POP DS						

	JZ @@OK					; Set CF

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

	JZ @@OK					; Set CF

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
;   BP+06 =  OFFSET address of destination array
;   BP+08 = SEGMENT address of destination array
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

	MOV AX, [BP+08H]		; Get user data segment
	MOV DI, [BP+06H]		; Get user data offset
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

	JZ @@OK					; Set CF

@@ERROR:
	
	POPF
	
	STC						; Set CF = There were errors
	
	JMP @@EXIT

@@OK:
		
	POPF
	
	CLC						; Clear CF = No Error

@@EXIT:

	POP BP

	RET 4
		
EMM_INFO ENDP

;------ EMM_ALLOC -----
;
; Allocates pages and
; get handle.
;
; Inputs:
;	BP+06 = Number of pages to allocate (WORD) 
;
;	On success:
;	CF is clear
;	AX = Handle (0001H to 00FEH)
;
;	On failure:
;	AX = FFFFH
;	CF is set

	PUBLIC EMM_ALLOC
		
EMM_ALLOC PROC FAR

	PUSH BP
	MOV BP, SP

	PUSHF					; Save flags
	
	PUSH DS					; Save registers
	PUSH BX					
	PUSH DX
	
	MOV AX, EMMDSEG			; Point to EMM Data
	MOV DS, AX
	
	CALL EMM_OK
	JB @@EMSERROR

	MOV BX, [BP + 06H]		; Get number of pages
							; from the stack

	MOV AH, 43H				; Allocate pages
	INT 67H
		
	OR AH, AH				; Check if allocation failed
	JNZ @@EMSERROR
	
	XOR AX, AX				; No error
	JMP @@SETCODE

@@EMSERROR:

	MOV AL, AH				; Set error code
	XOR AH, AH
	
	MOV DX, 0FFFFH			; Set handle to -1

@@SETCODE:

	MOV DS:[EMMCODE], AX
	
	OR AX, AX				; Check for errors
	
	MOV AX, DX				; Get handle
	
	POP DX					; Restore registers
	POP BX
	POP DS

	JZ @@OK					; Set CF

@@ERROR:
	
	POPF
	
	STC						; Set CF = There were errors
	
	JMP @@EXIT

@@OK:
		
	POPF
	
	CLC						; Clear CF = No Error

@@EXIT:

	POP BP

	RET 2

EMM_ALLOC ENDP

;------ EMM_FREE ------
;
; Frees allocated memory
;
; Inputs:
;	BP+06: Page handle to free
;
;	On success:
;	CF is clear
;
;	On failure:
;	CF is set

	PUBLIC EMM_FREE

EMM_FREE PROC FAR

	PUSH BP
	MOV BP, SP
	
	PUSHF					; Save flags
	
	PUSH DS					; Save registers
	PUSH AX
	PUSH DX
	
	MOV AX, EMMDSEG			; Point to EMM Data
	MOV DS, AX
		
	MOV DX, [BP+06H]		; De-allocate handle
	MOV AH, 45H				; ... and memory
	INT 67H					; ... in DX
		
	OR AH, AH				; Check if de-allocation
	JNZ @@EMSERROR			; failed
		
	XOR AX, AX				; No error
	JMP @@SETCODE

@@EMSERROR:

	MOV AL, AH				; Set error code
	XOR AH, AH
		
@@SETCODE:
	
	MOV DS:[EMMCODE], AX
	
	OR AX, AX				; Check for errors

	POP DX					; Restore registers
	POP AX
	POP DS

	JZ @@OK					; Set CF
		
@@ERROR:
	
	POPF
	
	STC						; Set CF = There were errors
	
	JMP @@EXIT

@@OK:
		
	POPF
	
	CLC						; Clear CF = No Error

@@EXIT:

	POP BP

	RET 2

EMM_FREE ENDP

;------ EMM_MAP -------
;
; Maps logical page to
; Physical page (0-3)
;
; Inputs:
;	BP+06 = Handle
;	BP+08 = Logical page (0FFFFH to unmap)
;	BP+0A = Physical page 0-3
;
;	On success:
;	CF is clear
;
;	On failure:
;	CF is set

	PUBLIC EMM_MAP

EMM_MAP	PROC FAR

	PUSH BP
	MOV BP, SP

	PUSHF					; Save flags
	
	PUSH DS					; Save registers
	PUSH AX
	PUSH BX
	PUSH DX
	
	PUSH AX					; Point to EMM Data
	MOV AX, EMMDSEG
	MOV DS, AX
	POP AX

	MOV DX, [BP+06H]		; Get handle
	MOV BX, [BP+08H]		; Get logical page to map/unmap
	MOV AX, [BP+0AH]		; Get physical page

	MOV AH, 44H				; Map/Unmap logical page
	INT 67H					; to/from physical page

	MOV AL, AH
	XOR AH, AH

	MOV DS:[EMMCODE], AX	; Set error code
	
	OR AX, AX				; Check for errors

	POP DX
	POP BX
	POP AX
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

	RET 6

EMM_MAP ENDP

;------ EMM_PUT -------
;
; Copies data into mapped page
; Assumes Expanded Memory Library was
; Initialized with EMM_INIT
;
; Inputs:
;   BP+06 =  OFFSET address of source array
;   BP+08 = SEGMENT address of source array
;	BP+0A = Physical Page number
;	BP+0C = Number of Bytes to copy 

	PUBLIC EMM_PUT

EMM_PUT PROC FAR
	
	PUSH BP
	MOV BP, SP
	
	PUSHF					; Save flags

	PUSH DS					; Save registers
	PUSH ES
	PUSH AX
	PUSH BX
	PUSH CX
	PUSH DX
	PUSH SI
	PUSH DI

	MOV BX, EMMDSEG
	MOV ES, BX
	MOV BX, ES:[EMMBASE]

	OR BX, BX				; Check if EMM Library
	JZ @@EMSERROR			; was initialized

	MOV AX, [BP+0AH]		; Get physical page
	CMP AX, 0003H			; and check if out of bounds
	JA @@INVALID
	
	MOV CX, [BP+0CH]
	OR CX, CX				; Check if there are
	JZ @@DONE				; bytes to copy
	
	MOV DX, [BP+08H]		; Setup source in
	MOV SI, [BP+06H]		; DS:SI
	MOV DS, DX

	MOV ES, BX				; Point to EMM Base Page Frame
	MOV DI, 4000H			; Setup destination:
	MUL DI					; Base Frame Segment:[Physical Page * 16384]
	MOV DI, AX
	
	CLD
	REPZ MOVSB				; Copy data to the physical page (expanded memory)
							; ... This physical page is the portion of
							; ...  expanded memory that is currently mapped
							; ... to the physical page

@@DONE:
	
	XOR AX, AX				; No errors
	JMP @@SETCODE

@@INVALID:

	MOV AX, 008BH			; invalid physical page
	JMP @@SETCODE

@@EMSERROR:
	
	MOV AX, 0080H			; Error

@@SETCODE:
	
	MOV BX, EMMDSEG			; Setup exit code
	MOV ES, BX
	MOV ES:[EMMCODE], AX
	
	OR AX, AX				; Check if there were errors
	
	POP DI
	POP SI
	POP DX
	POP CX
	POP BX
	POP AX
	POP ES
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

	RET 8

EMM_PUT ENDP

;------ EMM_GET -------
;
; Copies data from mapped page
; into destination buffer in
; conventional memory
;
; Initialized with EMM_INIT
;
; Inputs:
;   BP+06 =  OFFSET address of source array
;   BP+08 = SEGMENT address of source array
;	BP+0A = Physical Page number
;	BP+0C = Number of Bytes to copy 

	PUBLIC EMM_GET

EMM_GET PROC FAR

	PUSH BP
	MOV BP, SP
	
	PUSHF					; Save flags
	
	PUSH DS					; Save registers
	PUSH ES
	PUSH AX
	PUSH BX
	PUSH CX
	PUSH DX
	PUSH SI
	PUSH DI

	MOV BX, EMMDSEG
	MOV ES, BX
	MOV BX, ES:[EMMBASE]

	OR BX, BX				; Check if EMM Library
	JZ @@EMSERROR			; was initialized

	MOV AX, [BP+0AH]		; Get physical page
	CMP AX, 0003H			; Check if AX is out of bounds
	JA @@INVALID
	
	MOV CX, [BP+0CH]
	OR CX, CX				; Check if there are
	JZ @@DONE				; bytes to copy

	MOV DS, BX				; Point DS to EMM Base Page Frame Segment
	MOV SI, 4000H			; Setup Source:
	MUL SI					; Base Frame Segment:[Physical Page * 16384]
	MOV SI, AX

	MOV DX, [BP+08H]		; Setup destination in
	MOV DI, [BP+06H]		; ES:DI
	MOV ES, DX
	
	CLD
	REPZ MOVSB				; Copy data from physical page to destination buffer
							; ... This physical page is the portion of 
							; ... expanded memory that is currently mapped
							; ... to the physical page

@@DONE:
	
	XOR AX, AX				; No errors
	JMP @@SETCODE
	
@@INVALID:

	MOV AX, 008BH			; invalid physical page
	JMP @@SETCODE

@@EMSERROR:
	
	MOV AX, 0080H			; Error

@@SETCODE:
	
	MOV BX, EMMDSEG			; Setup exit code
	MOV ES, BX
	MOV ES:[EMMCODE], AX
	
	OR AX, AX				; Check if there were errors
	
	POP DI
	POP SI
	POP DX
	POP CX
	POP BX
	POP AX
	POP ES
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

	RET 8
	
EMM_GET ENDP

EMMCSEG ENDS
	
	END
