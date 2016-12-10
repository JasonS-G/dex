#!/usr/bin/env bats

#
# 50 - runtime command behavior
#

export DEX_NAMESPACE="dex/v1-tests"
load app


setup(){
  [ -e $APP ] || install_dex
  mk-imgtest
  __containers=()
}

get_containers(){
  __containers=()
  local filters="--filter=label=org.dockerland.dex.namespace=$DEX_NAMESPACE"
  for container in $(docker ps -aq $filters); do
    __containers+=( $container )
  done
}

rm_containers(){
  get_containers
  for container in ${__containers[@]}; do
    docker rm --force $container
  done
}

teardown(){
  rm -rf $TMPDIR/docker-test
  rm_containers
}

@test "run errors if it cannot find an image" {
  run $APP run imgtest/certainly-missing
  [ $status -eq 1 ]
}

@test "run automatically builds (and runs) image" {
  run $APP image --force rm imgtest/*
  run $APP run imgtest/debian
  [ $status -eq 0 ]
  [[ $output == *"built $DEX_NAMESPACE/debian"* ]]
  [[ $output == *"DEBIAN_RELEASE"* ]]
}

@test "run supports pulling from source(s)" {
  rm -rf $DEX_HOME/checkouts/
  [ ! -d $DEX_HOME/checkouts/imgtest ]

  run $APP run --pull imgtest/debian
  [ $status -eq 0 ]
  [ -d $DEX_HOME/checkouts/imgtest ]
  [[ $output == *"DEBIAN_RELEASE"* ]]
  [[ $output == *"imgtest updated"* ]]
}

@test "run supports persisting a container after it exits" {
  [ ${#__containers[@]} -eq 0 ]

  run $APP run --persist imgtest/debian
  [ $status -eq 0 ]

  get_containers
  [ ${#__containers[@]} -eq 1 ]
}

@test "run supports passing of arguments to container's command" {
  run $APP run imgtest/debian echo 'ping-pong'
  [ $status -eq 0 ]
  [ $output = "ping-pong" ]
}

@test "run returns exit code from container's command" {
  run $APP run imgtest/debian ls /no-dang-way
  [ $status -eq 2 ]
}

@test "run allows passing alternative CMD and entrypoint" {
  run $APP run --entrypoint "echo" --cmd "ping-pong" imgtest/debian
  [ $status -eq 0 ]
  [ $output = "ping-pong" ]
}

@test "run allows passing alternative UID and GID" {
  [ $($APP run --uid 1 imgtest/debian id -u) -eq 1 ]
  [ $($APP run --gid 1 imgtest/debian id -g) -eq 1 ]
}

@test "run allows passing alternative HOME and CWD" {
  rm -rf $TMPDIR/alt-home/ ; mkdir -p $TMPDIR/alt-home/abc
  [ $($APP run --workspace $TMPDIR/alt-home/ imgtest/debian ls) = "abc" ]
  [ $($APP run --home $TMPDIR/alt-home/ imgtest/debian ls /dex/home) = "abc" ]
}

@test "run allows passing alternative log-driver and persist flag" {

  get_containers
  [ ${#__containers[@]} -eq 0 ]

  run $APP run --persist --log-driver json-file imgtest/debian
  [ $status -eq 0 ]

  get_containers
  [ ${#__containers[@]} -eq 1 ]

  [ $(docker inspect --format "{{ index .HostConfig.LogConfig \"Type\" }}" ${__containers[0]}) = "json-file" ]
}
