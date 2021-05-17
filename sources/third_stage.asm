[ORG 0x10000]


[BITS 64]


Kernel:

mov rsi, hello_world_str
call video_print


call Mapping_Memory

call cls            ; Clearing the screen
mov rsi, cls_msg
call video_print


mov rsi, finished_mapping_msg
call video_print

;call memory_tester
;mov rsi, finished_testing
;call video_print

; Scanning all PCI devices
call scan_pci_devices               
mov rsi, finished_pci_scan_msg
call video_print

; Identifying ATA disks
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

mov rsi, identified_ata_msg
call video_print

; Initializing and setting the IDT
call init_idt
call setup_idt
mov rsi, finished_idt_msg
call video_print

mov rsi,done
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
not_found_2MB db "Finished Mapping 2MB pages", 13, 0
not_found_4K_msg db "Finished Mapping 4KB pages", 13, 0
finished_mapping_msg db "Finished Mapping", 13, 0
error_msg db "Error reading and writing to memory", 13, 0
finished_testing db "Finished Mapping and Testing Memory!", 13, 0
check_msg db "Check", 13, 0
dot db ".", 0
cls_msg db "Screen has been cleared", 13, 0
finished_pci_scan_msg db "Finished scanning pci devices", 13, 0
identified_ata_msg db "Identified ATA and loaded its parameters", 13, 0
finished_idt_msg db "Initialized and set up IDT", 13, 0
done db "The Bootloader is done!", 13, 0

pci_headers_count dq 0
pci_headers_address dq 0x3000

ata_channel_var dq 0
ata_master_var dq 0

bus db 0
device db 0
function db 0
offset db 0
hexa_digits       db "0123456789ABCDEF"         ; An array for displaying hexa decimal numbers
ALIGN 4


times 16384-($-$$) db 0                          ; 0x2000 long