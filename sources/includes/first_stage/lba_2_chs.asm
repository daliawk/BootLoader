;************************************** lba_2_chs.asm **************************************
lba_2_chs:  ; Convert the value store in [lba_sector] to its equivelant CHS values and store them in [Cylinder],[Head], and [Sector]
        
  ;[Sector] = ([lba_sector] % [spt]) + 1
  ;[Cylinder] = ([lba_sector]/[spt]) / [hpc]
  ;[Head] = ([lba_sector]/[spt]) % [hpc]

  pusha                   ;Saving all general purpose registers on the stack
  xor dx,dx               ;Zero dx
  mov ax, [lba_sector]

  div word [spt]          ;ax = [lba_sector] / [spt]
                          ;dx = [lba_sector] % [spt]

  inc dx                  ;dx = ([lba_sector] % [spt]) + 1
  mov [Sector], dx
  xor dx,dx               ;Zero dx
  
  div word [hpc]          ;ax = ([lba_sector]/[spt]) / [hpc]
                          ;dx = ([lba_sector]/[spt]) % [hpc]

  mov [Cylinder], ax 
  mov [Head], dl
  popa                    ;Restoring all general purpose registers from the stack
  ret