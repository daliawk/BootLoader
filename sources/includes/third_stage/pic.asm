%define MASTER_PIC_COMMAND_PORT     0x20
%define SLAVE_PIC_COMMAND_PORT      0xA0
%define MASTER_PIC_DATA_PORT        0x21
%define SLAVE_PIC_DATA_PORT         0xA1


configure_pic:
    pushaq
                  ; This function need to be written by you.
    mov al,11111111b
    ; Disabling PIC by basically masking all the IRQs
    out MASTER_PIC_DATA_PORT,al
    out SLAVE_PIC_DATA_PORT,al
    mov al,00010001b
    ; Set ICW1 with bit0: expect ICW4, bit4: initialization bit
    out MASTER_PIC_COMMAND_PORT,al
    out SLAVE_PIC_COMMAND_PORT,al
    ; Since we sent ICW1 to the Command port we need to write ICW2-4 to the Data Port
    ; ICW2 for mapping interrupts, which interrupt number should the controller starts at
    mov al,0x20
    ; start with interrupt 32 on master
    out MASTER_PIC_DATA_PORT,al
    mov al,0x28
    ; start interrupt 40 on slave
    out SLAVE_PIC_DATA_PORT,al
    ; ICW3 for cascading communication. Define the pins that the master and the salve will communicate over
    mov al,00000100b
    ; IRQ2 on the master
    out MASTER_PIC_DATA_PORT,al
    mov al,00000010b
    ; Tells the slave the IRQ that the master is on,IRQ2
    out SLAVE_PIC_DATA_PORT,al
    ; ICW4 to set 80x86 mode
    mov al,00000001b
    ; bit0 sets 80x86 mode
    out MASTER_PIC_DATA_PORT,al
    out SLAVE_PIC_DATA_PORT,al
    mov al,0x0
    ; Unmask all IRQs
    out MASTER_PIC_DATA_PORT,al
    out SLAVE_PIC_DATA_PORT,al

    popaq
ret


set_irq_mask:
    pushaq                              ;Save general purpose registers on the stack
    ; This function need to be written by you.

    mov rdx,MASTER_PIC_DATA_PORT ; Use the master data port
    cmp rdi,15 ; If the IRQ is larger than 15 get out
    jg .out
    cmp rdi,8 ; Else if the interrupt number is less than 8 then it is on the master
    jl .master
    sub rdi,8 ; Else subtract 8 from the port number to make it relative to the slave
    mov rdx,SLAVE_PIC_DATA_PORT ; Use the slave data port
    .master: ; If we are here we know which port we are going to use and the IRQ is set right
        in eax,dx ; Read the IMR into eax
        mov rcx,rdi ; Move rdi to rcx
        mov rdi,0x1 ; Move 0x1 to rdi
        shl rdi,cl ; Shift left the value in rdi with IRQ value
        or rax,rdi ; Move back rdi to rax
        out dx,eax ; Write to the data port to save the IMR with the new mask
    .out:
        popaq
ret


clear_irq_mask:
    pushaq
    ; This function need to be written by you.
    mov rdx,MASTER_PIC_DATA_PORT ; Use the master data port
    cmp rdi,15 ; If the IRQ is larger than 15 get out
    jg .out
    cmp rdi,8 ; Else if the interrupt number is less than 8 then it is on the master
    jl .master
    sub rdi,8 ; Else subtract 8 from the port number to make it relative to the slave
    mov rdx,SLAVE_PIC_DATA_PORT ; Use the slave data port
    .master: ; If we are here we know which port we are going to use and the IRQ is set right
        in eax,dx ; Read the IMR into eax
        mov rcx,rdi ; Move rdi to rcx
        mov rdi,0x1 ; Move 0x1 to rdi
        shl rdi,cl ; Shift left the value in rdi with IRQ value
        not rdi     ; Making all bits 1 with the exception of the bit we want to clear 
        and rax,rdi ; Clearing the wanted bit
        out dx,eax ; Write to the data port to save the IMR with the new mask

    .out:  
    popaq
ret
