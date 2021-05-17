;definitions for comman register and ports to be used in ata.asm
;in the definitions, CR will be used for writing and AS will be used for reading

%define ATA_PRIMARY_CR_AS        0x3F6 ; defining the status port of the primary control reg 
%define ATA_SECONDARY_CR_AS      0x376 ; defining the status port of the secondary control reg

%define ATA_PRIMARY_BASE_IO          0x1F0 ; the first I/O port for primary, we have a max of 8 ports so we use up to 0x1F7 
%define ATA_SECONDARY_BASE_IO          0x170 ; the first I/O port for secondary, we have a max of 8 ports so we use up to 0x177

%define ATA_MASTER              0x0     ; definition used to indicate that we are on the master drive
%define ATA_SLAVE               0x1     ; definition used to indicate that we are on the slave drive

%define ATA_MASTER_DRV_SELECTOR    0xA0     ; ATA_REG_HDDEVSEL  selector when we use the master drive
%define ATA_SLAVE_DRV_SELECTOR     0xB0     ; ATA_REG_HDDEVSEL  selector when we use the slave drive


; Commands to issue to the controller channels
%define ATA_CMD_READ_PIO          0x20      ; command for Programmable Input/Output LBA-28 Read
%define ATA_CMD_READ_PIO_EXT      0x24      ; command for Programmable Input/Output LBA-48 Read
%define ATA_CMD_READ_DMA          0xC8      ; command for Direct Memory Access LBA-28 Read
%define ATA_CMD_READ_DMA_EXT      0x25      ; command for Direct Memory Access LBA-48 Read
%define ATA_CMD_WRITE_PIO         0x30      ; command for Programmable Input/Output LBA-28 Write
%define ATA_CMD_WRITE_PIO_EXT     0x34      ; command for Programmable Input/Output LBA-48 Write
%define ATA_CMD_WRITE_DMA         0xCA      ; command for Direct Memory Access LBA-28 Write
%define ATA_CMD_WRITE_DMA_EXT     0x35      ; command for Direct Memory Access LBA-48 Write
%define ATA_CMD_IDENTIFY          0xEC      ; Identify Command

; Different Status values where each bit represents a status --> uses hot key encoding
%define ATA_SR_BSY 0x80             ; 10000000b     Busy
%define ATA_SR_DRDY 0x40            ; 01000000b     Drive Ready
%define ATA_SR_DF 0x20              ; 00100000b     Drive Fault
%define ATA_SR_DSC 0x10             ; 00010000b     Overlapped mde
%define ATA_SR_DRQ 0x08             ; 00001000b     Set when the drive has PIO data to transfer
%define ATA_SR_CORR 0x04            ; 00000100b     Corrected Data; always set to zero
%define ATA_SR_IDX 0x02             ; 00000010b     Index Status always set to Zero
%define ATA_SR_ERR 0x01             ; 00000001b     Error


; Ports offsets that can be used relative to the I/O base ports above.
; The use of the offset is defined by the ATA data sheet specifications.
%define ATA_REG_DATA       0x00
%define ATA_REG_ERROR      0x01
%define ATA_REG_FEATURES   0x01
%define ATA_REG_SECCOUNT0  0x02     ; Used to send the number of sectors to read, max 256
%define ATA_REG_LBA0       0x03     ; LBA0,1,2 are used to store the address of the first sector (24-bits)
%define ATA_REG_LBA1       0x04     ; Incase of LBA-28 the remaining 4 bits are sent as the higher 4 bits of
%define ATA_REG_LBA2       0x05     ; ATA_REG_HDDEVSEL when selecting the drive
%define ATA_REG_SECCOUNT1  0x02     ; Used for LBA-48 which allows 16 bit for the number of sector to be read, max 65536
%define ATA_REG_LBA3       0x03     ; The rmaining 20-bit to acheive LBA-48 and nothing is written to  ATA_REG_HDDEVSEL
%define ATA_REG_LBA4       0x04
%define ATA_REG_LBA5       0x05
%define ATA_REG_HDDEVSEL   0x06     ; The register for selecting the drive, master of slave
%define ATA_REG_COMMAND    0x07     ; This register for sending the command to be performed after filling up the rest of the registers
%define ATA_REG_STATUS     0x07     ; This register is used to read the status of the channel

