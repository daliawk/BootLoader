%define PTR_MEM_REGIONS_COUNT       0x21000
%define PTR_MEM_REGIONS_TABLE       0x21018
%define MEM_PAGE_4K                 0x1000
%define PAGE_PRESENT_WRITE              0x3 
%define PAGE_SIZE_BIT               10000000b
%define BITMAP_ADDRESS              0x40000
%define PML4_ADDRESS                0x15000      


Count_of_Frames dq 0                ; Total number of physical 4K frames
last_address dq 0                   ; Address of memory that can be used as a page

region_1 db "region 1", 13, 0
region_other db "other region", 13, 0

mark_bit:
    ;Parameters:
    ; (index) is passed in register rsi
    ; The value to be put in the bit is passed in register rdi (0/1)
    pushaq

    cmp rsi, 512
    jge cont
    
    ; We will set the first 2MB as mapped
    mov rdi, 1

    cont:
    mov rax, rsi                ;rax= index
    and rax, 63                 ;rax= index % 64

    mov r9, rdi                 ;r9= 0 or 1 depending on the value to be modified

    mov cl,al                   ;cl= index % 64
    shl r9, cl                  ;r9 = (0/1)<< (index % 64)

    mov r10, BITMAP_ADDRESS

    mov r8, rsi                 ;r8=index
    shr r8, 6                   ;r8=index/64
    shl r8, 3                   ;index offset of the array
    add r10, r8                 ;Address of word at index

    or QWORD[r10], r9

    popaq
    ret

check_bit:
    ; Parameter (index) is passed in register rsi
    ; Returns: true or false in rsi
    push rax
    push r9
    push rcx
    push r8
    push r10

    mov rax, rsi                ;rax= index
    and rax, 63                 ;rax= index % 64

    mov r9, 1                   ;r9= 0 or 1 depending on the value to be modified

    mov cl,al                   ;cl= index % 64
    shl r9, cl                  ;r9 = (0/1)<< (index % 64)

    mov r10, BITMAP_ADDRESS

    mov r8, rsi                 ;r8=index
    shr r8, 6                   ;r8=index/64
    shl r8, 3                   ;index offset of the array
    add r10, r8                 ;Address of word at index

    and r9, QWORD[r10]
    mov rsi, r9


    pop r10
    pop r8
    pop rcx
    pop r9
    pop rax

    ret

create_bitmap:
    pushaq
    
    mov r8, 0                               ;index
    mov rbx, PTR_MEM_REGIONS_TABLE
    mov r10, 512
    mov r12, qword[PTR_MEM_REGIONS_COUNT]   ; Count of regions

    mem_regions_loop:
        
        mov ecx, dword[rbx+16]              ; rcx: region type
        mov rax, qword[rbx+8]               ; rax: region length
        xor rdx, rdx
        mov r13, MEM_PAGE_4K
        idiv r13                            ; Divide length by 4K
                                            ; rax has count of 4K in this region
                            
        mov rdi, 1

        cmp rcx, 1
        jne set_bits_loop                   ; If the region type is not 1, set the bits in the bit map

        mov rdi, 0

        set_bits_loop:
            mov rsi, r8
            call mark_bit

            inc r8
            dec rax
            cmp rax, 0
            jg set_bits_loop

        ; In case the region size is not divisable by 4K
        cmp rdx, 0
        je increment

        mov rsi, r8
        mov rdi, 0
        call mark_bit
        inc r8
            
        increment:
            dec r12
            add rbx, 0x18

            cmp r12, 0
            jne mem_regions_loop

    mov qword[Count_of_Frames], r8

    popaq
ret



