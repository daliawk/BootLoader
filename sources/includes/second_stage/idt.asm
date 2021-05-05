ALIGN 4                 ; Ensuring that the IDT double-word aligned    
IDT_DESCRIPTOR:        
      ; We do not need a valid IDT descriptor so we are going to use a null one
      .Size dw    0x0     ; 16 bits for the size
      .Base dd    0x0     ; 32 bits for the table base address

load_idt_descriptor:
    pusha
    lidt [IDT_DESCRIPTOR]    ; load the IDT descriptor
    ; We cannot use BIOS interrupts any more.
    popa
    ret