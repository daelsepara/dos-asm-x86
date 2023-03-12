; Expanded Memory Manager Library
		
	LOCALS @@
		
	TITLE EMMLIB

EMMDSEG SEGMENT PARA PUBLIC 'DATA'
EMMNAME	DB "EMMXXXX0", 00H		; Expanded Memory Manager Driver Name
EMMBASE	DW 0000H			; EMM Page Frame Segment
EMMSIZE	DW 0000H			; Total number of pages in system
EMMFREE	DW 0000H                	; Number of unallocated pages
EMMCODE DB 00H				; Exit code
EMMDSEG ENDS

EMMCSEG SEGMENT PARA PUBLIC 'CODE'
	ASSUME CS:EMMCSEG, DS:EMMDSEG

;------ EMM_INIT ------
;
; Initializes EMM data
;
; Returns:
;	On success (CF clear):
;	AX = Base Page Frame Segment
;	BX = Number of free/unallocated pages (each 16Kbytes)
;	DX = Total number of pages
;
;	On failure (CF set):
;	AX = BX = DX = 0000H

	PUBLIC EMM_INIT

EMM_INIT PROC FAR

	PUSH DS
	PUSHF                   	; Save FLAGS
		
	MOV AX, EMMDSEG			; Point to EMMLIB data
	MOV DS, AX 
		
	CALL EMM_TEST			; Check if Expanded Memory Manager is present
	JC @@ERROR
		
	CALL EMM_OK             	; Check if Expanded Memory Manager is working
	JC @@ERROR

	CALL EMM_INFO			; Get info
	JC @@ERROR
		
	PUSH AX
	XOR AL, AL
	JMP @@EXIT
		
@@ERROR:
	PUSH AX
	MOV AL, 01H

@@EXIT:	
	MOV DS:[EMMCODE], AL
	POP AX

	CALL EMM_EXIT           	; Set CF flag
		
	POPF				; Restore FLAGS
	POP DS
	RET
		
EMM_INIT ENDP

;------ EMM_CHECK ------
;
; Tests for Expanded Memory Manager using the
; driver name compare method in interrupt vector
; segment.

	PUBLIC EMM_CHECK

EMM_CHECK PROC FAR
		
	PUSH DS				; Save registers
	PUSH ES
	PUSH AX
	PUSH CX
	PUSH SI
	PUSH DI
	PUSHF
		
	MOV AX, EMMDSEG
	MOV DS, AX              	; Set DS = Data Segment
	MOV SI, OFFSET EMMNAME		; Set DS:SI = EMM Device Driver Name
		
	MOV AX, 3567H           	; AH = 35H Get interrupt vector
	INT 21H                 	; AL = 67H Expanded Memory Manager
					; Returns ES:BX = Address of interrupt vector
								
	MOV DI, 0AH			; Device driver name starts at ES:000AH
	MOV CX, 08H     	        ; Compare up to 8 characters
	CLD                     	; Increment in forward direction
	REPZ CMPSB              	; Compare DS:SI to ES:DI
	JNZ @@CHECK0001         	; EMM is not present if names do not match
		
	XOR AL, AL              	; Set error code = 0, EMM driver present
	JMP @@CHECK0002

@@CHECK0001:
	MOV AL, 01H             	; Set error code = 1, EMM driver not present

@@CHECK0002:
	MOV DS:[EMMCODE], AL
	CALL EMM_EXIT           	; Set CF flag
		
	POPF				; Restore registers
	POP DI
	POP SI
	POP CX
	POP AX
	POP ES
	POP DS

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
		
	PUSH DS                 	; Save Registers
	PUSH AX
	PUSH BX
	PUSH DX
	PUSHF
		
	MOV AX, EMMDSEG
	MOV DS, AX              	; Set DS = Data Segment
		
	MOV AX, 3D00H           	; AH = 3DH Open file, AL = 00H Read mode only
	MOV DX, OFFSET EMMNAME  	; Set DS:DX to EMMNAME in data segment
	INT 21H
	JC @@TEST0003	           	; CF is set on error, EMM is not present
		
	MOV BX, AX              	; File handle in AX after DOS call to 3DH
	MOV AX, 4407H           	; IOCTL - Get Output Status
	INT 21H
	JC @@TEST0001			; Close handle on error
		
	CMP AL, 0FFH			; Check if device driver
	JNZ @@TEST0001
		
	XOR AL, AL			; Set return code to 0
	JMP @@TEST0002
		
