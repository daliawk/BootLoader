;************************************** detect_boot_disk.asm **************************************      
      detect_boot_disk: ; A subroutine to detect the the storage device number of the device we have booted from
                        ; After the execution the memory variable [boot_drive] should contain the device number
                        ; Upon booting the bios stores the boot device number into DL
            
            pusha                         ;Saving all general purpose registers on the stack
            
            call get_key_stroke           ;Indication for the user of the beginning of executing the next step

            mov si,fault_msg              ;Store address of fault_msg in si
            
            ;INT 0x13 Function 0 --> resets disk whose number is in dl
            xor ax,ax                    
            int 0x13 
            jc .exit_with_error           ;If carry flag is set, then an error occurred

            mov si,booted_from_msg
            call bios_print
            mov [boot_drive], dl          ;Saving the boot drive number

            cmp dl,0                      ;Checking if it is the floppy
            je .floppy 
            
            call load_boot_drive_params   ;If it is not a floppy, we load disk parameters
            mov si, drive_boot_msg 
            jmp .exit                     ;Skip over the .floppy code
            
            .floppy:
                  mov si,floppy_boot_msg         
                  jmp .exit
            .exit_with_error:
                  jmp hang
            .exit: 
                  call bios_print
                  popa                    ;Restore all general purpose registers from the stack
                  ret         