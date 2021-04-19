;************************************** first_stage_data.asm **************************************

      boot_drive db 0x0                               ;Boot drive number
      lba_sector dw 0x1                               ;The next sector to be read (starts at 0x1 since 0x0 is the MBR and it has been loaded)
      spt dw 0x12                                     ;The number of sectors per track (0x12 is the default for floppy)
      hpc dw 0x2                                      ;The number of heads per cylinder (0x2 is the default for floppy)
      
      ;Variables used in the conversion from LBA to CHS
      Cylinder dw 0x0
      Head db 0x0
      Sector dw 0x0

      ;String Messages
      disk_error_msg db 'Disk Error', 13, 10, 0
      fault_msg db 'Unknown Boot Device', 13, 10, 0
      booted_from_msg db 'Booted from ', 0
      floppy_boot_msg db 'Floppy', 13, 10, 0
      drive_boot_msg db 'Disk', 13, 10, 0
      greeting_msg db '1st Stage Loader', 13, 10, 0
      second_stage_loaded_msg db 13,10,'2nd Stage loaded, ', 0
      dot db '.',0
      newline db 13,10,0
      disk_read_segment dw 0
      disk_read_offset dw 0
      key_stroke_msg db 'Press a key', 13, 10, 0
