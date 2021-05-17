;*******************************************************************************************************************
video_print_hexa:  
; A routine to print a 16-bit value stored in di in hexa decimal (4 hexa digits)
    pushaq
    mov rbx,0x0B8000                                ; set BX to the start of the video RAM
    add bx,[start_location]                         ; Store the start location for printing in BX
    mov rcx,0x10                                    ; Set loop counter for 4 iterations, one for eacg digit
    loopie:                                         ; Loop on all 4 digits
    cmp rbx, 0xB8FA0                                ; at the beginning of the loop, we check if we are in the last line or not
    jl no_scrolling                                 ; if not then we jump to no scrolling to print normally
    call scroll_down                                ; if so, then we call the scrolling function
    mov rbx, 0xB8F00                                ; after scrolling we then movethe cursor to the line before the last
    mov qword[start_location], 0xF00                 ; after that we move the starting location to 3840 which is the beginning of the line second to last
    
    no_scrolling:
            mov rsi,rdi                             ; Move current bx into si
            shr rsi,0x3C                            ; Shift SI 60 bits right 
            mov al,[hexa_digits+rsi]                ; get the right hexadcimal digit from the array           
            mov byte [rbx],al                       ; Else Store the charcater into current video location
            inc rbx                                 ; Increment current video location
            mov byte [rbx],7                        ; Store Blue Backgroun, Yellow font color
            inc rbx                                 ; Increment current video location
            shl rdi,0x4                             ; Shift bx 4 bits left so the next digits is in the right place to be processed
            dec rcx                                 ; decrement loop counter
            cmp rcx,0x0                             ; compare loop counter with zero.
            jg loopie                               ; Loop again we did not yet finish the 4 digits

    add [start_location],word 0x20
    call update_cursor
    popaq
    ret
;*******************************************************************************************************************


video_print:
; routine thattt prints the string passed to rsi
    pushaq
    mov rbx,0x0B8000                                ; set BX to the start of the video RAM
    add bx,[start_location]                         ; Store the start location for printing in BX
    xor rcx,rcx                                     ; resetting the character counter 
video_print_loop:           
; Loop for a character by charcater processing
    cmp rbx, 0xB8FA0                                ; checking if the cursor is in the last character
    jl no_scroll                                    ; if not in the last line print normally
    call scroll_down                                ; else if in the last one then we scroll down
    mov rbx, 0xB8F00                                ; after scrolling we set the cursor to the line before the last
    mov qword[start_location], 0xF00                 ; moving the index of the start location to 3840 which is the index the beginning of the line before the last
    xor rcx, rcx                                    ; resetting the character counter

    no_scroll:
        lodsb                                       ; Load character pointed to by SI into al
        cmp al,13                                   ; Check  new line character to stop printing
        je out_video_print_loop                     ; If so get out
        cmp al,0                                    ; Check  new line character to stop printing
        je out_video_print_loop1                    ; If so get out
        mov byte [rbx],al                           ; Else Store the charcater into current video location
        inc rbx                                     ; Increment current video location
        mov byte [rbx],7                            ; Store black background and grey foreground
        inc rbx                                     ; Increment current video location
        inc rcx                                     ; increment char counter
        inc rcx                                     ; increment char counter
        jmp video_print_loop                        ; Loop to print next character


scroll_down:
; this function clears the first line then moves all the line one line up
    pushaq                                          ; pushing all the general purpose registers to the stack
    mov r9, 0x0B8000                                ; setting the cursor to the beginning at register r9

    clear_loop1:
    ; Clearing the first line on the screen
        mov byte[r9],0                              ; we set the character at this cursor to a null character
        inc r9                                      ; we then increment to move to the next byte
        cmp r9, 0x0B80A0                            ; if not at the end of the first line we loop again
        jl clear_loop1                              

    xor r10, r10                                    ; setting r10 to zero to function as an index
 
    copy_loop:
    ; this subroutine copies all the lines one line up
        mov r12, 0xB8000                            ; set the first cursor to the beginning of the screen
        mov r13, 0xB80A0                            ; set the second cursor to the beginning of the second line
        add r12, r10                                ; we then add the index r10 to the first line
        add r13, r10                                ; and the second line
        inc r10                                     ; we then increment by one byte
        mov al, byte[r13]                           ; we move the character in the second cursor to a temp register al
        mov byte[r12], al                           ; and then move it back to the first cursor
        cmp r13, 0xB8FA0                            ; if we reach the end of the screen we stop
        jl  copy_loop                               ; else we loop again

    mov r9, 0x0B8F00                                ; we then set the cursor again to the beginning of last line
    clear_loop2:
    ; this subroutine clears the last line
        mov byte[r9],0                              ; we move a null character to the position of the cursor
        inc r9                                      ; then we move to the next byte
        cmp r9, 0x0B8FA0                            ; if at the end of the screen we stop
        jl clear_loop2                              ; else we loop back
popaq                                               ; popping back all the general purpose registers of the stack
ret


out_video_print_loop:
; this subroutine only executes if a new line is being printed
    xor rax,rax                                     ; we set rax to zero
    mov ax,[start_location]                         ; Store the start location for printing in AX
    mov r8,160                                      ; we then move 160 which is the size of the whole line
    xor rdx,rdx                                     ; we set the rdx register to zero
    add ax,0xA0                                     ; Add a line to the value of start location (80 x 2 bytes)
    div r8                                          ; we then divide the satarting index plus a full line by 160 to get the beginning of the next line
    xor rdx,rdx                                     ; then we reset the rdx back to zero
    mul r8                                          ; we then multiply by 160 to get the beginning of the next new line
    mov [start_location],ax                         ; we then set this location as the new start location
    jmp finish_video_print_loop                     ; finally we finish the loop by popaq
out_video_print_loop1:
; this subroutine only executes at the end of a string being printed
    mov ax,[start_location]                         ; Store the start location for printing in AX
    add ax,cx                                       ; Add a line to the value of start location (80 x 2 bytes)
    mov [start_location],ax                         ; we set the new location of the start location
finish_video_print_loop:
; this label executes at the very end of a printing function
    call update_cursor
    popaq                                           ; finally we pop back all the general purpose registers
ret

cls:
; this function clears the screen
    pushaq                                          ; we push all the general purpose registers to the stack
    mov rbx, 0x0B8000                               ; we set the cursor to the beginning of the page
    clear_loop:
    ; this loop puts a null character in all the characters in the screen
        mov byte[rbx],0                             ; putting a null character to the cursor location
        inc rbx                                     ; move to the next byte
        cmp rbx, 0x0B8FA0                           ; if at the end of screen we return
        jl  clear_loop                              ; else we loop back again

mov word[start_location], 0                         ; since we have cleared the screen we move the cursor to the beginning of the screen
popaq                                               ; finally we push all the general purpose registers to the cursor location
ret

update_cursor:
    pushaq
    mov bx,[start_location]                         ; Store the start location for printing in BX
    
    ; Calculating the row and column indices
    xor rdx, rdx
    mov ax, bx
    mov cx, 160
    div cx
   
   ; Calculating the offset
    shr dx, 1       ; Divide by 2
    imul ax, 80
    add ax, dx
    mov bx, ax

    ; Check if we are out of range
    cmp bx, 2000
    jl set_cursor

    mov bx, 1920        ; Set the cursor to the last row


    set_cursor:
	mov dx, 0x03D4
	mov al, 0x0F
	out dx, al
 
	inc dl
	mov al, bl
	out dx, al
 
	dec dl
	mov al, 0x0E
	out dx, al
 
	inc dl
	mov al, bh
	out dx, al

    popaq
ret
