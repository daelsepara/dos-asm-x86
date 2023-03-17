;-------------------------------------------------------------------------------------------------------------------
; Hello, Windows!  in x86 ASM - (c) 2021 Dave's Garage - Use at your own risk, no warranty!
;-------------------------------------------------------------------------------------------------------------------
 
; Compiler directives and includes
 
.386                                ; Full 80386 instruction set and mode
.model flat, stdcall                ; All 32-bit and later apps are flat. Used to include "tiny, etc"
option casemap:none                 ; Preserve the case of system identifiers but not our own, more or less
 
; Include files - headers and libs that we need for calling the system dlls like user32, gdi32, kernel32, etc
include \masm32\include\windows.inc ; Main windows header file (akin to Windows.h in C)
include \masm32\include\user32.inc  ; Windows, controls, etc
include \masm32\include\kernel32.inc    ; Handles, modules, paths, etc
include \masm32\include\gdi32.inc   ; Drawing into a device context (ie: painting) 

; Libs - information needed to link your binary to the system DLL callss
 
includelib \masm32\lib\kernel32.lib ; Kernel32.dll
includelib \masm32\lib\user32.lib   ; User32.dll
includelib \masm32\lib\gdi32.lib    ; GDI32.dll
 
; Forward declarations - Our main entry point will CALL forward to WinMain, so we need to define it here
 
WinMain proto :DWORD, :DWORD, :DWORD, :DWORD    ; Forward decl for MainEntry 
 
; Constants and Datra
 
WindowWidth     equ 640             ; How big we'd like our main window
WindowHeight    equ 480
 
.DATA
 
ClassName   db "MyWinClass", 0      ; The name of our Window class
AppName     db "Dave's Tiny App", 0 ; The name of our main window
 
.DATA?                              ; Uninitialized data - Basically just reserves address space
 
hInstance   HINSTANCE ?             ; Instance handle (like the process id) of our application
CommandLine LPSTR     ?             ; Pointer to the command line text we were launched with
 
;-------------------------------------------------------------------------------------------------------------------
.CODE                               ; Here is where the program itself lives
;-------------------------------------------------------------------------------------------------------------------
 
MainEntry PROC
 
    LOCAL sui:STARTUPINFOA          ; Reserve stack space so we can load and inspect the STARTUPINFO
 
    PUSH NULL                       ; Get the instance handle of our app (NULL means ourselves)
    CALL GetModuleHandle            ; GetModuleHandle will return instance handle in EAX
    MOV hInstance, EAX              ; Cache it in our global variable
 
    CALL GetCommandLineA            ; Get the command line text ptr in EAX to pass on to main
    MOV CommandLine, EAX
 
    ; Call our WinMain and then exit the process with whatever comes back from it
 
    ; Please check this, I have only typed it, not tested it :-)
 
    LEA EAX, sui                    ; Get the STARTUPINFO for this process
    PUSH EAX
    CALL GetStartupInfoA            ; Find out if wShowWindow should be used
    TEST sui.dwFlags, STARTF_USESHOWWINDOW   
    JZ  @1
    PUSH sui.wShowWindow            ; If the show window flag bit was nonzero, we use wShowWindow
    JMP @2
@1:
    PUSH SW_SHOWDEFAULT             ; Use the default 
@2: 
    PUSH CommandLine
    PUSH NULL
    PUSH hInstance
    CALL WinMain
 
    PUSH EAX
    CALL ExitProcess
 
MainEntry ENDP
 
; 
; WinMain - The traditional signature for the main entry point of a Windows programa
;
 
