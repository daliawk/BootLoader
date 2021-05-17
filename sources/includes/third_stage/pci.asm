;*******************************************************************************************************************
%define CONFIG_ADDRESS  0xcf8
%define CONFIG_DATA     0xcfc

ata_device_msg db 'Found ATA Controller',13,10,0
pci_header times 512 db 0
ata_devices db 0


struc PCI_CONF_SPACE 
.vendor_id          resw    1
.device_id          resw    1
.command            resw    1
.status             resw    1
.rev                resb    1
.prog_if            resb    1
.subclass           resb    1
.class              resb    1
.cache_line_size    resb    1
.latency            resb    1
.header_type        resb    1
.bist               resb    1
.bar0               resd    1
.bar1               resd    1
.bar2               resd    1
.bar3               resd    1
.bar4               resd    1
.bar5               resd    1
.reserved           resd    2
.int_line           resb    1
.int_pin            resb    1
.min_grant          resb    1
.max_latency        resb    1
.data               resb    192
endstruc

scan_pci_devices:
    pushaq
    mov r8, [pci_headers_address] ; Saving initial physical address

    ; Scanning first bus
    mov byte[bus], 0
    call scan_bus

    mov [pci_headers_address], r8 ; Returning the original physical address

    popaq
ret

scan_bus:
    pushaq

    mov rax, 0      ; device
    mov rbx, 0      ; function

    device_loop:    ; Looping over all devices connected to the bus
        mov byte[device], al        ; Setting the device's number

        function_loop:              ; Looping over the functions of the device

            mov byte[function], bl  ; Setting the function's number
            call get_pci_device     ; Loading the header to memory
            
            inc rbx                 ; Getting the number of the next function
            cmp rbx,8
            jne function_loop       ; If we have not scanned all functions, go to the next function

        inc rax                     ; Getting the number of the next device
        mov rbx,0x0                 ; Initializing the function number
        cmp rax,32                  ; Check if we scanned 32 devices
        jne device_loop

    popaq
ret

get_pci_device:

    pushaq
    ; Zeroing rax and rbx for use
    xor rax,rax
    xor rbx, rbx

    ;  Bit 23-16 : bus (so we shift left 16 bits))
    mov bl,[bus]
    shl ebx,16
    or eax,ebx

    ;  Bit 15-11 : device (so we shift left 11 bits))
    xor rbx,rbx 
    mov bl,[device]
    shl ebx,11
    or eax,ebx

    ; Bit 10-8 : function (so we shift left 8 bits))
    xor rbx,rbx 
    mov bl,[function]
    shl ebx,8
    or eax,ebx

    ; Bit 31 : Enable bit, and to set it we | 0x80000000
    or eax,0x80000000 

    xor rsi,rsi                     ; Zero out RSI as we will use it as an offset
    mov rcx, [pci_headers_address]  ; Address where the header will be stored

    pci_config_space_read_loop:
        mov r8, rax                 ; Saving Initial Command Register
        
        or rax,rsi                  ; Bit 7-2 : offset
        and al,0xfc                 ; Bit 1-0 : zero
        
        ; Writing to port from Command Port
        mov dx,CONFIG_ADDRESS
        out dx,eax

        ; Writing to port from Data Port
        mov dx,CONFIG_DATA
        xor rax,rax
        in eax,dx

        mov [pci_header + rsi], eax ; Storing the header in local memory
        
        cmp rsi, 0                  ; If this is the initial 4 bytes of the header, then check the device id
        jne next_iter

        cmp word[pci_header + PCI_CONF_SPACE.device_id], 0xFFFF
        je return_scanning          ; If device id is 0xFFFF then skip the device

        next_iter:
        mov [rcx+rsi], eax          ; Saving header into physical memory

        add rsi,0x4                 ; Getting the next offset
        mov rax, r8                 ; Restoring the Initial Command Register
        cmp rsi,0xff                ; Check if we have read the whole 256 Configuration Space
        jl pci_config_space_read_loop
    
    ; Incrementing the header pointer
    add rcx, 256
    mov [pci_headers_address], rcx

    inc qword[pci_headers_count]     ; Incrementing counter

    mov rsi, dot
    call video_print

    ; Checking if it is a bridge
    cmp byte[pci_header + PCI_CONF_SPACE.header_type], 0x1
    jne check_ata             ; If header type is 1, then scan the bus connected to this bridge

    ; Getting the secondary bus number to scan it
    mov bl, [bus]
    mov al, byte[pci_header + 25]
    mov byte[bus], al

    call scan_bus

    mov [bus], bl               ; Returning to the previos bus
    jmp return_scanning

    check_ata:                  ; Checking if the device is ata
        ; Checking class
        cmp byte[pci_header + PCI_CONF_SPACE.class], 1
        jne return_scanning

        ; Checking sub-class
        cmp byte[pci_header + PCI_CONF_SPACE.subclass], 1
        jne return_scanning

        call ata_copy_pci_header
    
    return_scanning:
    popaq
ret
