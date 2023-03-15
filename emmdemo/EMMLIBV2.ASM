; Expanded Memory Library V2.0
;
; Library with "High-Level" calling interface
	LOCALS @@
		
	TITLE EMMLIBV2


EMMDSEG SEGMENT PARA PUBLIC 'DATA'
EMMNAME	DB "EMMXXXX0", 00H		; Expanded Memory Manager Driver Name
EMMCODE DB 00H				; Exit code
EMMDSEG ENDS

; Caller must now provide a destination array for these values

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

EMM_INIT ENDP