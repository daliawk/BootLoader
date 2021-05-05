

memory_tester:
    ; This function loops over all regions
    ; If a region is type 1, it starts to write in its bytes to check that it has been mapped
    pushaq

    mov rcx, qword[PTR_MEM_REGIONS_COUNT]   ; rcx: count of regions
    mov rbx, PTR_MEM_REGIONS_TABLE          ; rbx: address of the information about the current memory region
    mov rax, 0x1
    regions_loop:
        mov r8d, dword[rbx+16]              ; r8: region type
        cmp r8, 1
        jne next_region                     ; If the region is not type 1, then go to the next region

        mov r9, qword[rbx+8]                ; r9: region length
        ;shr r9, 12
        ;shl r9, 12                           ; we will check the 4K physical frames in the region
        
        
        mov r10, qword[rbx]                 ; r10: address if the current byte to be checked
        access_byte_loop:
            cmp r10, 0x200000               ; We will check bytes after the first 1 MB
            jl next_byte

            ; If the byte is not successfully mapped, the following will cause an exception
            ; Writing to the byte
            mov byte[r10], al

            ; Reading from byte
            mov dl, byte[r10]               

            next_byte:
            inc r10                         ; Moving pointer to the next byte
            dec r9
            cmp r9, 0                       ; Checking if we checked all bytes of the region
            jg access_byte_loop

        next_region:
            mov rsi, check_msg
            call video_print

            add rbx, 0x18                   ; Moving pointer to the next region's information
            dec rcx
            cmp rcx, 0                      ; Checking if all regions have been checked
            jg regions_loop


    popaq
ret

memory_error:
    mov rsi, error_msg
    call video_print
jmp hang
