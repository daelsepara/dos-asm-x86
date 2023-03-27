PAGE 60, 132

; CHECK FPU.ASM
; Determine the type of math coprocessor (FPU) installed

    .MODEL SMALL
    .STACK
    .DATA

SCRATCH DW  (?)                 ; Have the math chip store data here
SAYNONE DB  "No math coprocessor$"
SAY87   DB  "8087$"
SAY287  DB  "80287$"
SAY387  DB  "80387$"

    .CODE
    .STARTUP

CHECKFPU PROC
    
    FNINIT                      ; Intialize the FPU
    MOV     SCRATCH, 055AAH     ; The FPU will not write this
    FNSTSW  SCRATCH
    CMP     BYTE PTR SCRATCH, 0 ; Check LSB -- it should be a 0
    JNZ     NO_MATH             ; If not, return
    FNSTCW  SCRATCH             ; Now have the FPU write its control word
    MOV     AX, SCRATCH         ; Read the value
    AND     AX, 103FH           ; Mask expected bits
    CMP     AX, 003FH           ; This is what you should see
    JNZ     NO_MATH             ; If different, no math chip

; Now that you know that you have an FPU, which one is it?

    AND     SCRATCH, 0FF7FH     ; Clear interrupt bit
    FLDCW   SCRATCH             ; Load the control word
    FDISI                       ; Disable interrupts
    FSTCW   SCRATCH             ; Write the control word back
    TEST    SCRATCH, 0080H      ; Any effect on the word?
    JNZ     FOUND_8087          ; If so, it is an 8087

; The chip is not an 8087, so it is an 80287 or 80387

    FINIT                       ; Re-initialize the chip
    FLD1                        ; Push +1.0 onto the chip's stack
    FLDZ                        ; Push 0.0 onto the chip's stack
    FDIV                        ; Produce positive infinity
    FLD ST                      ; Produce negative inifinity
    FCOMPP                      ; Compare
    FSTSW   SCRATCH             ; Write the status word
    MOV     AX, SCRATCH
    SAHF                        ; Copy AH into the flags register
    JZ      FOUND_80287         ; If Z bit set (equal), the
                                ;   coprocessor found positive and
                                ;   negative infinity to be equal

; The chip is an 80387

    MOV     DX, OFFSET SAY387
    MOV     AL, 03H             ; Errorlevel 3
    JMP     SAYSO

           
NO_MATH:

    MOV     DX, OFFSET SAYNONE
    MOV     AL, 00H             ; Errorlevel 0
    JMP     SAYSO


FOUND_8087:

    MOV     DX, OFFSET SAY87
    MOV     AL, 01H             ; Errorlevel 1
    JMP     SAYSO


FOUND_80287:

    MOV     DX, OFFSET SAY287
    MOV     AL, 02H             ; Errorlevel 2

SAYSO:

    PUSH    AX                  ; Save Errorlevel
    MOV     AH, 09H             ; Call DOS write string function
    INT     21H
    POP     AX                  ; Retrieve Errorlevel
    MOV     AH, 4CH             ; Terminate program with return code
    INT     21H

CHECKFPU ENDP

    END
