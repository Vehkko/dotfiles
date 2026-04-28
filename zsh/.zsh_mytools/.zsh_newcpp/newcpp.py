#!/usr/bin/env python3
"""
newcpp: super-simple C++ project scaffold generator (hardcoded templates)

Creates (by default):
- CMakeLists.txt (generic, standardized, includes set(CMAKE_EXPORT_COMPILE_COMMANDS ON))
- .clang-format (your preferred style)
- src/main.cpp
- build/ directory

Optional:
- --git   : git init + generate .gitignore
- --conan : generate conanfile.txt (does NOT run conan)

Also supports:
- --path <dir>
- --ignore <path> (repeatable)
- --dry-run
"""

from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path
from typing import Dict, List

CLANG_FORMAT = """\
BasedOnStyle: LLVM

IndentWidth: 4
TabWidth: 4
UseTab: Never

PointerAlignment: Left
ColumnLimit: 0
NamespaceIndentation: All
AlignConsecutiveAssignments: true
AlignConsecutiveDeclarations: true
"""

GITIGNORE = """\
build*/
.cache/
compile_commands.json
*.o
*.a
*.so
*.dylib
*.dll
*.exe
*.pdb
*.obj
"""


CMAKELISTS = """\
cmake_minimum_required(VERSION 3.20)
project(@PROJECT_NAME@ LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

file(GLOB SRC_FILES
  src/*.cpp
)

# find_package(... CONFIG REQUIRED)

add_executable(@PROJECT_NAME@ ${SRC_FILES})
target_include_directories(@PROJECT_NAME@ PRIVATE ${CMAKE_SOURCE_DIR}/include)

target_compile_options(@PROJECT_NAME@ PRIVATE
  -Wall -Wextra -Wpedantic
  # -O3
  # -march=native
)

# target_link_libraries(@PROJECT_NAME@ PRIVATE ...)
"""


MAIN_CPP = """\
#include <iostream>

int main() {
    std::cout << "Hello from @PROJECT_NAME@!\\n";
    return 0;
}
"""

# Conan (Conan 2) minimal conanfile.txt; no execution, just file generation
CONANFILE_TXT = """\
# Minimal Conan (Conan 2) recipe file for CMakeToolchain + CMakeDeps
# Usage example:
#   conan install . -of build/release --build=missing -s build_type=Release
#   cmake -S . -B build/release -DCMAKE_TOOLCHAIN_FILE=build/release/conan_toolchain.cmake -DCMAKE_BUILD_TYPE=Release
#   cmake --build build/release

[requires]
# fmt/11.0.2
# spdlog/1.15.0
# eigen/3.4.0

[generators]
CMakeDeps
CMakeToolchain
"""


def normalize_relpath(p: str) -> str:
    return p.strip().lstrip("/").replace("\\", "/")


def should_ignore(rel: str, ignores: List[str]) -> bool:
    rel = normalize_relpath(rel)
    for ig in ignores:
        ig = normalize_relpath(ig)
        if not ig:
            continue
        if rel == ig:
            return True
        # If user ignores a directory, treat prefix match as ignored
        if ig.endswith("/"):
            if rel.startswith(ig):
                return True
        else:
            if rel.startswith(ig.rstrip("/") + "/"):
                return True
    return False


def write_file(path: Path, content: str, dry_run: bool) -> None:
    if dry_run:
        print(f"[dry-run] write {path}")
        return
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")


def ensure_dir(path: Path, dry_run: bool) -> None:
    if dry_run:
        print(f"[dry-run] mkdir {path}")
        return
    path.mkdir(parents=True, exist_ok=True)


def run_git_init(project_dir: Path, dry_run: bool) -> None:
    if dry_run:
        print(f"[dry-run] git init (cwd={project_dir})")
        return
    try:
        subprocess.run(["git", "init"], cwd=str(project_dir), check=True)
    except FileNotFoundError:
        print("warning: 'git' not found; skipped git init", file=sys.stderr)
    except subprocess.CalledProcessError as e:
        print(f"warning: git init failed: {e}", file=sys.stderr)


