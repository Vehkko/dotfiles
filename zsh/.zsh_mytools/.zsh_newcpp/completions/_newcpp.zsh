#compdef newcpp

_newcpp() {
  local -a ignore_items
  ignore_items=(
    "CMakeLists.txt"
    ".clang-format"
    "src/main.cpp"
    "build"
    "build/"
    "include"
    "include/"
    ".gitignore"
    "conanfile.txt"
    ".git/"
  )

  _arguments -s -S \
    '1:project name:' \
    '--path=[Base path to create project in]:directory:_directories' \
    '--git[git init + generate .gitignore]' \
    '--conan[generate conanfile.txt (does NOT run conan)]' \
    '*--ignore=[ignore a file/dir from template output (repeatable)]:ignore item:->ignore' \
    '--dry-run[print actions without creating files]' \
    '--help[show help]' \
    && return 0

  case "$state" in
    (ignore)
      _describe -t ignore_items 'ignore item' ignore_items
      ;;
  esac
}

_newcpp "$@"
