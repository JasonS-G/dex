#!/usr/bin/env bats

#
# 30 - initialization and configuration
#

load app

setup(){
  [ -e $APP ] || install_dex
  reset_vars
}

set_vars(){
  export DEX_HOME="/myhome"
  export DEX_BIN_DIR="/mybin"
  export DEX_BIN_PREFIX="my"
  export DEX_NETWORK=false
  export DEX_RUNTIME=v9000
}

reset_vars(){
  for var in ${DEX_VARS[@]}; do
    if [ $var = "DEX_HOME" ]; then
      export DEX_HOME=$TMPDIR/home/.dex
    else
      unset $var
    fi
  done
}

compare_defaults(){

  if [ $# -eq 0 ]; then
    echo "no lines passed to compare_defaults"
    return 1
  fi

  for line in $@; do
    IFS='='
    read -r var val <<< "$line"
    echo "comparing $var=$val"
    case $var in
      DEX_RUNTIME) [ $val = 'v1' ] || retval=1 ;;
      DEX_BIN_DIR) [ $val = "/usr/local/bin" ] || retval=1 ;;
      DEX_BIN_PREFIX) [ $val = "d" ] || retval=1 ;;
      DEX_HOME) ( [ $val = "$TMPDIR/home/.dex" ] || [ $val = "$HOME/.dex" ] ) || retval=1 ;;
      DEX_NAMESPACE) [ $val = 'dex/v1' ] || retval=1 ;;
      DEX_NETWORK) $val ;;
      *) echo "unrecognized var: $var" ; retval=1 ;;
    esac
  done

  return $retval
}

@test "vars prints helpful output matching our fixture" {
  diff <(cat_fixture help-vars.txt) <($APP vars --help)
  diff <(cat_fixture help-vars.txt) <($APP vars -h)
  diff <(cat_fixture help-vars.txt) <($APP help vars)
}

@test "vars prints a single variable, reflecting its default value" {
  run $APP vars DEX_BIN_DIR
  [ $status -eq 0 ]
  [ $output = "DEX_BIN_DIR=/usr/local/bin" ]
}

@test "vars exits with status code 2 on invalid configuration variable lookups" {
  run $APP vars INVALID_VAR
  [ $status -eq 2 ]
}

@test "vars prints evaluable lines matching configuration defaults" {
  run $APP vars all

  [ $status -eq 0 ]
  for line in "${lines[@]}"; do
    eval $line
  done
  compare_defaults "${lines[@]}"
}

@test "vars prints evaluable lines reflecting registration of exported configuration" {

  set_vars
  run $APP vars all

  [ $status -eq 0 ]
  for line in "${lines[@]}"; do
    eval $line
  done

  [ "$DEX_RUNTIME" = "v9000" ]
  [ "$DEX_HOME" = "/myhome" ]
  [ "$DEX_BIN_DIR" = "/mybin" ]
  [ "$DEX_BIN_PREFIX" = "my" ]
  [ "$DEX_NAMESPACE" = "dex/v9000" ]
  ! $DEX_NETWORK
}

@test "vars --defaults prints evaluable lines resetting configuration to defaults" {

  set_vars
  run $APP vars --defaults all

  [ $status -eq 0 ]
  for line in "${lines[@]}"; do
    eval $line
  done

  run $APP vars all
  compare_defaults "${lines[@]}"
}

@test "internal vars get properly initialized" {

  local ivars=( __checkouts __version __build )

  for var in ${ivars[@]}; do
    run $APP runfunc dex-vars-print $var

    var=${output%%=*}
    val=${output#*=}

    case $var in
      __checkouts) [ "$val" = "$TMPDIR/home/.dex/checkouts" ] ;;
      __build) [ "$val" = "$(git rev-parse --short HEAD)" ] ;;
      __version) [ "$val" = "$(git rev-parse --abbrev-ref HEAD)" ] ;;
      *) echo "unrecognized var \"$var\"" ; return 1 ;;
    esac
  done
}
