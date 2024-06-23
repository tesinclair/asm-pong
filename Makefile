C=nasm
C_FLAGS= -felf64

TARGET = main
SOURCES = src/main.s
OBJECTS = $(SOURCES:%.s=%.o)

.PHONY: clean all build

all: build

build: $(TARGET)
	mkdir build/
	mv $(OBJECTS) a.out build/

$(TARGET): $(OBJECTS)
	ld $^

$(OBJECTS): $(SOURCES)
	$(C) $(C_FLAGS) $^

clean:
	rm -rf build