ata_pci_header times 1024 db 0  ; space used to store PCI header within the memory, 4 * 256 = 1024 
; Indexed values that are used as if an array to switch between value at first index and second index
ata_control_ports dw ATA_PRIMARY_CR_AS,ATA_SECONDARY_CR_AS,0
ata_base_io_ports dw ATA_PRIMARY_BASE_IO,ATA_SECONDARY_BASE_IO,0
ata_slave_identifier db ATA_MASTER,ATA_SLAVE,0
ata_drv_selector db ATA_MASTER_DRV_SELECTOR,ATA_SLAVE_DRV_SELECTOR,0

ata_error_msg       db "Error Identifying Drive",13,10,0 ; error msg for any drive indentification errors
ata_identify_msg    db "Found Drive",13,0 ; msg to indicate that the drive was identified successfully
ata_identify_buffer times 2048 db 0  ; buffer to hold the PCI header of the 4 ATA drives with some extra space (4*512)
ata_identify_buffer_index dw 0x0
ata_channel db 0
ata_slave db 0  
lba_48_supported db 'LBA-48 Supported',0
align 4


struc ATA_IDENTIFY_DEV_DUMP                     ; Starts at
.device_type                resw              1
.cylinders                  resw              1 ; 1
.gap0                       resw              1 ; 2
.heads                      resw              1 ; 3
.gap1                       resw              2 ; 4
.sectors                    resw              1 ; 6
.gap2                       resw              3 ; 7
.serial                     resw              10 ; 10
.gap3                       resw              3  ; 20
.fw_version                 resw              4  ; 23
.model_number               resw              20 ; 27
.gap4                       resw              2  ; 47
.capabilities               resw              1  ; 49       Bit-9 set for LBA Support, Bit-8 for DMA Support
.gap5                       resw              3  ; 50
.avail_bf                   resw              1  ; 53
.current_cyl                resw              1  ; 54
.current_hdr                resw              1  ; 55
.current_sec                resw              1  ; 56
.total_sec_obs              resd              1  ; 57
.gap6                       resw              1  ; 59
.total_sec                  resd              1  ; 60       Number of sectors when in LBA-28 mode
.gap7                       resw              1  ; 62
.dma_mode                   resw              1  ; 63
.gap8                       resw              16 ; 64
.major_ver_num              resw              1  ; 80
.minor_ver_num              resw              1  ; 81
.command_set1               resw              1  ; 82
.command_set2               resw              1  ; 83
.command_set3               resw              1  ; 84
.command_set4               resw              1  ; 85
.command_set5               resw              1  ; 86       Bit-10 is set if LBA-48 is supported
.command_set6               resw              1  ; 87
.ultra_dma_reporting        resw              1  ; 88
.gap9                       resw              11 ; 89
.lba_48_sectors             resq              1  ; 100      Number of sectors when in LBA-48 mode
.gap10                      resw              23 ; 104
.rem_media_status_notif     resw              1  ; 127
.gap11                      resw              48 ; 128
.curret_media_serial_number resw              1  ; 176
.gap12                       resw             78 ; 177
.integrity_word             resw              1  ; 255      Checksum
endstruc


ata_copy_pci_header: ; function to copy PCI header to ata_pci_header memory buffer upon finding a device with class code 0x01 and subclass 0x01
; called with every iterationof the scan of the PCI
    pushaq ; save all general purpose registers
    mov rdi,ata_pci_header ; rdi points to the ata_pci_header buffer
    mov rsi,pci_header ; rsi points to the pci_header buffer
    mov rcx, 0x20 ; initialize the counter with hexa 20 which is the equivalent of 256, 32*8 is 256
    xor rax, rax ; clear the contents of rax reg
    cld ; Clearing the direction flag
    rep stosq ; store the value of eax at effective address of RDI
    popaq ; restore all general purpose registers
ret
 

