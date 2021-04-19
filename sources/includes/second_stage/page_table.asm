%define PAGE_TABLE_BASE_ADDRESS 0x0000
%define PAGE_TABLE_BASE_OFFSET 0x1000
%define PAGE_TABLE_EFFECTIVE_ADDRESS 0x1000
%define PAGE_PRESENT_WRITE 0x3  ; 011b
%define MEM_PAGE_4K         0x1000

build_page_table:
    pusha                                   ; Save all general purpose registers on the stack

            ; This function need to be written by you.

    popa                                ; Restore all general purpose registers from the stack
    ret