# -------- KinGraph Makefile --------
SHELL := /bin/bash
.DEFAULT_GOAL := help

# ----- Project layout -----
FRONTEND_DIR := frontend/kingraph-web
BACKEND_DIR  := backend
BINARY_NAME  := kingraph

LINUX_ARCH   := arm64
LINUX_OS     := linux

NG_VERSION := $(shell cd $(FRONTEND_DIR) && (jq -r '.devDependencies["@angular/cli"] // .dependencies["@angular/cli"] // "unknown"' package.json 2>/dev/null | sed 's/^[\^~]//'))

# ----- Snapshot packaging (for AI review / clean zips) -----
SNAP_NAME := snapshot-$(shell date +%Y%m%d-%H%M%S)
SNAP_DIR  := .snapshots

# ----- Phony targets -----
.PHONY: all help dev-backend dev-frontend dev-npm-install dev build-backend build-backend-rpi build-frontend build fmt-lint test lint fmt clean snapshot

# ----- Default targets -----
all: build

# ----- Help -----
help:
	@echo "=== Development ==="
	@echo "  dev-backend       - Run Go backend (dev)"
	@echo "  dev-frontend      - Run Angular dev server"
	@echo ""
	@echo "=== Build ==="
	@echo "  build             - Build backend + frontend"
	@echo "  build-rpi         - Cross-compile for Raspberry Pi"
	@echo ""
	@echo "=== Quality ==="
	@echo "  test              - Run tests"
	@echo "  lint              - Run linters with --fix"
	@echo "  fmt               - Format code"
	@echo ""
	@echo "=== Maintenance ==="
	@echo "  clean             - Remove build artifacts"
	@echo "  snapshot          - Create versioned snapshot zip"

# ---------- Dev ----------
dev-backend:
	cd $(BACKEND_DIR) && \
	KIN_GRAPH_ADDR=:8080 KIN_GRAPH_ENV=dev \
	go run ./cmd/kingraph

dev-frontend: dev-npm-install
	cd $(FRONTEND_DIR) && \
	NG_APP_API_URL=http://localhost:8080 \
	npx --yes ng serve --host 0.0.0.0 --port 4200

dev-npm-install:
	cd $(FRONTEND_DIR) && npm install

dev:
	@echo "Open two terminals:"
	@echo "  Terminal A: make dev-backend   (http://localhost:8080)"
	@echo "  Terminal B: make dev-frontend  (http://localhost:4200)"
	@echo "The frontend calls the backend at http://localhost:8080 (CORS allowed in dev)."

# ---------- Build ----------
build-backend:
	cd $(BACKEND_DIR) && \
	mkdir -p bin && \
	go build -trimpath -ldflags="-s -w" -o bin/$(BINARY_NAME) ./cmd/kingraph

build-backend-rpi:
	cd $(BACKEND_DIR) && \
	mkdir -p bin && \
	CGO_ENABLED=0 GOOS=$(LINUX_OS) GOARCH=$(LINUX_ARCH) \
	go build -trimpath -ldflags="-s -w" -o bin/$(BINARY_NAME)-$(LINUX_OS)-$(LINUX_ARCH) ./cmd/kingraph

build-frontend: dev-npm-install
	cd $(FRONTEND_DIR) && \
	NG_APP_API_URL=/api \
	npx --yes ng build --configuration production

build: build-backend build-frontend

build-rpi: build-backend-rpi build-frontend

# ---------- Quality ----------
test:
	cd $(BACKEND_DIR) && go test ./...
	@echo "Tip: configure frontend unit tests (Karma/Jasmine) later."

lint:
	@which golangci-lint > /dev/null || (echo "ERROR: golangci-lint not installed. See https://golangci-lint.run/usage/install/" && exit 1)
	cd $(BACKEND_DIR) && golangci-lint run --fix ./...
	cd $(FRONTEND_DIR) && npx --yes ng lint --fix

fmt: dev-npm-install
	cd $(BACKEND_DIR) && go fmt ./... && go mod tidy
	cd $(FRONTEND_DIR) && npm run prettier:write

fmt-lint: fmt lint
# ---------- Clean ----------
clean:
	rm -rf $(BACKEND_DIR)/bin
	rm -rf $(FRONTEND_DIR)/dist
	rm -rf $(FRONTEND_DIR)/node_modules

# ---- Snapshot ----
# Creates .snapshots/<name>.zip and a JSON manifest with versions.
# Archive content is derived from Git: tracked files + untracked but non-ignored files
# (respects .gitignore via --exclude-standard).
snapshot:
	@mkdir -p $(SNAP_DIR)
	@echo "Creating manifest..."
	@printf '{\n  "timestamp": "%s",\n  "git": "%s",\n  "go_version": "%s",\n  "node_version": "%s",\n  "npm_version": "%s",\n  "ng_version": "%s"\n}\n' \
"$(shell date -u +"%Y-%m-%dT%H:%M:%SZ")" \
"$(shell git rev-parse --short=10 HEAD 2>/dev/null || echo 'no-git')" \
"$(shell go version)" \
"$(shell node --version)" \
"$(shell npm --version)" \
"$(NG_VERSION)" \
> $(SNAP_DIR)/$(SNAP_NAME)-manifest.json
	@echo "Creating archive from Git-visible files (respects .gitignore)..."
	@git ls-files --cached --others --exclude-standard -z | xargs -0 zip -q -X $(SNAP_DIR)/$(SNAP_NAME).zip
	@zip -q -j -X $(SNAP_DIR)/$(SNAP_NAME).zip $(SNAP_DIR)/$(SNAP_NAME)-manifest.json
	@rm -f $(SNAP_DIR)/$(SNAP_NAME)-manifest.json
	@echo "Snapshot written to $(SNAP_DIR)/$(SNAP_NAME).zip"