;*******************************************************************************************************************
video_print_hexa:  ; A routine to print a 16-bit value stored in di in hexa decimal (4 hexa digits)
pushaq
mov rbx,0x0B8000          ; set BX to the start of the video RAM
;mov es,bx               ; Set ES to the start of teh video RAM
    add bx,[start_location] ; Store the start location for printing in BX
    mov rcx,0x10                                ; Set loop counter for 4 iterations, one for eacg digit
    ;mov rbx,rdi                                 ; DI has the value to be printed and we move it to bx so we do not change ot
    .loop:                                    ; Loop on all 4 digits
            mov rsi,rdi                           ; Move current bx into si
            shr rsi,0x3C                          ; Shift SI 60 bits right 
            mov al,[hexa_digits+rsi]             ; get the right hexadcimal digit from the array           
            mov byte [rbx],al     ; Else Store the charcater into current video location
            inc rbx                ; Increment current video location
            mov byte [rbx],1Fh    ; Store Blue Backgroun, Yellow font color
            inc rbx                ; Increment current video location

            shl rdi,0x4                          ; Shift bx 4 bits left so the next digits is in the right place to be processed
            dec rcx                              ; decrement loop counter
            cmp rcx,0x0                          ; compare loop counter with zero.
            jg .loop                            ; Loop again we did not yet finish the 4 digits
    add [start_location],word 0x20
    popaq
    ret
;*******************************************************************************************************************


video_print:
    pushaq
    mov rbx,0x0B8000          ; set BX to the start of the video RAM
    ;mov es,bx               ; Set ES to the start of teh video RAM
    add bx,[start_location] ; Store the start location for printing in BX
    xor rcx,rcx
video_print_loop:           ; Loop for a character by charcater processing
    lodsb                   ; Load character pointed to by SI into al
    cmp al,13               ; Check  new line character to stop printing
    je out_video_print_loop ; If so get out
    cmp al,0                ; Check  new line character to stop printing
    je out_video_print_loop1 ; If so get out
    mov byte [rbx],al     ; Else Store the charcater into current video location
    inc rbx                ; Increment current video location
    mov byte [rbx],1Fh    ; Store Blue Backgroun, Yellow font color
    inc rbx                ; Increment current video location
                            ; Each position on the screen is represented by 2 bytes
                            ; The first byte stores the ascii code of the character
                            ; and the second one stores the color attributes
                            ; Foreground and background colors (16 colors) stores in the
                            ; lower and higher 4-bits
    inc rcx
    inc rcx
    jmp video_print_loop    ; Loop to print next character

scroll_down:
pushaq
mov r9, 0x0B8000
    clear_loop1:
        mov byte[r9],0
        inc r9
        cmp r9, 0x0B80A0
        jl clear_loop1
; up to B8F50

    mov r10, 0
    mov r11, 0
    copy_loop:
        mov r12, 0xB8000
        mov r13, 0xB80A0
        add r12, r10
        add r13, r10
        inc r10
        ;sinc r10
        mov r14b, byte[r13]
        mov byte[r12], r14b
        cmp r13, 0xB8FA0
        jl  copy_loop

    
    mov r9, 0x0B8F00
    clear_loop2:
        mov byte[r9],0
        inc r9
        cmp r9, 0x0B8FA0
        jl clear_loop2
popaq
ret




out_video_print_loop:
    
    cmp word[start_location], 0x0F00
    jl no_scroll
    call scroll_down
    ;mov rbx, 0x0B8F00
    mov word[start_location], 0xF00
    jmp finish_video_print_loop
        no_scroll:
            xor rax,rax
            mov ax,[start_location] ; Store the start location for printing in AX
            mov r8,160
            xor rdx,rdx
            add ax,0xA0             ; Add a line to the value of start location (80 x 2 bytes)
            div r8
            xor rdx,rdx
            mul r8
            mov [start_location],ax
            jmp finish_video_print_loop
out_video_print_loop1:
    mov ax,[start_location] ; Store the start location for printing in AX
    add ax,cx             ; Add a line to the value of start location (80 x 2 bytes)
    mov [start_location],ax
finish_video_print_loop:
    popaq
ret

cls:
    pushaq
    mov rbx, 0x0B8000
    ;we need to clear 4000 bytes ====> 80x2x25
    clear_loop:
        mov byte[rbx],0
        inc rbx
        cmp rbx, 0x0B8FA0
        jl  clear_loop

mov word[start_location], 0
popaq
ret