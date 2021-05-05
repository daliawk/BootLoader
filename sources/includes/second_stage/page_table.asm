%define PAGE_TABLE_BASE_ADDRESS         0x0000
%define PAGE_TABLE_BASE_OFFSET          0x1000
%define PAGE_TABLE_EFFECTIVE_ADDRESS    0x1000
%define PAGE_PRESENT_WRITE              0x3  
%define MEM_PAGE_4K                     0x1000

build_page_table:
        pusha                                   ; Save all general purpose registers on the stack

        ; Setting es:di with the address of the page table
        mov ax,PAGE_TABLE_BASE_ADDRESS
        mov es,ax
        mov edi,PAGE_TABLE_BASE_OFFSET

        ; Preparing 4 memory pages for the 4 levels
        mov ecx, 0x1000                         ; Setting the rep counter to 4KB
        xor eax, eax                            ; Zeroing eax
        cld                                     ; Clearing direction flag
        rep stosd                               ; Storing 4096 of the 4 bytes in eax at address es:di (4 * 4 KB = 4 memory pages)

        mov edi,PAGE_TABLE_BASE_OFFSET          ; Reloading the Page Table's address
        ; PML4 is now at address 0x0000:0x1000


        lea eax, [es:di + MEM_PAGE_4K]          ; eax: address of the next page (PDP table)
        or eax, PAGE_PRESENT_WRITE              ; Set the Present and the Writable bits
        mov [es:di], eax                        ; First PML4 entry: 0x2003 (address of PDP table + PTE bits)
        ; PDP is now at 0x0000:0x2000


        add di,MEM_PAGE_4K                      ; Moving pointer to PDP table
        lea eax, [es:di + MEM_PAGE_4K]          ; eax: address of the next page (PD table)
        or eax, PAGE_PRESENT_WRITE              ; Set the Present and the Writable bits
        mov [es:di], eax                        ; First PDP entry: 0x3003 (address of PD table + PTE bits)
        ; PD is now at 0x0000:0x3000
        
        add di,MEM_PAGE_4K                      ; Moving pointer to PD table
        lea eax, [es:di + MEM_PAGE_4K]          ; eax: address of the next page (PT table)
        or eax, PAGE_PRESENT_WRITE              ; Set the Present and the Writable bits
        mov [es:di], eax                        ; First PD entry: 0x3003 (address of PT table + PTE bits)
        ; PT is now at [es:di] = [0x0000:0x4000]
        
        add di,MEM_PAGE_4K                      ; Moving pointer to PT table
        mov eax, PAGE_PRESENT_WRITE             ; eax: Address of first physical frame + PTE bits
        .pte_loop:                              ; Map first 2MB of memory using the 512 entries of the PT table
                mov [es:di], eax
                add eax, MEM_PAGE_4K
                add di, 0x8
                cmp eax, 0x200000               ; Check if we mapped 2 MB.
                jl .pte_loop                    
        
        mov si, pml4_page_table_msg
        call bios_print
        
        popa                                ; Restore all general purpose registers from the stack
        ret