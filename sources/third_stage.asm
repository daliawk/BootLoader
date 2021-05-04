[ORG 0x10000]


[BITS 64]


Kernel:

mov rsi, hello_world_str
call video_print

call Mapping_Memory

call memory_tester

mov rsi, horray
call video_print


hang:                   ; An infinite loop just in case interrupts are enabled. More on that later.
    hlt               ; Halt will suspend the execution. This will not return unless the processor got interrupted.
    jmp hang          ; Jump to hang so we can halt again.


bus_loop:
    device_loop:
        function_loop:
            call get_pci_device
            inc byte [function]
            cmp byte [function],8
        jne device_loop
        inc byte [device]
        mov byte [function],0x0
        cmp byte [device],32
        jne device_loop
    inc byte [bus]
    mov byte [device],0x0
    cmp byte [bus],255
    jne bus_loop

channel_loop:
    mov qword [ata_master_var],0x0
    master_slave_loop:
        mov rdi,[ata_channel_var]
        mov rsi,[ata_master_var]
        call ata_identify_disk
        inc qword [ata_master_var]
        cmp qword [ata_master_var],0x2
        jl master_slave_loop

    inc qword [ata_channel_var]
    inc qword [ata_channel_var]
    cmp qword [ata_channel_var],0x4
    jl channel_loop
    

call init_idt
call setup_idt
mov rsi,hello_world_str
call video_print

kernel_halt: 
    hlt
    jmp kernel_halt


;*******************************************************************************************************************

      
      %include "sources/includes/third_stage/pushaq.asm"
      %include "sources/includes/third_stage/pic.asm"
      %include "sources/includes/third_stage/idt.asm"
      %include "sources/includes/third_stage/pci.asm"
      %include "sources/includes/third_stage/video.asm"
      %include "sources/includes/third_stage/pit.asm"
      %include "sources/includes/third_stage/ata.asm"
      %include "sources/includes/third_stage/bitmap.asm"
      %include "sources/includes/third_stage/memory_tester.asm"

;*******************************************************************************************************************


colon db ':',0
comma db ',',0
newline db 13,0

end_of_string  db 13        ; The end of the string indicator
start_location   dq  0x0  ; A default start position (Line # 8)

hello_world_str db 'Hello all here',13, 0
created_bitmap db "Finished bitmap", 13, 0
not_found_2MB db "Did not find 2MB page", 13, 0
finished_mapping_msg db "Finished Mapping", 13, 0
created_page_msg db "Created a page", 13, 0
read_pdp_msg db "Read PDP", 13, 0
read_PD_msg db "Read PD", 13, 0
read_PT_msg db "Read PT", 13, 0
error_msg db "Everything is not fine", 13, 0
horray db "HORRRAAAAAAAAY!!!!!", 13, 0
check_msg db "Check", 13, 0



ata_channel_var dq 0
ata_master_var dq 0

bus db 0
device db 0
function db 0
offset db 0
hexa_digits       db "0123456789ABCDEF"         ; An array for displaying hexa decimal numbers
ALIGN 4


times 8192-($-$$) db 0                          ; 0x2000 long