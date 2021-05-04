
dot db ".", 0

memory_tester:
    pushaq

    mov rsi, 0x200000
    mov rdi, 1
    shl rdi, 7

    ;mov r11, qword[Count_of_Frames]
    ;imul r11, 0x1000

    ;sub r11, 0x200000           ;removing the initial 2MB

    ;mov r12, 0                      ; counter

    mov r11, 0x200000               ; increment value

    memory_access_loop:
        mov r8, rsi

        ; Read PML4
        shr r8, 39

        imul r8, 8              ; Get effective offset of PML4 entry address
        mov r9, PML4_ADDRESS
        add r9, r8              ; Address of PML4 entry
        mov r8, qword[r9]

        ;push rsi
        ;mov rsi, check_msg
        ;call video_print
        ;pop rsi

        ; Get PDP
        shr r8, 12               
        shl r8, 12               ; r8 is PDP base address (After zeroing the last 12 bits)

        mov r9, rsi             ; r9 is the virtual address
        shr r9, 30              
        and r9, 111111111b      ; r9 is the 9 bits corresponding to the PDP index
        imul r9, 8              ; r9 is effective offset of PDP entry address
        add r9, r8              ; r9 is the address of the PDP entry

        ; Get PD
        mov r8, qword[r9]       ; r8 has the value of the PDP entry
        shr r8, 12               
        shl r8, 12              ; r8 is PD base address (After zeroing the last 12 bits)

        mov r9, rsi             ; r9 is the virtual address
        shr r9, 21              
        and r9, 111111111b      ; r9 is the 9 bits corresponding to the PD index
        imul r9, 8              ; r9 is effective offset of PD entry address
        add r9, r8              ; r9 is the address of the PD entry

        ; Printing
        ;push rsi
        ;mov rsi, check_msg
        ;call video_print
        ;pop rsi


        ; Reading PD entry
        mov r8, qword[r9]       ; r8 has the value of the PD entry

        mov r10, PAGE_SIZE_BIT
        and r10, r8
        cmp r10, 0
        jne access_2MB_page

        mov r11, 0x1000

        shr r8, 12               
        shl r8, 12              ; r8 is PT base address (After zeroing the last 12 bits)

        mov r9, rsi             ; r9 is the virtual address
        shr r9, 12              
        and r9, 111111111b      ; r9 is the 9 bits corresponding to the PT index
        imul r9, 8              ; r9 is effective offset of PT entry address
        add r9, r8              ; r9 is the address of the PT entry

        ; Printing
        ;push rsi
        ;mov rsi, check_msg
        ;call video_print
        ;pop rsi

        ; Reading from 4K page
        mov r8, qword[r9]       ; r8 has the value of the PT entry
        shr r8, 12               
        shl r8, 12              ; r8 is address of physical fram (After zeroing the last 12 bits)

        mov r9, rsi             ; r9 is the virtual address           
        and r9, 111111111111b   ; r9 is the 12 bits corresponding to the offset

        or r8, r9               ; r8 has physical address

        

        jmp access

        ; Should address be 2MB aligned?
        access_2MB_page:
            shr r8, 21               
            shl r8, 21                      ; r8 is address of physical frame (After zeroing the last 12 bits)

            mov r9, rsi                     ; r9 is the virtual address           
            and r9, 111111111111111111111b  ; r9 is the 21 bits corresponding to the offset

            or r8, r9                       ; r8 has physical address
        
        
        access:
            cmp r8, qword[last_physical_address]
            jge iterate_test

            push rsi
            mov rsi, dot
            call video_print
            pop rsi

            mov al, byte[dot]
            mov byte[r8], al
            cmp byte[r8], al
            ;jne memory_error

        iterate_test:
        ;inc rsi
        add rsi, r11
        ;inc r12

        cmp rsi, qword[last_virtual_address]
        ;cmp r12, r11
        jl memory_access_loop

    
    popaq
ret

memory_error:
    mov rsi, error_msg
    call video_print
jmp hang