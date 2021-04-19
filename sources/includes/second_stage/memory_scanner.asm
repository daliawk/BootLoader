%define MEM_REGIONS_SEGMENT         0x2000
%define PTR_MEM_REGIONS_COUNT       0x1000
%define PTR_MEM_REGIONS_TABLE       0x1018
%define MEM_MAGIC_NUMBER            0x0534D4150     ;magic number = 'SMAP'           
    memory_scanner:
            pusha                                   ;Saving all general purpose registers on the stack

            mov ax,MEM_REGIONS_SEGMENT              
            mov es,ax                               ;Destination segment for the memory region information
            xor ebx,ebx                             ;Memory index starting at zero
            mov [es:PTR_MEM_REGIONS_COUNT],word 0x0 ;Use the word at address 0x2000:0x1000 as a counter to count memory regions
            mov di, PTR_MEM_REGIONS_TABLE           ;Address of memory regions table
            
            ;Scanning each memory region
            .memory_scanner_loop:
                mov edx,MEM_MAGIC_NUMBER            
                mov word [es:di+20], 0x1            ;To mark that this memory region should not be ignored (changed by function 0xe820 int 0x15 if it needs to be ignored)
                mov eax, 0xE820                     ;Function number to scan memory
                mov ecx,0x18                        ;Size of memory to use for storage
                int 0x15
                
                jc .memory_scan_failed              ;In case of an error

                cmp eax,MEM_MAGIC_NUMBER            ;eax should have the magic number unless an error occured
                jnz .memory_scan_failed 
                
                add di,0x18                         ;Increment address to next entry in memory regions table
                inc word [es:PTR_MEM_REGIONS_COUNT] ;Incrementing number of regions scanned
                cmp ebx,0x0                         ;If ebx==0, then all regions have been scanned
                jne .memory_scanner_loop            ;Scan next region

            popa                                    ;Restoring all general purpose registers from the stack
            ret
            
            .memory_scan_failed:
                mov si, memory_scan_failed_msg
                call bios_print
                call hang

                

    print_memory_regions:
            pusha
            mov ax,MEM_REGIONS_SEGMENT                  ; Set ES to 0x0000
            mov es,ax       
            xor edi,edi
            mov di,word [es:PTR_MEM_REGIONS_COUNT]
            call bios_print_hexa
            mov si,newline
            call bios_print
            mov ecx,[es:PTR_MEM_REGIONS_COUNT]
            mov si,0x1018 
            .print_memory_regions_loop:
                mov edi,dword [es:si+4]
                call bios_print_hexa_with_prefix
                mov edi,dword [es:si]
                call bios_print_hexa
                push si
                mov si,double_space
                call bios_print
                pop si

                mov edi,dword [es:si+12]
                call bios_print_hexa_with_prefix
                mov edi,dword [es:si+8]
                call bios_print_hexa

                push si
                mov si,double_space
                call bios_print
                pop si

                mov edi,dword [es:si+16]
                call bios_print_hexa_with_prefix


                push si
                mov si,newline
                call bios_print
                pop si
                add si,0x18

                dec ecx
                cmp ecx,0x0
                jne .print_memory_regions_loop
            popa
            ret