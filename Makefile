NASM=/usr/bin/nasm
DD=/bin/dd
CAT=/bin/cat
QEMU=/usr/bin/qemu-system-x86_64
BIN=./bin
IMAGES=./images
SOURCES=./sources

all: $(IMAGES)/boot_hello.flp $(IMAGES)/myos.flp

$(BIN)/boot_hello.bin: $(SOURCES)/boot_hello.asm
	$(NASM) -f bin $(SOURCES)/boot_hello.asm -o $(BIN)/boot_hello.bin

$(IMAGES)/boot_hello.flp: $(BIN)/boot_hello.bin
	$(CAT) $(BIN)/boot_hello.bin /dev/zero | $(DD) bs=512 count=2880 of=$(IMAGES)/boot_hello.flp

run_hello: $(IMAGES)/boot_hello.flp
	$(QEMU)  -drive file=$(IMAGES)/boot_hello.flp,format=raw,index=0,if=floppy

$(BIN)/first_stage.bin: $(SOURCES)/first_stage.asm $(SOURCES)/includes/first_stage/*.asm
	$(NASM) -f bin $(SOURCES)/first_stage.asm -o $(BIN)/first_stage.bin

$(BIN)/second_stage.bin: $(SOURCES)/second_stage.asm $(SOURCES)/includes/second_stage/*.asm
	$(NASM) -f bin $(SOURCES)/second_stage.asm -o $(BIN)/second_stage.bin

$(BIN)/third_stage.bin: $(SOURCES)/third_stage.asm $(SOURCES)/includes/third_stage/*.asm
	$(NASM) -f bin $(SOURCES)/third_stage.asm -o $(BIN)/third_stage.bin

$(IMAGES)/myos.flp: $(BIN)/first_stage.bin $(BIN)/second_stage.bin $(BIN)/third_stage.bin
	$(CAT) $(BIN)/first_stage.bin $(BIN)/second_stage.bin $(BIN)/third_stage.bin /dev/zero | $(DD) bs=512 count=2880 of=$(IMAGES)/myos.flp

$(IMAGES)/myos.drv: $(BIN)/first_stage.bin $(BIN)/second_stage.bin $(BIN)/third_stage.bin
	$(CAT) $(BIN)/first_stage.bin $(BIN)/second_stage.bin $(BIN)/third_stage.bin /dev/zero | $(DD) bs=512 count=61440 of=$(IMAGES)/myos.drv

run_myos: $(IMAGES)/myos.flp
	$(QEMU) -m 4096 -drive file=$(IMAGES)/myos.flp,format=raw,index=0,if=floppy -drive file=$(IMAGES)/disk0.qcow2,format=qcow2,index=0,media=disk  -drive file=$(IMAGES)/disk1.qcow2,format=qcow2,index=1,media=disk -drive file=$(IMAGES)/disk2.qcow2,format=qcow2,index=2,media=disk -drive file=$(IMAGES)/disk3.qcow2,format=qcow2,index=3,media=disk

run_myos_drv: $(IMAGES)/myos.drv
	$(QEMU) -m 4096 -drive file=$(IMAGES)/myos.drv,format=raw,index=0,media=disk -drive file=$(IMAGES)/disk0.qcow2,format=qcow2,index=1,media=disk  -drive file=$(IMAGES)/disk1.qcow2,format=qcow2,index=2,media=disk -drive file=$(IMAGES)/disk2.qcow2,format=qcow2,index=3,media=disk
clean:
	rm -rf $(BIN)/* $(IMAGES)/*.flp $(IMAGES)/*.drv