def build_template_map(
    project_name: str, with_gitignore: bool, with_conan: bool
) -> Dict[str, str]:
    def subst(s: str) -> str:
        return s.replace("@PROJECT_NAME@", project_name)

    m: Dict[str, str] = {
        "CMakeLists.txt": subst(CMAKELISTS),
        ".clang-format": CLANG_FORMAT,
        "src/main.cpp": subst(MAIN_CPP),
    }
    if with_gitignore:
        m[".gitignore"] = GITIGNORE
    if with_conan:
        m["conanfile.txt"] = CONANFILE_TXT
    return m


def parse_args(argv: List[str]) -> argparse.Namespace:
    ap = argparse.ArgumentParser(prog="newcpp", add_help=True)
    ap.add_argument(
        "name", nargs="?", default="example", help='Project name (default: "example")'
    )
    ap.add_argument(
        "--path", default=".", help='Base path to create project in (default: ".")'
    )
    ap.add_argument(
        "--git",
        action="store_true",
        help="Initialize a git repository (git init) + create .gitignore",
    )
    ap.add_argument(
        "--conan", action="store_true", help="Create conanfile.txt (does NOT run conan)"
    )
    ap.add_argument(
        "--ignore",
        action="append",
        default=[],
        help="Ignore a file/dir from template output (repeatable). Examples: --ignore .clang-format --ignore build --ignore src/main.cpp",
    )
    ap.add_argument(
        "--dry-run", action="store_true", help="Print actions without creating files"
    )
    return ap.parse_args(argv)


def main(argv: List[str]) -> int:
    args = parse_args(argv)

    project_name = (args.name or "example").strip()
    if not project_name:
        print("error: project name is empty", file=sys.stderr)
        return 2

    base_dir = Path(args.path).expanduser().resolve()
    dest_dir = (base_dir / project_name).resolve()

    if dest_dir.exists():
        print(f"error: destination already exists: {dest_dir}", file=sys.stderr)
        return 1

    ignores = list(args.ignore or [])

    # Create root directory
    if args.dry_run:
        print(f"[dry-run] mkdir {dest_dir}")
    else:
        dest_dir.mkdir(parents=True, exist_ok=False)

    # Always create build/ unless ignored
    if not (should_ignore("build", ignores) or should_ignore("build/", ignores)):
        ensure_dir(dest_dir / "build", args.dry_run)
    else:
        print("[skip] build/ (ignored)")

    # Always create include/ unless ignored
    if not (should_ignore("include", ignores) or should_ignore("include/", ignores)):
        ensure_dir(dest_dir / "include", args.dry_run)
    else:
        print("[skip] include/ (ignored)")

    template_map = build_template_map(
        project_name=project_name,
        with_gitignore=args.git,
        with_conan=args.conan,
    )

    for rel, content in template_map.items():
        if should_ignore(rel, ignores):
            print(f"[skip] {rel} (ignored)")
            continue
        write_file(dest_dir / rel, content, args.dry_run)

    if args.git and not should_ignore(".git/", ignores):
        run_git_init(dest_dir, args.dry_run)

    print(f"Created project: {dest_dir}")
    print("Next:")
    print(f"  cd {dest_dir}")
    if args.conan:
        print("  # (Conan) edit conanfile.txt, then:")
        print(
            "  # conan install . -of build/release --build=missing -s build_type=Release"
        )
        print(
            "  # cmake -S . -B build/release -DCMAKE_TOOLCHAIN_FILE=build/release/conan_toolchain.cmake -DCMAKE_BUILD_TYPE=Release"
        )
        print("  # cmake --build build/release")
    else:
        print("  cmake -S . -B build -DCMAKE_BUILD_TYPE=Release")
        print("  cmake --build build")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
