# MediCloudX Data Exporter - Makefile
# Healthcare Records Export Tool

CC=gcc
CFLAGS=-Wall -Wextra -std=c99 -O2 -I/opt/homebrew/include
LDFLAGS=-lcurl -lssl -lcrypto -L/opt/homebrew/lib
TARGET=medicloudx_exporter
SOURCE=medicloudx_exporter.c

# AWS Credentials (can be overridden)
AWS_ACCESS_KEY_ID ?= PLACEHOLDER_ACCESS_KEY
AWS_SECRET_ACCESS_KEY ?= PLACEHOLDER_SECRET_KEY

# Default target
all: $(TARGET)

# Build the medical records exporter
$(TARGET): $(SOURCE)
	@echo "Building MediCloudX Data Exporter..."
	@echo "Compiler: $(CC)"
	@echo "Flags: $(CFLAGS)"
	@echo "Injecting AWS credentials..."
	$(CC) $(CFLAGS) -DAWS_ACCESS_KEY_ID='"$(AWS_ACCESS_KEY_ID)"' -DAWS_SECRET_ACCESS_KEY='"$(AWS_SECRET_ACCESS_KEY)"' -o $(TARGET) $(SOURCE) $(LDFLAGS)
	@echo "Build complete: $(TARGET)"
	@echo ""
	@echo "Usage:"
	@echo "  ./$(TARGET) --version"
	@echo "  ./$(TARGET) --bucket <bucket_suffix>"

# Build with debug symbols
debug: CFLAGS += -g -DDEBUG
debug: $(TARGET)

# Build statically linked binary (for distribution)
static: LDFLAGS += -static
static: $(TARGET)

# Build for Linux (using Docker)
linux:
	@echo "Building for Linux using Docker..."
	docker build -t medicloudx-builder .
	docker create --name temp-container medicloudx-builder
	docker cp temp-container:/build/$(TARGET) ./$(TARGET)_linux
	docker rm temp-container
	@echo "Linux binary created: $(TARGET)_linux"

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	rm -f $(TARGET)
	@echo "Clean complete."

# Install system dependencies (Ubuntu/Debian)
deps-ubuntu:
	sudo apt-get update
	sudo apt-get install -y libcurl4-openssl-dev gcc make

# Install system dependencies (macOS)
deps-macos:
	brew install curl

# Create distribution package
dist: clean static
	@echo "Creating distribution package..."
	mkdir -p dist
	cp $(TARGET) dist/
	cp README.md dist/ 2>/dev/null || true
	@echo "Distribution ready in dist/"

# Show binary information
info: $(TARGET)
	@echo "Binary Information:"
	@echo "===================="
	file $(TARGET)
	@echo ""
	@echo "Size:"
	ls -lh $(TARGET)
	@echo ""
	@echo "Dependencies:"
	ldd $(TARGET) 2>/dev/null || otool -L $(TARGET) 2>/dev/null || echo "Static binary"

# Test the binary
test: $(TARGET)
	@echo "Testing binary..."
	./$(TARGET) --version

.PHONY: all debug static clean deps-ubuntu deps-macos dist info test
