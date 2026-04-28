# ~/.zsh_load/envs/local.zsh

_load_local() {
  export PATH="$HOME/opt/bin:$PATH"
  export LD_LIBRARY_PATH="$HOME/opt/lib:$LD_LIBRARY_PATH"
  export CMAKE_PREFIX_PATH="$HOME/opt:$CMAKE_PREFIX_PATH"
  export PKG_CONFIG_PATH="$HOME/opt/lib/pkgconfig:$PKG_CONFIG_PATH"
}
