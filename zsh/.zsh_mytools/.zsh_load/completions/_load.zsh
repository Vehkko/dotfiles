#compdef load

_load() {
  local -a envs intel_comps
  envs=(intel conda local nvm) # venv spack)
  intel_comps=(all compiler mkl openmp)

  _arguments -C \
    '1:environment:->env' \
    '*:component/env:->comp'

  case $state in
    env)
      _describe -t environments 'environment' envs
      ;;
    comp)
      case $words[2] in
        intel)
          _describe -t components 'intel component' intel_comps
          ;;
        conda)
          local -a cenvs
          if (( $+commands[conda] )); then
            cenvs=(${(f)"$(conda env list 2>/dev/null | awk 'NF && $1 !~ /^#/ {print $1}')"})
          else
            cenvs=(base off enable)
          fi
          _describe -t conda-envs 'conda env' cenvs
          ;;
      esac
      ;;
  esac
}

_load
