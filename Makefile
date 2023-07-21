SHELL := /bin/bash

.SILENT: word_count macos_deps ubuntu_deps clean venv fetch markdown epub mobi pdf

all: clean venv fetch markdown epub mobi pdf

clean:
		@echo "🗑 Cleaning up the room..."
		rm -rf essays/ .venv/ graham.epub graham.md graham.mobi graham.pdf; true

word_count:
		wc -w essays/* | sort -n

venv:
		@echo "🐍 Creating a safe place for a Python..."
		python3 -m venv .venv
		source "./.venv/bin/activate"
		pip3 install --upgrade pip
		pip3 install -r requirements.txt

macos_deps:
		brew install python@3
		brew install --build-from-source pandoc
		brew install --cask calibre

ubuntu_deps:
		sudo apt install --yes pandoc
		sudo apt install --yes calibre
		pip install --upgrade chardet

fetch:
		@echo "🧠 Downloading Paul Graham mind..."
		mkdir essays
		python3 graham.py

markdown:
		@echo "📒 Binding Markdown..."
		pandoc essays/*.md -o graham.md -f markdown_strict
		@echo "🎉 MD file created."

epub:
		${markdown}
		@echo "📒 Binding EPUB..."
		pandoc essays/*.md -o graham.epub -f markdown_strict --metadata-file=metadata.yaml --toc --toc-depth=1 --epub-cover-image=cover.png
		@echo "🎉 EPUB file created."

mobi:
		${epub}
		@echo "📒 Binding MOBI..."
		ebook-convert graham.epub graham.mobi
		@echo "🎉 MOBI file created."

pdf:
		${epub}
		@echo "📒 Binding PDF..."
		ebook-convert graham.epub graham.pdf
		@echo "🎉 PDF file created."
