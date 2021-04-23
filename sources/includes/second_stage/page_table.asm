%define PAGE_TABLE_BASE_ADDRESS         0x0000
%define PAGE_TABLE_BASE_OFFSET          0x1000
%define PAGE_TABLE_EFFECTIVE_ADDRESS    0x1000
%define PAGE_PRESENT_WRITE              0x3  
%define MEM_PAGE_4K                     0x1000

build_page_table:
        pusha                                   ; Save all general purpose registers on the stack

        ; Set es:di with the address of the page table
        mov ax,PAGE_TABLE_BASE_ADDRESS
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
        lea eax, [es:di + MEM_PAGE_4K] ; Store the address of the next page into eax (PDP Table).
        or eax, PAGE_PRESENT_WRITE ; Set the Present and the Writable flags: bit 0 and bit 1.
        mov [es:di], eax ; Store eax = 0x2003 into the first entry of the PML4.
        ; PDP is now at [es:di] = [0x0000:0x2000]
        add di,MEM_PAGE_4K
        lea eax, [es:di + MEM_PAGE_4K] ; Store the address of the next page into eax (PDP Table).
        or eax, PAGE_PRESENT_WRITE ; Set the Present and the Writable flags: bit 0 and bit 1.
        mov [es:di], eax ; Store eax = 0x3003 into the first entry of the PML4.
        ; PD is now at [es:di] = [0x0000:0x3000]
        add di,MEM_PAGE_4K
        lea eax, [es:di + MEM_PAGE_4K] ; Store the address of the next page into eax (PDP Table).
        or eax, PAGE_PRESENT_WRITE ; Set the Present and the Writable flags: bit 0 and bit 1.
        mov [es:di], eax ; Store eax = 0x4003 into the first entry of the PML4.
        ; PT is now at [es:di] = [0x0000:0x4000]
        add di,MEM_PAGE_4K
        mov eax, PAGE_PRESENT_WRITE ; Store 0x0003 to eax.
        .pte_loop: ; Fill 512 entries of the PT to point to the first 2 MB of physical memory
                mov [es:di], eax
                add eax, MEM_PAGE_4K
                add di, 0x8
                cmp eax, 0x200000 ; Check if we mapped 2 MB.
                jl .pte_loop ; Jump if we still not mapped 2 MB
        
        mov si, pml4_page_table_msg
        call bios_print
        
        popa                                ; Restore all general purpose registers from the stack
        ret