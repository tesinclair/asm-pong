C=nasm
C_FLAGS= -felf64 -g

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
	touch build/temp.t
	mv $(OBJECTS) a.out build/

$(TARGET): $(OBJECTS)
	ld $^

$(OBJECTS): $(SOURCES)
	$(C) $(C_FLAGS) $^

clean:
	rm -rf build
