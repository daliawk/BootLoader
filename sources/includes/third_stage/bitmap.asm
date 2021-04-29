%define PTR_MEM_REGIONS_COUNT       0x21000
%define PTR_MEM_REGIONS_TABLE       0x21018
%define MEM_PAGE_4K                 0x1000


Bitmap_address dq 0
Bitmap_end_address dq 0
Count_of_2MB dq 0
Count_of_4KB dq 0
last_address dq 0
PML4_address dq 0

mark_bit:
    ;Parameter (index) is passed in register rsi
    pushaq

    mov rax, rsi                ;rax= index
    and rax, 31                 ;rax= index % 32

    mov r9d, 1                  ;r9d=1

    mov cl,al                   ;cl= index % 32
    shl r9d, cl                 ;r9d = 1<< (index % 32)

    ;mov r10, BIT_MAP

    mov r8, rsi                 ;r8=index
    shr r8, 5                   ;r8=index/32
    shl r8, 2                   ;index offset of the array
    add r10, r8                 ;Address of word at index

    or DWORD[r10], r9d

    popaq
    ret

check_bit:
    ;Parameter (index) is passed in register rsi
    ;
    pushaq

    mov rax, rsi                ;rax= index
    and rax, 31                 ;rax= index % 32

    mov r9d, 1                  ;r9d=1

    mov cl,al                   ;cl= index % 32
    shl r9d, cl                 ;r9d = 1<< (index % 32)

    ;mov r10, BIT_MAP

    mov r8, rsi                 ;r8=index
    shr r8, 5                   ;r8=index/32
    shl r8, 2                   ;index offset of the array
    add r10, r8                 ;Address of word at index

    and r9d, DWORD[r10]
    mov rsi, r9

    ;Still figure out how to return

    popaq
    ret

create_bitmap:
    pushaq
    
    ; Calculating bitmap address
    mov ax, word[PTR_MEM_REGIONS_COUNT]        ; Moving to rax count of regions
    imul rax, 0x18                              ; rax = 24 bytes * count of regions                             
    mov r9, PTR_MEM_REGIONS_TABLE               ; r9 = address of memory regions info
    add r9, rax                                 ; r9 = address of memory regions info + (24 bytes * count of regions)
    add r9, 4                                   
    mov qword[Bitmap_address], r9                ; address of bit map 1 word after memory regions info

    
    mov r8, 0       ;index
    mov rdi, PTR_MEM_REGIONS_TABLE
    mov r9, 0       ; Remainder of dividing by 2MB
    mov r10, 512

    mem_regions_loop:
        mov ecx, dword[rdi+16]      ; rcx: region type
        mov rax, qword[rdi+8]       ; rax: region length
        xor rdx, rdx
        mov r9, MEM_PAGE_4K
        idiv r9                     ; Divide length by 4K
                                    ; rax has count of 4K in this region
        cmp rcx, 1
        jne check_4k_bits_loop      ; If the region type is not 1, set the bits in the bit map

        mov r9, rax
        make_zero_loop:
            mov rsi, r8
            ;call mark_bit
            mov byte[Bitmap_address + r8], 0
            inc r8
            dec r9
            cmp r9, 0
            jne make_zero_loop
            
        ;add r8, rax                 ; Updating to the last index
        xor rdx, rdx
        idiv r10                    ; Check how many 2MB in this region
        add qword[Count_of_2MB], rax ; Inrementing number of available 2MB pages
        add r9, rdx                 ; Updating cumalitive remaining 4KB pages since last unusable memory
        mov rax, r9
        xor rdx, rdx
        idiv r10                    ; Check how many 2MB in the remaining 4KB pages
        add qword[Count_of_2MB], rax  ; Inrementing number of available 2MB pages with the quotient
        mov r9, rdx                 ; Seting the remaining pages with the remainder
        jmp increment

        check_4k_bits_loop:
            mov rsi, r8
            ;call mark_bit
            mov byte[Bitmap_address + r8], 1
            inc r8
            dec rax
            cmp rax, 0
            jne check_4k_bits_loop
            
            add qword[Count_of_4KB], r9  ; The previous available 4KB pages will be mapped with 4KB since they cannot be formed as consecutive 2MB
            mov r9, 0   ; Zero the remainder since there is an unusable region after it
        
        increment:
            dec rbx
            add rdi, 0x18
            cmp rbx, 0
            jne mem_regions_loop

    add qword[Count_of_4KB], r9  ; The previous available 4KB pages will be mapped with 4KB since they cannot be formed as consecutive 2MB
    add r8, Bitmap_address
    mov qword[Bitmap_end_address], r8
    
    ;Ensuring that the new address is word aligned
    mov rax, r8
    mov r9, 8
    xor rdx, rdx
    idiv r9                     ; Dividing the last available address by 8
    sub r9, rdx                 ; Subtracting the previous remainder from 8... For example, if remainder is 3 then we need to add 5 to address to ensure that it is aligned
    add r8, r9

    mov qword[last_address], r8
    mov qword[PML4_address], r8

    popaq
    ret

