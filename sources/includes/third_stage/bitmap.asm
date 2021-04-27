%define PTR_MEM_REGIONS_COUNT       0x21000
%define PTR_MEM_REGIONS_TABLE       0x21018
%define MEM_PAGE_4K                 0x1000


Bitmap_address dw 0
Count_of_2MB dw 0
Count_of_4KB dw 0
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
    mov word[Bitmap_address], r9w                ; address of bit map 1 word after memory regions info

    
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

        add r8, rax                 ; Updating to the last index
        xor rdx, rdx
        idiv r10                    ; Check how many 2MB in this region
        add word[Count_of_2MB], ax ; Inrementing number of available 2MB pages
        add r9, rdx                 ; Updating cumalitive remaining 4KB pages since last unusable memory
        mov rax, r9
        xor rdx, rdx
        idiv r10                    ; Check how many 2MB in the remaining 4KB pages
        add word[Count_of_2MB], ax  ; Inrementing number of available 2MB pages with the quotient
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
            add word[Count_of_4KB], r9w  ; The previous available 4KB pages will be mapped with 4KB since they cannot be formed as consecutive 2MB
            mov r9, 0   ; Zero the remainder since there is an unusable region after it
        
        increment:
            dec rbx
            add rdi, 0x18
            cmp rbx, 0
            jne mem_regions_loop

    add word[Count_of_4KB], r9w  ; The previous available 4KB pages will be mapped with 4KB since they cannot be formed as consecutive 2MB
    add r8, Bitmap_address
    
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


    call create_bitmap

    mov rsi, created_bitmap
    call video_print


    ; Set es:di with the address of the page table
    mov ax,PML4_address
    mov es,ax
    mov edi,PAGE_TABLE_BASE_OFFSET

    ; Initializing 4 memory pages
    mov ecx, 0x1000                 ; set rep counter to 4096
    xor eax, eax                    ; Zero out eax
    cld                             ; Clear direction flag
    rep stosd                       ; Store EAX (4 bytes) at address ES:EDI
    ; rep will repeat for 4096 and advance EDI by 4 each time
    ; 4 * 4096 = 4 * 4 KB = 16 KB = 4 memory pages

    mov edi,PAGE_TABLE_BASE_OFFSET ; Reset di to point to 0x1000
    ; PML4 is now at [es:di] = [0x0000:0x1000]