WinMain PROC hInst:HINSTANCE, hPrevInst:HINSTANCE, CmdLine:LPSTR, CmdShow:DWORD
 
    LOCAL wc:WNDCLASSEX             ; Create these vars on the stack, hence LOCAL
    LOCAL msg:MSG
    LOCAL hwnd:HWND
 
    MOV wc.cbSize, SIZEOF WNDCLASSEX        ; Fill in the values in the members of our windowclass
    MOV wc.style, CS_HREDRAW or CS_VREDRAW  ; Redraw if resized in either dimension
    MOV wc.lpfnWndProc, OFFSET WndProc      ; Our callback function to handle window messages
    MOV wc.cbClsExtra, 0            ; No extra class data
    MOV wc.cbWndExtra, 0            ; No exttra window data
    MOV EAX, hInstance
    MOV wc.hInstance, EAX           ; Our instance handle
    MOV wc.hbrBackground, COLOR_3DSHADOW+1  ; Default brush colors are color plus one
    MOV wc.lpszMenuName, NULL       ; No app menu
    MOV wc.lpszClassName, OFFSET ClassName  ; The window's class name
 
    PUSH IDI_APPLICATION            ; Use the default application icon
    PUSH NULL    
    CALL LoadIcon
    MOV wc.hIcon, EAX
    MOV wc.hIconSm, EAX
 
    PUSH IDC_ARROW                  ; Get the default "arrow" mouse cursor
    PUSH NULL
    CALL LoadCursor
    MOV wc.hCursor, EAX
 
    LEA EAX, wc
    PUSH EAX
    CALL RegisterClassEx            ; Register the window class 
 
    PUSH NULL                       ; Bonus data, but we have none, so null
    PUSH hInstance                  ; Our app instance handle
    PUSH NULL                       ; Menu handle
    PUSH NULL                       ; Parent window (if we were a child window)
    PUSH WindowHeight               ; Our requested height
    PUSH WindowWidth                ; Our requested width
    PUSH CW_USEDEFAULT              ; Y
    PUSH CW_USEDEFAULT              ; X
    PUSH WS_OVERLAPPEDWINDOW + WS_VISIBLE   ; Window stytle (normal and visible)
    PUSH OFFSET AppName             ; The window title (our application name)
    PUSH OFFSET ClassName           ; The window class name of what we're creating
    PUSH 0                          ; Extended style bits, if any
    CALL CreateWindowExA
    CMP EAX, NULL
    JE WinMainRet                   ; Fail and bail on NULL handle returned
    MOV hwnd, EAX                   ; Window handle is the result, returned in EAX
 
    PUSH EAX                        ; Force a paint of our window
    CALL UpdateWindow
 
MessageLoop:
 
    PUSH 0
    PUSH 0
    PUSH NULL
    LEA EAX, msg
    PUSH EAX
    CALL GetMessage                 ; Get a message from the application's message queue
 
    CMP EAX, 0                      ; When GetMessage returns 0, it's time to exit
    JE DoneMessages
 
    LEA EAX, msg                    ; Translate 'msg'
    PUSH EAX
    CALL TranslateMessage
 
    LEA EAX, msg                    ; Dispatch 'msg'
    PUSH EAX
    CALL DispatchMessage
 
    JMP MessageLoop
 
DoneMessages:
    
    MOV EAX, msg.wParam             ; Return wParam of last message processed
 
WinMainRet:
    
    RET
 
WinMain ENDP
 
;
; WndProc - Our Main Window Procedure, handles painting and exiting
;
 
WndProc PROC hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
 
    LOCAL ps:PAINTSTRUCT            ; Local stack variables
    LOCAL rect:RECT
    LOCAL hdc:HDC
 
    CMP uMsg, WM_DESTROY
    JNE NotWMDestroy
 
    PUSH 0                          ; WM_DESTROY received, post our quit msg
    CALL PostQuitMessage            ; Quit our application
    XOR EAX, EAX                    ; Return 0 to indicate we handled it
    RET
 
NotWMDestroy:
 
    CMP uMsg, WM_PAINT
    JNE NotWMPaint
 
    LEA EAX, ps                     ; WM_PAINT received
    PUSH EAX
    PUSH hWnd
    CALL BeginPaint                 ; Go get a device context to paint into
    MOV hdc, EAX
 
    PUSH TRANSPARENT
    PUSH hdc
    CALL SetBkMode                  ; Make text have a transparent background
 
    LEA EAX, rect                   ; Figure out how big the client area is so that we
    PUSH EAX                        ;   can center our content over it
    PUSH hWnd
    CALL GetClientRect
 
    PUSH DT_SINGLELINE + DT_CENTER + DT_VCENTER
    LEA EAX, rect
    PUSH EAX
    PUSH -1
    PUSH OFFSET AppName
    PUSH hdc
    CALL DrawText                   ; Draw text centered vertically and horizontally
 
    LEA EAX, ps
    PUSH EAX
    PUSH hWnd
    CALL EndPaint                   ; Wrap up painting
 
    XOR EAX, EAX                    ; Return 0 as no further processing needed
    RET
 
NotWMPaint:
    
    PUSH lParam
    PUSH wParam
    PUSH uMsg
    PUSH hWnd
    CALL DefWindowProc              ; Forward message on to default processing and
    RET                             ;   return whatever it does
 
WndProc ENDP
 
END MainEntry                       ; Specify entry point, else _WinMainCRTStartup is assumed