Mapping_Memory:
    pushaq

    ; Calculating first free address
    mov rax, qword[PTR_MEM_REGIONS_COUNT]        ; Moving to rax count of regions
    imul rax, 0x18                              ; rax = 24 bytes * count of regions                             
    mov r9, PTR_MEM_REGIONS_TABLE               ; r9 = address of memory regions info
    add r9, rax                                 ; r9 = address of memory regions info + (24 bytes * count of regions)
    mov r11, r9
    add r9, MEM_PAGE_4K       
    and r9, 0xFFF000                            ; Making sure that it is 4K aligned                           
    mov qword[last_address], r9                ; address of 1 word after memory regions info


    ; Initializing 4 memory pages
    mov rdi, PML4_ADDRESS
    mov rcx, 0x800                  ; Setting rep counter to 2048
    xor rax, rax                    ; Zeroing rax
    mov es, ax
    cld                             ; Clearing direction flag
    rep stosq                       ; Storing 2048 of the 8 bytes in rax at address in rdi (8 * 2 KB = 4 memory pages)

    mov rdi,PML4_ADDRESS 
    ; PML4 is now at 0x13000
    
    mov rax, rdi 
    add rax, MEM_PAGE_4K            ; rax: address of the next page (PDP table)
    or rax, PAGE_PRESENT_WRITE      ; Set the Present and the Writable bits
    mov qword[rdi], rax 
    ; PDP is now at 0x14000


    add rdi, MEM_PAGE_4K
    mov rax, rdi
    add rax, MEM_PAGE_4K            ; rax: address of the next page (PD table)
    or rax, PAGE_PRESENT_WRITE      ; Set the Present and the Writable bits
    mov qword[rdi], rax 
    ; PD is now at 0x15000
    
   
    add rdi, MEM_PAGE_4K
    mov qword[rdi], PAGE_PRESENT_WRITE      ; Now the first PD entry maps the first 2MB
    or qword[rdi], PAGE_SIZE_BIT            ; Setting the page size to 2MB

    mov rdi, PML4_ADDRESS
    mov cr3, rdi


    call create_bitmap                      ; Creating the bitmap and filling it

    mov rsi, created_bitmap
    call video_print

    ; Mapping all physical memory
    mov rsi, 0x200000       ; Virtual address since the first 2MB have already been mapped
    mov r8, 0x200000        ; The value used to increment the virtual address to the next 2MB
    mov rdi, 1

    mov rcx, 0
    
    loop_2MB:
        cmp rcx, 1          
        je check_4k_pages
        call Page_Walk      ; Takes address in rsi and size in rdi... returns 1 in rcx if there are no more 2MB pages
        add rsi, r8         ; Next Virtual Address

        jmp loop_2MB

    
    
    check_4k_pages:

        mov rcx, 0
        mov rdi, 0
        shr r8, 9

        loop_4K:
            cmp rcx, 1
            je done_mapping
            call Page_Walk  ; Takes address in rsi and size in rdi... returns 1 in rcx if there are no more 2MB pages
            add rsi, r8     ; Next Virtual Address

            jmp loop_4K

    done_mapping:

    push rsi
    mov rsi, finished_mapping_msg
    call video_print
    pop rsi
    popaq
ret


Page_Walk:
    ; Parameters:
    ; rsi --> virtual address
    ; rdi --> 1 if 2MB
    
    ;pushaq
    push r8
    push r9
    push r10
    push rdi
    push rsi

    shl rdi, 7              ;Used to modify Page Size bit

    mov r8, rsi
    shr r8, 39

    imul r8, 8              ; Get effective offset of PML4 entry address
    mov r9, PML4_ADDRESS
    add r9, r8              ; Address of PML4 entry

    mov r8, qword[r9]
    and r8, PAGE_PRESENT_WRITE
    cmp r8, PAGE_PRESENT_WRITE  ; Checking present bit
    je read_pdp

    ; In case the page does not exist
    mov r10, qword[last_address]
    mov qword[r9], r10
    or qword[r9], PAGE_PRESENT_WRITE 
    call create_table

    read_pdp:
        mov r8, qword[r9]        ; r8 has the value of the PML4 entry
        shr r8, 12               
        shl r8, 12               ; r8 is PDP base address (After zeroing the last 12 bits)


        mov r9, rsi             ; r9 is the virtual address
        shr r9, 30              
        and r9, 111111111b      ; r9 is the 9 bits corresponding to the PDP index
        imul r9, 8              ; r9 is effective offset of PDP entry address
        add r9, r8              ; r9 is the address of the PDP entry

    
    mov r8, qword[r9]
    and r8, PAGE_PRESENT_WRITE
    cmp r8, PAGE_PRESENT_WRITE  ; Checking present bit
    je read_PD

    ; In case the page does not exist
    mov r10, qword[last_address]
    mov qword[r9], r10
    or qword[r9], PAGE_PRESENT_WRITE
    call create_table
    
    read_PD:
        mov r8, qword[r9]       ; r8 has the value of the PDP entry
        shr r8, 12               
        shl r8, 12              ; r8 is PD base address (After zeroing the last 12 bits)

        mov r9, rsi             ; r9 is the virtual address
        shr r9, 21              
        and r9, 111111111b      ; r9 is the 9 bits corresponding to the PD index
        imul r9, 8              ; r9 is effective offset of PD entry address
        add r9, r8              ; r9 is the address of the PD entry


    mov r8, qword[r9]
    and r8, PAGE_PRESENT_WRITE
    cmp r8, PAGE_PRESENT_WRITE  ; Checking present bit
    je read_PT

    ; In case the page does not exist
    mov r10, qword[last_address]
    mov qword[r9], r10
    or qword[r9], PAGE_PRESENT_WRITE
    cmp rdi, 0
    jne map_2MB                 ; Checking the size bit to map 2MB
    call create_table

    read_PT:
        mov r8, qword[r9]        ; r8 has the value of the PD entry
        and r8, rdi              ; Check the size
        cmp r8, 0
        jne map_2MB

        mov r8, qword[r9]        ; r8 has the value of the PD entry
        shr r8, 12               
        shl r8, 12              ; r8 is PT base address (After zeroing the last 12 bits)

        mov r9, rsi             ; r9 is the virtual address
        shr r9, 12              
        and r9, 111111111b      ; r9 is the 9 bits corresponding to the PT index
        imul r9, 8              ; r9 is effective offset of PT entry address
        add r9, r8              ; r9 is the address of the PT entry


    map_4K:
        mov r8, qword[r9]
        call get_4K_frame_address   ; returns with physical frame address in rsi

        cmp rcx, 1
        je return

        ; Refreshing CR3
        mov rdi, PML4_ADDRESS
        mov cr3, rdi

        mov qword[r9], rsi
        or qword[r9], PAGE_PRESENT_WRITE

        ; Refreshing CR3
        mov rdi, PML4_ADDRESS
        mov cr3, rdi

       
    jmp return

    map_2MB:
        mov r8, qword[r9]
        call get_2MB_frame_address   ; returns with physical frame address in rsi

        ; Refreshing CR3
        mov rdi, PML4_ADDRESS
        mov cr3, rdi

        cmp rcx, 1
        je return

        mov qword[r9], rsi
        or qword[r9], PAGE_PRESENT_WRITE
        or qword[r9], PAGE_SIZE_BIT

        ; Refreshing CR3
        mov rdi, PML4_ADDRESS
        mov cr3, rdi


    return:
        pop rsi
        pop rdi
        pop r10
        pop r9
        pop r8
