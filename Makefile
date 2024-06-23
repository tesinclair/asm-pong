CC=gcc

TARGET = main
SOURCES = src/main.s
OBJECTS = $(SOURCES:%.s=%.o)

.PHONY: clean all build

all: build

build: $(TARGET)
	mkdir build/
	mv $(OBJECTS) $(TARGET) build/

$(TARGET): $(OBJECTS)
	$(CC) -o $^ $@

$(OBJECTS): $(SOURCE)
	$(CC) -c $^ $@

clean:
	rm -rf build
