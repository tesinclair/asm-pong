C=nasm
C_FLAGS= -felf64 -g
L_FLAGS= -lc -dynamic-linker /lib64/ld-linux-x86-64.so.2

TARGET = main
SOURCES = src/main.s
OBJECTS = $(SOURCES:%.s=%.o)

.PHONY: clean all build run
 
all: build

run: build
	echo "\n\n"
	build/a.out

build: clean $(TARGET)
	mkdir build/
	mv $(OBJECTS) a.out build/

$(TARGET): $(OBJECTS)
	ld $^ $(L_FLAGS)

$(OBJECTS): $(SOURCES)
	$(C) $(C_FLAGS) $^

clean:
	rm -rf build
