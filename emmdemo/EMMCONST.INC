; Error Codes

EMM_NONE        EQU 0   ; No error
EMM_NOMEM       EQU	1	; Expanded memory not present
EMM_NODRV	    EQU 2   ; Driver not loaded
EMM_DRIVER      EQU 3   ; Driver error
EMM_NOTREADY    EQU 4   ; Driver not ready

; Offsets in user-provided array

EMMBASE         EQU 0   ; Expanded Memory Page Frame Segment
EMMSIZE         EQU 2   ; Total number of pages in system
EMMFREE         EQU 4   ; Number of unallocated pages