@@TEST0001:
	MOV AL, 01H             	; Set return code to 1
		
@@TEST0002:
	MOV DS:[EMMCODE], AL
	MOV AH, 3EH             	; Close file handle
	INT 21H

	JC @@TEST0003			; Jump on error
	JMP @@TEST0004

@@TEST0003:
	MOV AL, 01H             	; Set return code = 1, no EMM present
	MOV DS:[EMMCODE], AL
		
@@TEST0004:

	CALL EMM_EXIT           	; Set CF Flag

	POPF				; Restore registers
	POP DX
	POP BX
	POP AX
	POP DS
		
	RET
		
EMM_TEST ENDP

;------ EMM_OK ------
;
; Tests if Expanded Memory Manager (if present) is working.

	PUBLIC EMM_OK

EMM_OK	PROC FAR
		
	PUSH DS				; Push DS
	PUSH AX				; Save AX
	PUSHF				; Save flags

	MOV AX, EMMDSEG			; Point DS to EMM Data
	MOV DS, AX
		
	MOV AH, 40H			; Get Expanded Memory Manager Status
	INT 67H

	MOV DS:[EMMCODE], AH		; Copy result code in AH
		
	CALL EMM_EXIT           	; Set CF Flag
	POPF

	POP AX				; Restore AX
	POP DS				; Restore DS
	RET

EMM_OK  ENDP

;------ EMM_INFO ------
;
; Returns:
;	On success (CF clear):
;	AX = Base Page Frame Segment
;	BX = Number of free/unallocated pages (each 16Kbytes)
;	DX = Total number of pages
;
;	On failure (CF set):
;	AX = BX = DX = 0000H

	PUBLIC EMM_INFO

EMM_INFO PROC FAR

	PUSH DS
	PUSHF

	MOV AX, EMMDSEG			; Point to EMMLIB DATA
	MOV DS, AX
		
	MOV AH, 41H			; Get Page Frame Segment
	INT 67H
		
	OR AH, AH
	JNZ @@ERROR
		
	MOV [EMMBASE], BX       	; Set EMM Page Frame Segment
		
	MOV AH, 42H             	; Get Page Counts
	INT 67H
		
	OR AH, AH
	JNZ @@ERROR
		
	MOV [EMMSIZE], DX		; Set total number of pages
	MOV [EMMFREE], BX		; Set total number of unallocated pages
		
	XOR AL, AL			; No error
	JMP @@EXIT1

@@ERROR:
	MOV AL, 01H
		
@@EXIT1:
	MOV DS:[EMMCODE], AL
	CALL EMM_EXIT           	; Set CF flag
	POPF
	JC @@EXIT2			; Exit on error

	MOV AX, [EMMBASE]
	MOV BX, [EMMFREE]
	MOV DX, [EMMSIZE]
	JMP @@EXIT3

@@EXIT2:
	PUSHF				; Adding PUSHF/POPF
	XOR AX, AX			; ... because XOR
	XOR BX, BX			; ... alters FLAGS
	XOR DX, DX
	POPF
		
@@EXIT3:
	POP DS				; Restore DS
		
	RET
		
EMM_INFO ENDP

;------ EMM_ALLOC -----
;
; Allocates pages and
; get handle.
;
; Inputs:
;	AX = Number of pages to allocate
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
		
	PUSH DS				; Save registers
	PUSH BX					
	PUSH DX
	PUSHF
		
	PUSH AX				; Point to EMM Data
	MOV AX, EMMDSEG
	MOV DS, AX
	POP AX
		
	CALL EMM_OK
	JC @@ERROR
		
	MOV BX, AX			; Allocate pages
	MOV AH, 43H
	INT 67H
		
	OR AH, AH
	JNZ @@ERROR
	
	XOR AL, AL
	JMP @@EXIT1

