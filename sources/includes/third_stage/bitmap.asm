%define MEM_REGIONS_SEGMENT         0x2000
%define PTR_MEM_REGIONS_COUNT       0x1000
%define PTR_MEM_REGIONS_TABLE       0x1018
%define MEM_PAGE_4K                 0x1000


.BIT_MAP: equ PTR_MEM_REGIONS_TABLE + PTR_MEM_REGIONS_COUNT     ; Address of bit map after mem_regions
    ; Upper bound on mem regions is 0x2000:0xFFFF 
    ; max number of regions is (0xFFFF - 0x1000) / 0x18 = 0x9FF with remainder 0x17 so there are at max 0xA00 so we need at max 0xA00/8 = 0x140 bit in the bit map
    db times 0x140

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

    mov rbx, PTR_MEM_REGIONS_COUNT ;number of regions
    
    ;(Still not sure if we can use segmentation)
    mov es, MEM_REGIONS_SEGMENT
    mov rdi, PTR_MEM_REGIONS_TABLE
    mov r8, 0       ;index

    mem_regions_loop:
        mov rcx, dword[es:di+16]
        mov rax, qword[es:di+8]
        xor rdx, rdx
        idiv MEM_PAGE_4K
        mov rdx, rax            ;rdx has count of 4k
        cmp rcx, 1
        jne check_4k_bits_loop

        add r8, rdx
        jmp increment

        check_4k_bits_loop:
            mov rsi, r8
            call mark_bit
            inc r8
            dec rdx
            cmp rdx, 0
            jne check_4k_bits_loop
        
        increment:
            dec rbx
            add rdi, 0x18
            cmp rbx, 0
            jne mem_regions_loop

    popaq



