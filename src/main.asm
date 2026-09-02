; Z80 Calculator Program
; Brandon Mitchell
; rasm_w64.exe -ob out.bin main.asm
; http://rasm.wikidot.com/

; I/O addresses, 7 segement is output only, buttons and switches are input only
CS_7SEG_1       equ 0x00
CS_7SEG_2       equ 0x01
CS_7SEG_3       equ 0x02
CS_7SEG_4       equ 0x03
CS_BTN          equ 0x04
CS_SW_X         equ 0x05
CS_SW_Y         equ 0x06

; Used for checking which button was pressed, each button is tied to one data line
BIT_ADD         equ 7
BIT_SUB         equ 6
BIT_MUL         equ 5
BIT_DIV         equ 4
BIT_GCD         equ 3
BIT_SQRT        equ 2

; 7 6 5 4 3 2 1 0
; A B C D E F G DP
VAL_0           equ 0b11111100
VAL_1           equ 0b01100000
VAL_2           equ 0b11011010
VAL_3           equ 0b11110010
VAL_4           equ 0b01100110
VAL_5           equ 0b10110110
VAL_6           equ 0b10111110
VAL_7           equ 0b11100000
VAL_8           equ 0b11111110
VAL_9           equ 0b11110110
VAL_A           equ 0b11101110
VAL_B           equ 0b00111110
VAL_C           equ 0b10011100
VAL_D           equ 0b01111010
VAL_E           equ 0b10011110
VAL_F           equ 0b10001110

VAL_HYPHEN      equ 0b00000010

; Blank and r are used to display " Err", used when dividing by 0
VAL_BLANK       equ 0b00000000
VAL_r           equ 0b00001010

; Location of the display_ans values in ROM
VAL_START       equ 0x0200
SQRT_START      equ 0x0210

; 0000 - 1FFF is ROM, 2000 - 3FFF is RAM
RAM_START       equ 0x2000

; Memory locations of a view variables, used in display routine
NEG_RES         equ 0x2000
ANS_LOW         equ 0x2001
ANS_HIGH        equ 0x2002
DISP_SEG_1      equ 0x2003
DISP_SEG_2      equ 0x2004
DISP_SEG_3      equ 0x2005
DISP_SEG_4      equ 0x2006

; We want to store these values in ROM for use as a look up table
org             VAL_START
defb            VAL_0, VAL_1, VAL_2, VAL_3, VAL_4, VAL_5, VAL_6, VAL_7, VAL_8, VAL_9, VAL_A, VAL_B, VAL_C, VAL_D, VAL_E, VAL_F

; I didn't want to implement an actual square root, so store squares from 0 to 15
; We can then just consult this table to find which is closest to the input
org             SQRT_START
defb            0, 1, 4, 9, 16, 25, 36, 49, 64, 81, 100, 121, 144, 169, 196, 225

; Reset address to beginning of address space
org             0x0000



startup:
    ld          a, 0x00                 ; Clear neg bit
    ld          (NEG_RES), a

    ld          a, VAL_0                ; Screen should display all zeroes on start up
    ld          (DISP_SEG_1), a
    ld          (DISP_SEG_2), a
    ld          (DISP_SEG_3), a
    ld          (DISP_SEG_4), a



mainloop:
    in          a, (CS_BTN)             ; Read the buttons

    bit         BIT_ADD, a              ; Check which button was pressed
    jp          nz, addition

    bit         BIT_SUB, a
    jp          nz, subtraction

    bit         BIT_MUL, a
    jp          nz, multiplication

    bit         BIT_DIV, a
    jp          nz, divide

    bit         BIT_GCD, a
    jp          nz, gcd

    bit         BIT_SQRT, a
    jp          nz, square_root

    jp          display_ans             ; Display the answer



addition:
    ld          a, 0x00                 ; Clear neg bit
    ld          (NEG_RES), a

    in          a, (CS_SW_Y)            ; Read Y switch into A
    ld          h, 0x00                 ; Clear out H register (upper half of HL)
    ld          l, a                    ; L = A

    in          a, (CS_SW_X)            ; Read X switch into A
    ld          b, 0x00                 ; Clear out B register (upper half of BC)
    ld          c, a                    ; C = A

    add         hl, bc                  ; Needed to clear upper bytes as we are doing a 16 bit add

    ld          (ANS_LOW), hl           ; Store in RAM for later use

    jp          format_ans              ; Format the answer for later display