ret

create_table:
    pushaq

    ; Refresh CR3
    mov rdi, PML4_ADDRESS
    mov cr3, rdi


    ;Create Page
    mov rdi, qword[last_address]

    mov rcx, 0x200                  ; set rep counter to 512
    xor rax, rax                    ; Zero out rax
    mov es, ax
    cld                             ; Clear direction flag
    rep stosq                       ; Store rax (8 bytes) at address rdi

    mov qword[last_address], rdi    ; Update last address

    ; Refresh CR3
    mov rdi, PML4_ADDRESS
    mov cr3, rdi

    
    push rsi
    mov rsi, dot
    call video_print
    pop rsi
    

    popaq

ret

get_4K_frame_address:
    ; returns: rsi has address of physical frame
    push r8
    push r9
    push rdi

    mov r8, 512       ;index

    .bitmap_loop:                       ; Searches for an empty frame
        mov rsi, r8
        call check_bit
        cmp rsi, 0
        je .get_address
        inc r8
        cmp r8, qword[Count_of_Frames]
        jl .bitmap_loop

        jmp not_found_4K

    .get_address:
        mov rsi, r8
        mov rdi, 1
        call mark_bit

        mov rsi, qword[PTR_MEM_REGIONS_TABLE]    ; Address of first physical frame
        imul r8, 0x1000
        add rsi, r8                              ; rsi: Address of free physical frame

    pop rdi
    pop r9
    pop r8

ret

not_found_4K:
    push rsi
    mov rsi, not_found_4K_msg
    call video_print
    pop rsi

    mov rcx, 1
    pop rdi
    pop r9
    pop r8
ret


get_2MB_frame_address:

    push r8
    push r9
    push r10
    push r11
    push rdi

    mov r8, 512       ;index

    bitmap_loop_2MB:
        mov rsi, r8
        call check_bit
        cmp rsi, 0
        je check_2MB
        add r8, 512                          ; Incrementing to the next 2MB
        cmp r8, qword[Count_of_Frames]
        jl bitmap_loop_2MB

        jmp not_found


    check_2MB:                              ; Checks for 512 empty consecutive frames
        mov r9, r8
        mov r10, 0      ;Frames count
        check_2MB_loop:
            inc r10
            inc r8

            cmp r10, 512
            je found
            
            cmp r8, qword[Count_of_Frames]
            je not_found
            
            mov rsi, r8
            call check_bit
            cmp rsi, 0
            je check_2MB_loop
            
            mov r8, r9
            add r8, 512
            jmp bitmap_loop_2MB

    found:
        mov r8, r9
        imul r9, 0x1000         ; Address of the 2MB physical frame

        mov r10, 0      ;Frames count
        mov rdi, 1
        loop_set_unavailable:
            mov rsi, r8
            call mark_bit
            
            inc r10
            inc r8

            cmp r10, 512
            jne loop_set_unavailable

        mov rsi, r9                            ; Address of the 2MB physical frame

        pop rdi
        pop r11
        pop r10
        pop r9
        pop r8
    ret

    not_found:

    push rsi
    mov rsi, not_found_2MB
    call video_print
    pop rsi

        mov rcx, 1
        pop rdi
        pop r11
        pop r10
        pop r9
        pop r8
        ret
