GDT64:
    .Null: equ $ - GDT64         ; The null descriptor.
    ; This function need to be written by you.

    .Code: equ $ - GDT64         ; The Kernel code descriptor.
    ; This function need to be written by you.

    .Data: equ $ - GDT64         ; The Kernel data descriptor.
    ; This function need to be written by you.

    .Pointer:
    ; This function need to be written by you.