select_ata_disk:             
;function takes the channel value on rdi and master/slave indicator at rsi 
    pushaq ; save all general purpose registers
    xor rax,rax ; clear rax
    mov dx,[ata_base_io_ports+rdi] ; determining which channel will be used according to the base I/O port 
    add dx,ATA_REG_HDDEVSEL ;select the drive by dding the port offset
    mov al,byte [ata_drv_selector+rsi] ; get drive value, i.e.: master or slave
    out dx,al ; Output to port
    popaq ; restore all general purpose registers
ret

ata_print_size: ; function that prints all attributes of the ata_drive when found
; we commented out below the printing of the attributes and only print the number of LBA sectors
; to print full list of attributes, uncomment the video_print calls within the function 
    pushaq ; save general purpose registers
    mov byte [ata_identify_buffer+39],0x0 ; putting one null character 
    mov rsi, ata_identify_buffer+ATA_IDENTIFY_DEV_DUMP.serial ; now printing this null character by the following call
    ;call video_print
    mov rsi,comma ; print a comma by the next call
    ;call video_print
    mov byte [ata_identify_buffer+50],0x0 ; another null character added
    mov rsi, ata_identify_buffer+ATA_IDENTIFY_DEV_DUMP.fw_version ; Printing this null character
    ;call video_print
    mov rsi,comma ; printing another comma
    ;call video_print
    xor rdi,rdi ; clearing out rdi before printing the number of LBA sectors
    mov rdi, qword [ata_identify_buffer+ATA_IDENTIFY_DEV_DUMP.lba_48_sectors] ; Printing number of LBA Sectors
    call video_print_hexa ; calling the video printing function modified in phase 3 of the project
    mov ax, 0000010000000000b
    and ax,word [ata_identify_buffer+ATA_IDENTIFY_DEV_DUMP.command_set5] ; Checking LBA-48 bit
    cmp ax,0x0
    je .out
    mov rsi,comma
    ;call video_print
    mov rsi,lba_48_supported
    ;call video_print
    .out:
        mov rsi,newline
        call video_print

    popaq
    ret


ata_identify_disk:              ; rdi = channel, rsi = master/slave
    pushaq
       
    ; This function need to be written by you.

    xor rax,00000000b ; refresh channel
    mov dx,[ata_control_ports+rdi]
    out dx,al
    call select_ata_disk ; Select Disk to send the identify packet
    xor rax,rax ; Zero out RAX
    mov dx,[ata_base_io_ports+rdi] ; Send out zero to sector count, lba0, lba1, and lba2
    add dx,ATA_REG_SECCOUNT0
    out dx,al
    mov dx,[ata_base_io_ports+rdi]
    add dx,ATA_REG_LBA0
    out dx,al
    mov dx,[ata_base_io_ports+rdi]
    add dx,ATA_REG_LBA1
    out dx,al
    mov dx,[ata_base_io_ports+rdi]
    add dx,ATA_REG_LBA2
    out dx,al
    mov dx,[ata_base_io_ports+rdi] ; Send Identify command
    add dx,ATA_REG_COMMAND
    mov al,ATA_CMD_IDENTIFY
    out dx,al
    mov dx,[ata_base_io_ports+rdi] ; Read the status for the first time
    add dx,ATA_REG_STATUS
    in al, dx
    cmp al, 0x2
    jl .error ; Error if status is less than 2

    .check_ready: ; A loop that checks status has an error or PIO Ready
        mov dx,[ata_base_io_ports+rdi]
        add dx,ATA_REG_STATUS
        in al, dx
        xor rcx,rcx
        mov cl,ATA_SR_ERR
        and cl,al
        cmp cl,ATA_SR_ERR
        je .error
        mov cl,ATA_SR_DRQ
        and cl,al
        cmp cl,ATA_SR_DRQ
        jne .check_ready
        jmp .ready

    .error: ; Print error message and exit
        mov rsi,ata_error_msg
        call video_print
        jmp .out
    
    .ready: ; Read from base port 256 words ATA Identify Configuration Data →
        mov rsi,ata_identify_msg
        call video_print
        mov rdx,[ata_base_io_ports+rdi]
        mov si,word [ata_identify_buffer_index]
        add rdi,ata_identify_buffer
        mov rcx, 256
        xor rbx,rbx
        rep insw
        add word [ata_identify_buffer_index],256
        call ata_print_size

    .out:
    popaq
ret