subtraction:
    ld          a, 0x00                 ; Clear neg bit
    ld          (NEG_RES), a

    in          a, (CS_SW_X)            ; Read X switch into A
    ld          c, a                    ; Move A value to C

    in          a, (CS_SW_Y)            ; Read Y switch into A

    cp          c                       ; Compare A and C
    jp          nc, subtraction_pos     ; If carry flag is not set, then A >= C, skip negative handling code

    ld          b, c                    ; Swap A with C before doing subtraction as A < C
    ld          c, a

    ld          a, 0x01                 ; Set neg bit
    ld          (NEG_RES), a

    ld          a, b                    ; Save C's value to A

subtraction_pos:
    sub         c                       ; A = A - C

    ld          (ANS_LOW), a            ; Save result for later
    ld          a, 0x00
    ld          (ANS_HIGH), a           ; The upper 8 bytes will always be 00 as the difference between two 8 bit
                                        ; values will always be an 8 bit value
    jp          format_ans              ; Format the answer for later display



multiplication:
    ld          a, 0x00                 ; Clear neg bit
    ld          (NEG_RES), a

    ld          l, a                    ; Clear out HL, will be used for adding
    ld          h, a

    in          a, (CS_SW_Y)            ; Read Y switch into A
    ld          b, 0x00                 ; Clear out B register (upper half of BC)
    ld          c, a                    ; C = A

    in          a, (CS_SW_X)            ; Read X switch into A

    cp          c                       ; Compare A and C
    jp          c, multiplication_loop  ; If carry flag is set, then A < C, go to loop

    ld          e, a                    ; Else, swap the values so the multiplication is faster
    ld          a, c
    ld          c, e

multiplication_loop:
    and         a                       ; Check if a is zero and exit loop if so
    jp          z, multiplication_end

    add         hl, bc                  ; Else, perform the add
    dec         a                       ; A is our loop counter, decrement it
    jp          multiplication_loop

multiplication_end:
    ld          (ANS_LOW), hl           ; Store in RAM for later use

    jp          format_ans              ; Format the answer for later display



divide:
    ld          a, 0x00                 ; Clear neg bit
    ld          (NEG_RES), a

    in          a, (CS_SW_X)            ; Read X switch into A

    and         a                       ; If it is zero, display an error
    jp          z, format_err           ; Can't divide by zero

    ld          c, a                    ; Move A value to C

    in          a, (CS_SW_Y)            ; Read Y switch into A

    ld          e, 0x00                 ; Used to store our answer

divide_loop:
    cp          c,                      ; A < C, stop division
    jp          c, divide_end

    sub         c                       ; A = A - C
    inc         e                       ; Increment our answer

    jp          divide_loop

divide_end:
    ld          a, e                    ; Load answer into A register
    ld          (ANS_LOW), a            ; Save result in RAM for later
    ld          a, 0x00                 ; The upper byte will always be 00
    ld          (ANS_HIGH), a

    jp          format_ans              ; Format the answer for later display



gcd:                                    ; Euclid's algorithm using subtraction
    ld          a, 0x00                 ; Clear neg bit
    ld          (NEG_RES), a

    in          a, (CS_SW_X)            ; Read X switch into A
    ld          c, a                    ; Move A value to C

    in          a, (CS_SW_Y)            ; Read Y switch into A
    ld          e, a                    ; Move A value to E

    and         a                       ; Test if E is zero
    jp          z, gcd_end              ; If so, skip to end, C is the answer

    ld          a, c                    ; Check if C is zero
    and         a
    jp          z, gcd_e_end            ; Skip to end and load E as answer

gcd_loop:
    ld          a, c                    ; Load C into A ...
    cp          e                       ; ... so we can compare it to E

    jp          z, gcd_end              ; C == E, we have our answer

    jp          nc, gcd_greater_than    ; C >= E

    ld          a, e                    ; Load E into A so we can perform the subtraction
    sub         c                       ; A = A - C
    ld          e, a                    ; E = A

    jp          gcd_loop

