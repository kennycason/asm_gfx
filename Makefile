# ============================================================================
# Makefile for ASM Graphics Library
# ============================================================================
# Targets:
#   make          - Build the demo
#   make clean    - Remove build artifacts
#   make run      - Build and run the demo
#   make install-sdl - Install SDL2 via Homebrew
# ============================================================================

# Compiler/Assembler settings
AS = as
LD = ld
CC = clang

# Detect architecture
ARCH := $(shell uname -m)
ifeq ($(ARCH),arm64)
    ASFLAGS = -arch arm64
    LDFLAGS = -arch arm64 -syslibroot $(shell xcrun --show-sdk-path) -lSystem -lSDL2 -L/opt/homebrew/lib -framework CoreFoundation -framework CoreGraphics
else
    ASFLAGS = -arch x86_64
    LDFLAGS = -arch x86_64 -syslibroot $(shell xcrun --show-sdk-path) -lSystem -lSDL2 -L/usr/local/lib -framework CoreGraphics
endif

# SDL2 include path
SDL2_INCLUDE = $(shell sdl2-config --cflags 2>/dev/null || echo "-I/opt/homebrew/include/SDL2")

# Directories
SRC_DIR = src
LIB_DIR = src/lib
INC_DIR = include
BUILD_DIR = build

# Source files
LIB_SRCS = $(LIB_DIR)/print.s $(LIB_DIR)/window.s $(LIB_DIR)/events.s $(LIB_DIR)/raster.s $(LIB_DIR)/keyboard.s
DEMO_SRC = $(SRC_DIR)/demo.s

# Object files
LIB_OBJS = $(patsubst $(LIB_DIR)/%.s,$(BUILD_DIR)/%.o,$(LIB_SRCS))
DEMO_OBJ = $(BUILD_DIR)/demo.o

# Output
TARGET = $(BUILD_DIR)/demo

# ============================================================================
# Targets
# ============================================================================

.PHONY: all clean run install-sdl check-sdl

all: check-sdl $(TARGET)

$(TARGET): $(LIB_OBJS) $(DEMO_OBJ)
	@echo "Linking $(TARGET)..."
	$(LD) $(LDFLAGS) -o $@ $^
	@echo "Build complete! Run with: $(TARGET)"

$(BUILD_DIR)/%.o: $(LIB_DIR)/%.s | $(BUILD_DIR)
	@echo "Assembling $<..."
	$(AS) $(ASFLAGS) -I$(INC_DIR) -o $@ $<

$(BUILD_DIR)/demo.o: $(SRC_DIR)/demo.s | $(BUILD_DIR)
	@echo "Assembling $<..."
	$(AS) $(ASFLAGS) -I$(INC_DIR) -o $@ $<

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

clean:
	rm -rf $(BUILD_DIR)
	@echo "Cleaned build directory."

run: all
	@echo "Running demo..."
	@$(TARGET)

# ============================================================================
# SDL2 Installation
# ============================================================================

check-sdl:
	@which sdl2-config > /dev/null 2>&1 || (echo "SDL2 not found! Run: make install-sdl" && exit 1)

install-sdl:
	@echo "Installing SDL2 via Homebrew..."
	brew install sdl2
	@echo "SDL2 installed successfully!"

# ============================================================================
# Help
# ============================================================================

help:
	@echo "ASM Graphics Library Makefile"
	@echo ""
	@echo "Targets:"
	@echo "  make              - Build the demo"
	@echo "  make run          - Build and run the demo"
	@echo "  make clean        - Remove build artifacts"
	@echo "  make install-sdl  - Install SDL2 via Homebrew"
	@echo "  make help         - Show this help"
	@echo ""
	@echo "Controls:"
	@echo "  Arrow keys        - Move the square"
	@echo "  ESC               - Quit"

