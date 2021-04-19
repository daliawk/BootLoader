 ;************************************** read_disk_sectors.asm **************************************
     read_disk_sectors:  ; This function will read a number of 512-sectors stored in DI 
                         ; The sectors should be loaded at the address starting at [disk_read_segment:disk_read_offset]
          pusha                         ;Saving all general purpose registers on the stack
          add di,[lba_sector]           ;Last sector to be read
          
          ;The address where the read sector(s) will be loaded should be in es:bx
          mov ax,[disk_read_segment]    
          mov es,ax 
          add bx,[disk_read_offset]     
          mov dl,[boot_drive]           ;Get drive number
          
          .read_sector_loop:
               call lba_2_chs           ;Converting sector format from LBA to CHS.
               mov ah, 0x2              ;INT 0x13 Function 0x2 --> Read Sectors
               mov al,0x1               ;Number of sectors to be read
               mov cx,[Cylinder]        ;Cylinder index
               shl cx,0x8               ;Cylinder index should be from bit 6 to 15
               or cx,[Sector]           ;Sector index should be from bit 0 to 5
               mov dh,[Head]            ;Head index
               int 0x13 
               jc .read_disk_error      ;Print error message in case of something wrong happening
               
               mov si,dot               ;Else print a '.' indicating successful sector read
               call bios_print
               inc word [lba_sector]    ;Get next sector
               add bx,0x200             ;Increment offset
               cmp word[lba_sector],di  ;If we have reached the last sector, exit loop
               jl .read_sector_loop     

          jmp .exit

          .read_disk_error:
               mov si,disk_error_msg   
               call bios_print
               jmp hang

          .exit:
               popa                     ;Restoring all general purpose registers from the stack
               ret
            