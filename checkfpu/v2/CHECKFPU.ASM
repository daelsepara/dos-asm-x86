PAGE 60, 132

; CHECKFPU.ASM (v2.0)
;
; Determine the type of math coprocessor (FPU) installed
;
; Based on Borland TP7.0 Test8087 routine

    .MODEL SMALL
    .STACK 100H
    .DATA

SCRATCH DW  0000H ; Have the math chip store data here
SAYNONE DB  "No math coprocessor"
SAY87   DB  "8087"
SAY287  DB  "80287"
SAY387  DB  "80387"


    .CODE

CHECKFPU PROC NEAR

LABEL00:
    
    MOV AX, @DATA
    MOV DS, AX

    MOV BX, OFFSET SCRATCH

    XOR AX, AX

    PUSH SP
    POP	DX
    
    CMP	DX,SP
    JNZ LABEL01

    OUT 0F0H, AL

LABEL01:

    FINIT

    MOV	WORD PTR [BX], AX

    FSTCW	[BX]

    MOV	CX, 0014H

LABEL02:

    LOOP LABEL02
    
    MOV	AX, WORD PTR [BX]
    AND	AX, 0F3FH
    CMP	AX, 033FH
    MOV	AL, 00H
    JNZ NO_MATH

LABEL03:

    PUSH SP
    POP AX
    CMP AX, SP
    MOV AL, 01H
    JNZ FPU_87

LABEL04:
    
    FINIT
    FLD1
    FLDZ
    FDIVP
    FLD ST(0)
    FCHS
    FCOMPP
    FSTSW [BX]
    
    WAIT
    MOV	AX,[BX]
    SAHF

    MOV	AL, 02H
    JZ FPU_287

    MOV	AL, 03H

 FPU_387:

    MOV DX, OFFSET SAY387
    MOV CX, 05H
    JMP SAYSO

FPU_287:

    MOV DX, OFFSET SAY287
    MOV CX, 05H
    JMP SAYSO

FPU_87:

    MOV DX, OFFSET SAY87
    MOV CX, 04H
    JMP SAYSO

NO_MATH:

    MOV DX, OFFSET SAYNONE
    MOV CX, 0013H

SAYSO:
    
    PUSH AX

    MOV BX, 0001H
    MOV AH, 40H
    INT 21H
    
    POP AX

    MOV AH, 4CH
    INT 21H

CHECKFPU ENDP

    END CHECKFPU