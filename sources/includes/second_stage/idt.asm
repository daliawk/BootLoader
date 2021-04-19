ALIGN 4                 ; Make sure that the IDT starts at a 4-byte aligned address    
IDT_DESCRIPTOR:         ; The label indicating the address of the IDT descriptor to be used with lidt
      .Size dw    0x0     ; Table size is zero (word, 16-bit)
      .Base dd    0x0     ; Table base address is NULL (Double word, 32-bit)

load_idt_descriptor:
    pusha
    lidt [IDT_DESCRIPTOR]    ; load the IDT descriptor
    ; We cannot use BIOS interrupts any more.
    popa
    ret