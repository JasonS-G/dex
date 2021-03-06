main_conf(){
  local operand
  local list=()

  [ $# -eq 0 ] && die/help 1

  args/normalize_flags_first "" "$@"
  set -- "${__argv[@]}"
  while [ $# -ne 0 ]; do
    case "$1" in
      -h|--help)
        die/help ;;
      -d|--defaults)
        dex/conf-reset ;;
      --)
        shift ; list=( "$@" ) ; break ;;
      -*)
        args/unknown "$1" "flag" ;;
      vars)
        operand="dex/conf-print" ;;
      *)
        args/unknown "$1" ;;
    esac
    shift
  done
  shell/execfn "$operand" "${list[@]}"
}

dex/conf-init(){
  DEX_HOME="${DEX_HOME:-$HOME/.dex}"
  DEX_RUNTIME="${DEX_RUNTIME:-v1}"
  DEX_BIN_DIR="${DEX_BIN_DIR:-$DEX_HOME/bin}"
  DEX_BIN_PREFIX="${DEX_BIN_PREFIX:-d}"
  DEX_NAMESPACE="${DEX_NAMESPACE:-dex/$DEX_RUNTIME}"
  DEX_NETWORK=${DEX_NETWORK:-true}
  DEX_REGISTRY="${DEX_NETWORK:-dexbuilds/}"

  # ensure DEX_HOME is absolute
  is/absolute "$DEX_HOME" || DEX_HOME="$(pwd)/$DEX_HOME"

  # bootstrap internal vars
  __checkouts="$DEX_HOME/checkouts"
  __sources="$DEX_HOME/sources.list"
  __sources_url="${DEX_SOURCES_URL:-https://raw.githubusercontent.com/dockerland/dex/master/${DEX_RUNTIME}-sources.list}"

  __build_callback=
  __defaults=false
  __format=
  __force=false
  __pull=false
  __pulled_repos=()

  mkdir -p $__checkouts || die/perms "unable to create DEX_HOME - $__checkouts"

  # seed sources list if it's missing
  [ -e "$__sources" ]  || {
    __force=true dex/repo-reset
    __force=true dex/repo-pull
  }
}

dex/conf-print(){
  [ -n "$1" ] || set -- ${!DEX_*}
  local var

  p/comment \
    "DEX_BIN_DIR: installation location (add this to your PATH)" \
    "DEX_BIN_PREFIX: installation prefix. Not applied on 'global' installs." \
    "DEX_HOME: user workspace where checkouts and image homes are stored" \
    "DEX_NAMESPACE: tag prefix used by dex images" \
    "DEX_NETWORK: enables network fetching" \
    "DEX_REGISTRY: default registry prefix used when pulling pre-built images" \
    "DEX_RUNTIME: runtime api version"

    for var; do
      eval "shell/evaluable_export \"$var\" \"\$$var\""
    done

    shell/evaluable_entrypoint
}

dex/conf-reset(){
  local var
  for var in "${!DEX_*}"; do
    unset $var
  done

  dex/conf-init
}
