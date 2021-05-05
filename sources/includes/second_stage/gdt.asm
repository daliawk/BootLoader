GDT64:
    .Null: equ $ - GDT64        ; The null descriptor.
        times 8 db 0            ; The null entry contains only zeroes

    .Code: equ $ - GDT64        ; The Kernel code descriptor.
        dw 0                    ; Lower part of Limit
        dw 0                    ; Lower part of Base
        db 0                    ; Middle part of Base
        db 10011000b            ; Access byte --> we set present bit (Pr), executable bit (Ex), and the Conforming bit (DC)
        db 00100000b            ; The upper 4 bits are the Flags --> we set L=1
                                ; The lower 4 bits are the higher part of the Limit
        db 0                    ; Rest of higher part of the Base

    .Data: equ $ - GDT64        ; The Kernel data descriptor.
        dw 0                    ; Lower part of Limit
        dw 0                    ; Lower part of Base
        db 0                    ; Middle part of Base
        db 10010011b            ; Access byte --> we set present bit (Pr), executable bit (Ex), and the Conforming bit (DC)
        db 0                    ; The upper 4 bits are the Flags --> we set L=1
                                ; The lower 4 bits are the higher part of the Limit
        db 0                    ; Rest of higher part of the Base
    ALIGN 4
        dw 0                    ; Making the address of the GDT double-word-aligned
    .Pointer:
        dw $ - GDT64 - 1        ; Length of GDT
        dd GDT64                ; Base Address of GDT