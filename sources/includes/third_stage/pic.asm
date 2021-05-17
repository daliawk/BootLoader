%define MASTER_PIC_COMMAND_PORT     0x20
%define SLAVE_PIC_COMMAND_PORT      0xA0
%define MASTER_PIC_DATA_PORT        0x21
%define SLAVE_PIC_DATA_PORT         0xA1


configure_pic:
; This routine is written so that we can configure the pick by initiallizing the 4 ICW

    pushaq                                          ; pushing all the general purpose registers to the stack

    ; Disabling PIC
    mov al,11111111b                                ; Disabling PIC by basically all the IRQs
    out MASTER_PIC_DATA_PORT,al                     ; Write 1's to all the master data port
    out SLAVE_PIC_DATA_PORT,al                      ; and the slave datta port to disable it
;=================================================================================================

    ; Setting ICW1
    mov al,00010001b                                
    ; least significant bit (0) is is to expect ICW4
    ; fifth bit (bit number 4) is the initiallization bit
    out MASTER_PIC_COMMAND_PORT,al                  ; writing al to the master command port
    out SLAVE_PIC_COMMAND_PORT,al                   ; writing al to the slave command port
;=================================================================================================

    ; setting ICW2
    mov al,0x20                                     ; setting al with 32, the interrupt on master
    out MASTER_PIC_DATA_PORT,al                     ; writing al to the master data port

    mov al,0x28                                     ; setting al with 32, the interrupt on slave
    out SLAVE_PIC_DATA_PORT,al                      ; writing al to the slave data port
;=================================================================================================

    ; Setting ICW3
    mov al,00000100b                                ; putting al the IRQ2 on the master
    out MASTER_PIC_DATA_PORT,al                     ; writing al to the master data port
    mov al,00000010b                                ; Tells the slave the IRQ that the master is on,IRQ2
    out SLAVE_PIC_DATA_PORT,al                      ; writing al to the slave data port
;=================================================================================================

    ; setting ICW4
    mov al,00000001b                                ; setting least significant bit to one to be on 80x86 mode
    out MASTER_PIC_DATA_PORT,al                     ; writing al to the master data port
    out SLAVE_PIC_DATA_PORT,al                      ; writing al to the slave data port
;=================================================================================================

    mov al,0x0                                      ; Unmasking all IRQs
    out MASTER_PIC_DATA_PORT,al                     ; writing al to the master data port
    out SLAVE_PIC_DATA_PORT,al                      ; writing al to the slave data port
;=================================================================================================

    popaq                                           ; popping all the general purpose registers to the stack
ret


set_irq_mask:
; this subroutine sets the IRQ mask
    pushaq                                          ; pushing all the general purpose registers to the stack

    mov rdx,MASTER_PIC_DATA_PORT                    ; Use the master data port
    cmp rdi,15                                      ; If the IRQ is larger than 15 get out
    jg .out                                         ; else continue executing the function
    cmp rdi,8                                       ; if the interrupt number is less than 8 then it is on the master
    jl .master                                      ; else continue executing
    sub rdi,8                                       ; subtract 8 from the port number to make it relative to the slave
    mov rdx,SLAVE_PIC_DATA_PORT                     ; Use the slave data port
    .master: 
    ; this subroutine executes only if we are on the master
        in eax,dx                                   ; Read the IMR into eax
        mov rcx,rdi                                 ; Move rdi to rcx
        mov rdi,0x1                                 ; Move 0x1 to rdi
        shl rdi,cl                                  ; Shift left the value in rdi with IRQ value
        or rax,rdi                                  ; Move back rdi to rax
        out dx,eax                                  ; Write to the data port to save the IMR with the new mask
    .out:
        popaq                                       ; popping all the general purpose registers to the stack
ret


clear_irq_mask:
; this subroutine clears the IRQ mask
    pushaq                                          ; pushing all the general purpose registers to the stack

    mov rdx,MASTER_PIC_DATA_PORT                    ; Use the master data port
    cmp rdi,15                                      ; If the IRQ is larger than 15 get out
    jg .out                                         ; else continue executing the function
    cmp rdi,8                                       ; if the interrupt number is less than 8 then it is on the master
    jl .master                                      ; else continue executing
    sub rdi,8                                       ; subtract 8 from the port number to make it relative to the slave
    mov rdx,SLAVE_PIC_DATA_PORT                     ; Use the slave data port
    .master: 
    ; this subroutine executes only if we are on the master
        in eax,dx                                   ; Read the IMR into eax
        mov rcx,rdi                                 ; Move rdi to rcx
        mov rdi,0x1                                 ; Move 0x1 to rdi
        shl rdi,cl                                  ; Shift left the value in rdi with IRQ value
        not rdi                                     ; Making all bits 1 with the exception of the bit we want to clear 
        and rax,rdi                                 ; Clearing the wanted bit
        out dx,eax                                  ; Write to the data port to save the IMR with the new mask

    .out:  
    popaq                                           ; popping all the general purpose registers to the stack
ret