@@ERROR:
	MOV AL, 01H

@@EXIT1:
	MOV DS:[EMMCODE], AL
	CALL EMM_EXIT			; Set CF flag
	POPF
	JC @@EXIT3
		
	MOV AX, DX			; Copy Handle in DX
	JMP @@EXIT4

@@EXIT3:
	MOV AX, 0FFFFH
@@EXIT4:
	POP DX				; Restore registers
	POP BX
	POP DS
		
	RET

EMM_ALLOC ENDP

;------ EMM_FREE ------
;
; Frees allocated memory
;
; Inputs:
;	AX = Page handle to free
;
;	On success:
;	CF is clear
;
;	On failure:
;	CF is set

	PUBLIC EMM_FREE

EMM_FREE PROC FAR

	PUSH DS				; Save registers
	PUSH AX
	PUSH DX
	PUSHF
		
	PUSH AX				; Point to EMM Data
	MOV AX, EMMDSEG
	MOV DS, AX
	POP AX
		
	MOV DX, AX			; De-allocate handle
	MOV AH, 45H			; ... and memory
	INT 67H				; ... in DX
		
	OR AH, AH			; Check if de-allocation
	JNZ @@ERROR			; failed
		
	XOR AL, AL
	JMP @@EXIT

@@ERROR:
	MOV AL, 01H
		
@@EXIT:
	MOV DS:[EMMCODE], AL
	CALL EMM_EXIT			; Set CF flag

	POPF				; Restore registers
	POP DX
	POP AX
	POP DS
		
	RET

EMM_FREE ENDP

;------ EMM_MAP -------
;
; Maps logical page to
; Physical page (0-3)
;
; Inputs:
;	AL = Physical page 0-3
;	BX = Logical page (0FFFFH to unmap)
;	DX = Handle
;
;	On success:
;	CF is clear
;
;	On failure:
;	CF is set

	PUBLIC EMM_MAP

EMM_MAP	PROC FAR

	PUSH DS				; Save registers
	PUSH AX
	PUSH BX
	PUSH DX
	PUSHF
		
	PUSH AX				; Point to EMM Data
	MOV AX, EMMDSEG
	MOV DS, AX
	POP AX

	MOV AH, 44H			; Map/Unmap logical page
	INT 67H				; from physical page
		
	MOV DS:[EMMCODE], AH		; Set CF on error
	CALL EMM_EXIT
		
	POPF
	POP DX
	POP BX
	POP AX
	POP DS
		
	RETF

EMM_MAP ENDP

;------ EMM_EXIT ------
;
; Sets CF on success/error
;
; 1. Assumes that flags are immediately
;    next to the FAR return address (below)
; 2. Assumes [EMMCODE] contains the error code
; 3. Non-zero error code sets CF, is cleared otherwise
; 4. Updates FLAGS on stack (CF)

	PUBLIC EMM_EXIT

EMM_EXIT PROC FAR

FLG_OFF	EQU 0CH				; Offset in stack where FLAGS are stored
		
	PUSH DS				; Save registers
	PUSH AX
	PUSH BX
	PUSH BP
		
	MOV BP, SP			; Use BP to address values in stack
	MOV BX, [BP + FLG_OFF]		; Copy flags on the stack
	PUSH BX				; ... push a copy of the flags
					; ... in BX to STACK
		
	MOV AX, EMMDSEG
	MOV DS, AX
	MOV AL, DS:[EMMCODE]
		
	OR AL, AL			; Check error code
	JNZ @@EXIT01

	POPF                    	; Copy BX from stack to FLAGS
	CLC				; Clear CF because of success
		
	JMP @@EXIT02

@@EXIT01:
	POPF				; Copy BX from stack to FLAGS
	STC				; Set CF because of error

@@EXIT02:
	PUSHF				; Copy FLAGS into AX
	POP AX
		
	MOV [BP + FLG_OFF], AX		; Modify FLAGS in stack
		
	POP BP				; Restore registers
	POP BX
	POP AX
	POP DS
		
	RET

EMM_EXIT ENDP           		

EMMCSEG ENDS

	END
