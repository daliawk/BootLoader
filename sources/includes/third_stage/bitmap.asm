%define PTR_MEM_REGIONS_COUNT       0x21000
%define PTR_MEM_REGIONS_TABLE       0x21018
%define MEM_PAGE_4K                 0x1000


Bitmap_address dw 0
Count_of_2MB dw 0
Count_of_4KB dw 0

mark_bit:
    ;Parameter (index) is passed in register rsi
    pushaq

    mov rax, rsi                ;rax= index
    and rax, 31                 ;rax= index % 32

    mov r9d, 1                  ;r9d=1

    mov cl,al                   ;cl= index % 32
    shl r9d, cl                 ;r9d = 1<< (index % 32)

    mov r10, BIT_MAP

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

    mov r10, BIT_MAP

    mov r8, rsi                 ;r8=index
    shr r8, 5                   ;r8=index/32
    shl r8, 2                   ;index offset of the array
    add r10, r8                 ;Address of word at index

    and r9d, DWORD[r10]
    mov rsi, r9d

    ;Still figure out how to return

    popaq
    ret

create_bitmap:
    pushaq
    
    ; Calculating bitmap address
    mov rax, word[PTR_MEM_REGIONS_COUNT]        ; Moving to rax count of regions
    imul rax, 0x18                              ; rax = 24 bytes * count of regions                             
    mov r9, PTR_MEM_REGIONS_TABLE               ; r9 = address of memory regions info
    add r9, rax                                 ; r9 = address of memory regions info + (24 bytes * count of regions)
    add r9, 4                                   
    mov word[Bitmap_address], r9                ; address of bit map 1 word after memory regions info

    
    mov r8, 0       ;index
    mov rdi, PTR_MEM_REGIONS_TABLE
    mov r9, 0       ; Remainder of dividing by 2MB

    mem_regions_loop:
        mov rcx, dword[rdi+16]      ; rcx: region type
        mov rax, qword[rdi+8]       ; rax: region length
        xor rdx, rdx
        idiv MEM_PAGE_4K            ; Divide length by 4K
                                    ; rax has count of 4K in this region
        cmp rcx, 1
        jne check_4k_bits_loop      ; If the region type is not 1, set the bits in the bit map

        add r8, rax                 ; Updating to the last index
        idiv 512                    ; Check how many 2MB in this region
        add word[Count_of_2MB], rax ; Inrementing number of available 2MB pages
        add r9, rdx                 ; Updating cumalitive remaining 4KB pages since last unusable memory
        mov rax, r9
        idiv 512                    ; Check how many 2MB in the remaining 4KB pages
        add word[Count_of_2MB], rax ; Inrementing number of available 2MB pages with the quotient
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
            add word[Count_of_4KB], r9  ; The previous available 4KB pages will be mapped with 4KB since they cannot be formed as consecutive 2MB
            mov r9, 0   ; Zero the remainder since there is an unusable region after it
        
        increment:
            dec rbx
            add rdi, 0x18
            cmp rbx, 0
            jne mem_regions_loop

    add word[Count_of_4KB], r9  ; The previous available 4KB pages will be mapped with 4KB since they cannot be formed as consecutive 2MB

    popaq



