# Makefile para micro-os-boot

ASM = nasm
SRC = src/boot.asm
OUT = build/boot.bin

.PHONY: all clean

all: $(OUT)

$(OUT): $(SRC)
	$(ASM) -f bin -o $(OUT) $(SRC)

clean:
	rm -f build/*.bin build/*.o