gcd_greater_than:
    ld          a, c                    ; Load E into A so we can perform the subtraction
    sub         e                       ; A = A - E
    ld          c, a                    ; C = A

    jp          gcd_loop

gcd_e_end:
    ld          c, e

gcd_end:
    ld          a, c                    ; Load answer into A register
    ld          (ANS_LOW), a            ; Save result for later
    ld          a, 0x00                 ; The upper byte will always be 00
    ld          (ANS_HIGH), a

    jp          format_ans              ; Format the answer for later display



square_root:
    ld          a, 0x00                 ; Clear neg bit
    ld          (NEG_RES), a

    in          a, (CS_SW_X)            ; Read X switch into A

    ld          b, 0x00                 ; Clear out B, upper half of BC
    ld          c, 15                   ; Highest possible int

square_root_loop:
    ld          hl, SQRT_START          ; Load in our ROM start value
    add         hl, bc                  ; Add to it our offset

    cp          (HL)                    ; Perform the comparision
    jp          nc, square_root_end     ; A >= (HL), we have our answer

    dec         c                       ; Decrement our offset and try again

    jp          square_root_loop

square_root_end:
    ld          a, c                    ; Load answer into A register
    ld          (ANS_LOW), a            ; Save result in RAM for later
    ld          a, 0x00                 ; The upper byte will always be 00    
    ld          (ANS_HIGH), a

    jp          format_ans              ; Format the answer for later display



format_err:
    ld          a, VAL_BLANK            ; Display " Err" for divide by 0
    ld          (DISP_SEG_1), a         ; Load appropriate values into RAM

    ld          a, VAL_E
    ld          (DISP_SEG_2), a

    ld          a, VAL_r
    ld          (DISP_SEG_3), a
    ld          (DISP_SEG_4), a

    jp          display_ans             ; Display the answer



format_ans:
    ld          b, 0x00                 ; B is used in getting the RAM offset, need to clear it

    ld          a, (ANS_LOW)            ; Load in the lower half of the answer
    and         0x0F                    ; We want the lower nibble for use as an offset

    ld          hl, VAL_START           ; Load in our ROM address
    ld          c, a                    ; and move the offset to C
    add         hl, bc                  ; and add to get the ROM address

    ld          a, (hl)                 ; Load the correct value
    ld          (DISP_SEG_4), a         ; and save it for later display

    ld          a, (ANS_LOW)            ; Perform same steps with upper nibble
    rrca        4                       ; Rotate right four times to isolate upper nibble
    and         0x0F

    ld          hl, VAL_START
    ld          c, a
    add         hl, bc

    ld          a, (hl)
    ld          (DISP_SEG_3), a

    out         (CS_7SEG_3), a

    ld          a, (ANS_HIGH)
    and         0x0F

    ld          hl, VAL_START
    ld          c, a
    add         hl, bc

    ld          a, (hl)
    ld          (DISP_SEG_2), a

    ld          a, (NEG_RES)            ; Check if neg bit is set
    and         a

    jp          nz, format_ans_neg      ; Skip logic for finding hex value, just show hyphen if negative

    ld          a, (ANS_HIGH)           ; Otherwise, perform same lookup logic
    rrca        4
    and         0x0F

    ld          hl, VAL_START
    ld          c, a
    add         hl, bc

    ld          a, (hl)
    ld          (DISP_SEG_1), a

    jp          display_ans

format_ans_neg:

    ld          a, VAL_HYPHEN           ; Load a hyphen into the first digit
    ld          (DISP_SEG_1), a

    jp          display_ans



display_ans:
    ld          a, (DISP_SEG_1)         ; Load first character and display it
    out         (CS_7SEG_1), a

    ld          a, (DISP_SEG_2)
    out         (CS_7SEG_2), a

    ld          a, (DISP_SEG_3)
    out         (CS_7SEG_3), a

    ld          a, (DISP_SEG_4)
    out         (CS_7SEG_4), a

    jp          mainloop