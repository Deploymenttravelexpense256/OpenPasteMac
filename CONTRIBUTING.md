# Contributing to OpenPasteMac

Thanks for your interest in contributing. Here's how to get started.

## Setup

1. Clone the repository
2. Install Xcode Command Line Tools: `xcode-select --install`
3. Run `make build` to verify everything compiles

## Development workflow

```bash
make run    # Build and launch the debug version
make build  # Just build
make clean  # Clean build artifacts
```

## Guidelines

- Keep pull requests small and focused
- Write clear commit messages
- Test your changes locally before submitting
- Open an issue first for large features or architectural changes

## Project structure

- `Sources/` — all Swift source files
- `Sources/Views/` — SwiftUI views
- `scripts/` — build and packaging scripts
- `Makefile` — common development commands

## Code style

- Swift standard conventions
- SwiftUI for views, AppKit for system integration
- No external dependencies — keep it lightweight
