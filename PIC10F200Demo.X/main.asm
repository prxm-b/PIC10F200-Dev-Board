PROCESSOR 10F200
#include <xc.inc>

config WDTE = OFF, CP = OFF, MCLRE = OFF

; Force this psect to start at address 0
PSECT code,class=CODE,delta=2,abs
org 0x00

global start
start:
    MOVWF   OSCCAL      ; Apply calibration
    MOVLW   0           ; Digital I/O mode
    OPTION
    MOVLW   0xFE        ; GP0 as Output
    TRIS    GPIO

main_loop:
    MOVLW   0x01
    XORWF   GPIO, f     ; Toggle GP0
    
    ; Nested Delay Loops
    MOVLW   255
    MOVWF   0x10
d1:
    MOVLW   255
    MOVWF   0x11
d2:
    DECFSZ  0x11, f
    GOTO    d2
    DECFSZ  0x10, f
    GOTO    d1
    
    GOTO    main_loop

END start