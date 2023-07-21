SHELL := /bin/bash
SRC_DIR := essays
OUT_DIR := build

.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

all: $(OUT_DIR) ## Fetches all the essays and creates books in various file formats

$(OUT_DIR): $(SRC_DIR)/%.md $(OUT_DIR)/%.md $(OUT_DIR)/%.epub $(OUT_DIR)/%.mobi $(OUT_DIR)/%.pdf

$(SRC_DIR)/%.md: ## Fetches all the essays as Markdown files and creates a CSV index
	@echo "⬇️ Downloading essays..."
	python3 graham.py
	@echo "🎉 Essays and CSV file created."

$(OUT_DIR)/%.md: $(SRC_DIR)/%.md ## Creates a Markdown book of the essays
	@echo "📒 Binding Markdown..."
	pandoc essays/*.md -o graham.md -f markdown_strict
	@echo "🎉 MD file created."

$(OUT_DIR)/%.epub: $(SRC_DIR)/%.md ## Creates an EPUB book of the essays
	@echo "📒 Binding EPUB..."
	pandoc essays/*.md -o graham.epub -f markdown_strict --metadata-file=metadata.yaml --toc --toc-depth=1 --epub-cover-image=cover.png
	@echo "🎉 EPUB file created."

$(OUT_DIR)/%.mobi: $(OUT_DIR)/%.epub ## Creates a MOBI book of the essays
	@echo "📒 Binding MOBI..."
	ebook-convert graham.epub graham.mobi
	@echo "🎉 MOBI file created."

$(OUT_DIR)/%.pdf: $(OUT_DIR)/%.epub ## Creates a PDF book of the essays
	@echo "📒 Binding PDF..."
	ebook-convert graham.epub graham.pdf
	@echo "🎉 PDF file created."

.venv: ## Creates a virtual environment for Python and installs dependencies
	python3 -m venv .venv
	source "./.venv/bin/activate"
	pip3 install --upgrade pip
	pip3 install -r requirements.txt

.PHONY: macos_deps
macos_deps: ## Installs macOS dependencies
	brew install python@3
	brew install --build-from-source pandoc
	brew install --cask calibre

.PHONY: ubuntu_deps
ubuntu_deps: ## Installs Ubuntu dependencies
	sudo apt install --yes pandoc
	sudo apt install --yes calibre
	pip install --upgrade chardet

.PHONY: clean
clean: ## Clean all generated files and Python virtual environment
	rm -rf .venv/ essays/* essays.csv build/*

.PHONY: word_count
word_count: ## Count words of all essays
	@wc -w essays/* | sort --numeric-sort
