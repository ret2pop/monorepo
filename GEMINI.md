# GEMINI.md - Your AI Assistant's Guide to this Project

This file provides context for the Gemini AI assistant to understand and effectively work with this project.

## Directory Overview

This project is a personal knowledge base, often referred to as a "digital garden" or "second brain." It is primarily composed of Org mode (`.org`) files, which are used for note-taking, project planning, and authoring content. The directory is structured to organize different types of information, from a personal blog and journal to a mind map of interconnected ideas.

## Key Directories and Files

*   `./`: The root directory contains personal pages like `about.org`, `resume.org`, and an `index.org` file that likely serves as the main entry point.
*   `blog/`: This directory contains a series of articles written in Org mode, which are likely published as a personal blog.
*   `config/`: This directory holds configuration files for various tools, primarily centered around Emacs (`emacs.el`, `emacs.org`) and other development tools like `nix.org` and `qtile.org`.
*   `journal/`: This directory contains daily journal entries, with filenames corresponding to dates (e.g., `20240101.org`).
*   `mindmap/`: This is a collection of interconnected notes on various topics, forming a personal wiki or knowledge graph. The files are interlinked, creating a web of knowledge.
*   `style.css`: This file defines the visual style for the HTML exports of the Org mode files.

## Usage and Conventions

*   **Format:** The primary format is Org mode. Content is written in plain text with Org mode syntax for structure and formatting.
*   **Editing:** The files are intended to be edited with a text editor that supports Org mode, with Emacs being the canonical choice.
*   **Exporting:** The Org mode files are likely exported to HTML for viewing in a web browser. The `#+html_head` directives in the files indicate that they are set up for this.
*   **Interlinking:** The notes, especially in the `mindmap/` directory, are heavily interlinked using Org mode's linking features (e.g., `[[id:...][...]]`). This is a key feature of the knowledge base.