Mapping_Memory:
    pushaq

    call create_bitmap

    mov rsi, created_bitmap
    call video_print

    ;Create PML4
    mov rcx, 4      ; Counter of 4 qwords representing 4 PML4 entries
    mov rax, 0      ; index
    Initializing_PML4_loop:
        mov qword[PML4_address+rax], 0
        add rax, 8
        dec rcx
        cmp rcx, 0
        jne Initializing_PML4_loop

    mov rdi, PML4_address
    mov cr3, rdi

    ; Mapping all physical memory
    mov rsi, 0          ; Virtual address
    mov r8, 1
    shl r8, 21          ; The value used to increment the virtual address to the next 2MB
    mov rdi, 1
    mov r9, 0           ; Count of 2MB mapped
    
    loop_2MB:
        cmp r9, qword[Count_of_2MB]
        je check_4k_pages
        call Page_Walk
        inc r9
        add rsi, r8      ;Next Virtual Address

        jmp loop_2MB


    check_4k_pages:
        mov rdi, 0
        shr r8, 9
        mov r9, 0           ; Count of 4K mapped
        loop_4K:
            cmp r9, qword[Count_of_4KB]
            je done_mapping
            call Page_Walk
            inc r9
            add rsi, r8      ;Next Virtual Address

            jmp loop_4K

    done_mapping:

    popaq
ret


Page_Walk:
    ; Parameters:
    ; rsi --> virtual address
    ; rdi --> 1 if 2MB
    pushaq

    shl rdi, 7              ;Used to modify Page Size bit

    mov r8, rsi
    shr r8, 39

    imul r8, 8              ; Get effective offset of PML4 entry address
    mov r9, PML4_address
    add r9, r8              ; Address of PML4 entry

    mov r8, qword[r9]
    and r8, 1
    cmp r8, 1               ; Checking present bit
    je read_pdp

    mov r10, qword[last_address]
    ;mov r10, qword[r11]
    shl r10, 12
    or qword[r9], r10
    or qword[r9], 1
    call create_table

    read_pdp:
        mov r8, qword[r9]        ; r8 has the value of the PML4 entry
        shr r8, 12               ; r8 is PDP base address

        mov r9, rsi             ; r9 is the virtual address
        shr r9, 30              
        and r9, 111111111b      ; r9 is the 9 bits corresponding to the PDP index
        imul r9, 8              ; r9 is effective offset of PDP entry address
        add r9, r8              ; r9 is the address of the PDP entry
    
    mov r8, qword[r9]
    and r8, 1
    cmp r8, 1               ; Checking present bit
    je read_PD

    mov r10, qword[last_address]
    ;mov r10, qword[r11]
    shl r10, 12
    or qword[r9], r10
    or qword[r9], 1
    call create_table
    
    read_PD:
        mov r8, qword[r9]        ; r8 has the value of the PDP entry
        shr r8, 12               ; r8 is PD base address

        mov r9, rsi             ; r9 is the virtual address
        shr r9, 21              
        and r9, 111111111b      ; r9 is the 9 bits corresponding to the PD index
        imul r9, 8              ; r9 is effective offset of PD entry address
        add r9, r8              ; r9 is the address of the PD entry

    mov r8, qword[r9]
    and r8, 1
    cmp r8, 1               ; Checking present bit
    je read_PT

    mov r10, qword[last_address]
    ;mov r10, qword[r11]
    shl r10, 12
    or qword[r9], r10
    or qword[r9], 1
    or qword[r9], rdi
    cmp rdi, 0
    jne map_2MB
    call create_table

    read_PT:
        mov r8, qword[r9]        ; r8 has the value of the PD entry
        and r8, rdi              ; Check the size
        cmp r8, 0
        jne map_2MB

        mov r8, qword[r9]        ; r8 has the value of the PD entry
        shr r8, 12               ; r8 is PT base address

        mov r9, rsi             ; r9 is the virtual address
        shr r9, 12              
        and r9, 111111111b      ; r9 is the 9 bits corresponding to the PT index
        imul r9, 8              ; r9 is effective offset of PT entry address
        add r9, r8              ; r9 is the address of the PT entry

    map_4K:
        mov r8, qword[r9]
        call get_4K_frame_address   ; returns with physical frame address in rsi

        shl rsi, 12
        or qword[r9], rsi
        or qword[r9], 1
    jmp return

    map_2MB:
        mov r8, qword[r9]
        call get_2MB_frame_address   ; returns with physical frame address in rsi

        shl rsi, 21
        or qword[r9], rsi
        or qword[r9], 1

    return:
        popaq
