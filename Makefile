# ============================================================================
# Makefile for ASM Graphics Library
# ============================================================================
# Native macOS implementation
#
# Targets:
#   make          - Build the demo
#   make clean    - Remove build artifacts
#   make run      - Build and run the demo
# ============================================================================

# Assembler/Linker
AS = as
LD = ld

# Architecture (ARM64 for Apple Silicon)
ARCH = arm64

# Flags
ASFLAGS = -arch $(ARCH)
LDFLAGS = -arch $(ARCH) \
          -syslibroot $(shell xcrun --show-sdk-path) \
          -lSystem \
          -framework Cocoa \
          -framework CoreGraphics \
          -framework AppKit \
          -framework QuartzCore

# Directories
PLATFORM_DIR = src/platform/macos
SHARED_DIR = src/shared
INC_DIR = include
BUILD_DIR = build

# Source files
PLATFORM_SRCS = $(PLATFORM_DIR)/print.s \
                $(PLATFORM_DIR)/keyboard.s \
                $(PLATFORM_DIR)/window.s \
                $(PLATFORM_DIR)/timing.s

SHARED_SRCS = $(SHARED_DIR)/raster.s

DEMO_SRC = src/demo.s

# Object files
PLATFORM_OBJS = $(patsubst $(PLATFORM_DIR)/%.s,$(BUILD_DIR)/%.o,$(PLATFORM_SRCS))
SHARED_OBJS = $(patsubst $(SHARED_DIR)/%.s,$(BUILD_DIR)/%.o,$(SHARED_SRCS))
DEMO_OBJ = $(BUILD_DIR)/demo.o

ALL_OBJS = $(PLATFORM_OBJS) $(SHARED_OBJS) $(DEMO_OBJ)

# Output
TARGET = $(BUILD_DIR)/demo

# ============================================================================
# Targets
# ============================================================================

.PHONY: all clean run

all: $(TARGET)

$(TARGET): $(ALL_OBJS)
	@echo "Linking $(TARGET)..."
	$(LD) $(LDFLAGS) -o $@ $^
	@echo "Build complete! Run with: $(TARGET)"

# Platform-specific objects
$(BUILD_DIR)/%.o: $(PLATFORM_DIR)/%.s | $(BUILD_DIR)
	@echo "Assembling $<..."
	$(AS) $(ASFLAGS) -I$(INC_DIR) -o $@ $<

# Shared objects
$(BUILD_DIR)/%.o: $(SHARED_DIR)/%.s | $(BUILD_DIR)
	@echo "Assembling $<..."
	$(AS) $(ASFLAGS) -I$(INC_DIR) -o $@ $<

# Demo
$(BUILD_DIR)/demo.o: src/demo.s | $(BUILD_DIR)
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
# Help
# ============================================================================

help:
	@echo "ASM Graphics Library Makefile"
	@echo ""
	@echo "Native macOS implementation"
	@echo ""
	@echo "Targets:"
	@echo "  make              - Build the demo"
	@echo "  make run          - Build and run the demo"
	@echo "  make clean        - Remove build artifacts"
	@echo "  make help         - Show this help"
	@echo ""
	@echo "Controls:"
	@echo "  Arrow keys / WASD - Move the square"
	@echo "  ESC / Q           - Quit"