ret

create_table:
    pushaq

    ;Create table
    mov rcx, 512      ; Counter of 512 qwords representing 512 entries
    mov rax, 0      ; index
    mov rbx, qword[last_address]
    Initializing_table_loop:
        mov qword[rbx+rax], 0
        add rax, 8
        dec rcx
        cmp rcx, 0
        jne Initializing_table_loop

    add rbx, rax
    mov qword[last_address], rbx

    ; Refresh CR3
    mov rdi, PML4_address
    mov cr3, rdi

    popaq

ret

get_4K_frame_address:
    ; returns: rsi has address of physical frame
    push r8
    push r9

    mov r8, 0       ;index
    
    .bitmap_loop:
        cmp byte[Bitmap_address + r8], 1
        jne .get_address
        add r8, 8
        mov r9, Bitmap_address
        add r9, r8
        cmp r9, Bitmap_end_address
        jne .bitmap_loop

    .get_address:
        mov rsi, qword[PTR_MEM_REGIONS_TABLE]    ; Address of first physical frame
        add rsi, r8                              ; rsi: Address of free physical frame
        mov byte[Bitmap_address + r8], 1

    pop r9
    pop r8

ret

get_2MB_frame_address:

    push r8
    push r9
    push r10
    push r11

    mov r8, 0       ;index

    bitmap_loop:
        cmp byte[Bitmap_address + r8], 1
        jne check_2MB
        add r8, 8
        mov r9, Bitmap_address
        add r9, r8
        cmp r9, Bitmap_end_address
        jne bitmap_loop


    check_2MB:
        mov r9, r8
        mov r10, 0      ;Frames count
        check_2MB_loop:
            inc r10
            add r8, 8

            cmp r10, 512
            je found
            
            mov r9, Bitmap_address
            add r11, r8
            cmp r11, Bitmap_end_address
            je not_found
            
            cmp byte[Bitmap_address + r8], 1
            jne check_2MB_loop
            
            jmp bitmap_loop

    found:
        mov rsi, qword[PTR_MEM_REGIONS_TABLE]    ; Address of first physical frame
        add rsi, r9                              ; Address of the 2MB physical frame

        mov r10, 0      ;Frames count
        loop_set_unavailable:
            mov byte[Bitmap_address + r9], 1
            
            inc r10
            add r9, 8

            cmp r10, 512
            jne loop_set_unavailable

        pop r11
        pop r10
        pop r9
        pop r8
    ret

    not_found:
        ; Print error message





