#!/usr/bin/env bats

#
# 70 - test command after-effects
#

load app

export DEX_NAMESPACE="dex/v1-tests"
export DEX_BIN_DIR=$TMPDIR/usr/local/bin/installs

setup(){
  [ -e $APP ] || install_dex
  [ -d $DEX_BIN_DIR ] || mkdir -p $DEX_BIN_DIR
  mk-imgtest
}

teardown(){
  chmod 755 $DEX_BIN_DIR
  rm -rf $DEX_BIN_DIR
}

imgcount(){
  echo $(ls -1 $DEX_BIN_DIR | wc -l)
}

@test "install errors if it cannot write(126)|access(127) DEX_BIN_DIR" {

  chmod 000 $DEX_BIN_DIR
  run $APP install imgtest/alpine
  [ $status -eq 126 ]

  chmod 755 $DEX_BIN_DIR && rm -rf $DEX_BIN_DIR
  run $APP install imgtest/alpine
  [ $status -eq 127 ]
}

@test "install errors if it cannot match any image(s)" {
  run $APP install imgtest/certainly-missing
  [ $status -eq 2 ]
}

@test "install adds tagged runtime to DEX_BIN_DIR and a prefixed link to it" {
  [ $(imgcount) -eq 0 ]
  eval $($APP vars DEX_BIN_PREFIX)

  run $APP install imgtest/alpine:latest

  [ $status -eq 0 ]
  [ $(imgcount) -eq 2 ]
  [ -e $DEX_BIN_DIR/${DEX_BIN_PREFIX}alpine-latest ]
  [ -L $DEX_BIN_DIR/${DEX_BIN_PREFIX}alpine ]
}

@test "install writes _behaving dexecutables_ to DEX_BIN_DIR"  {

  export TMPDIR=$TMPDIR
  mkdir -p $TMPDIR/label-test/{home,vol,workspace}

  eval $($APP vars DEX_BIN_PREFIX)
  run $APP install imgtest/labels

  [ $status -eq 0 ]
  [ -x $DEX_BIN_DIR/${DEX_BIN_PREFIX}labels ]

  run $DEX_BIN_DIR/${DEX_BIN_PREFIX}labels
  [[ $output == *"DEBIAN_RELEASE"* ]]

  output=$(echo "foo" | $DEX_BIN_DIR/${DEX_BIN_PREFIX}labels sed 's/foo/bar/')
  [ $? -eq 0 ]
  [ "$output" = "bar" ]
}

@test "install adds matching images to DEX_BIN_DIR" {
  [ $(imgcount) -eq 0 ]

  local repo_image_count=$(ls -ld $DEX_HOME/checkouts/imgtest/dex-images/* | wc -l)

  run $APP install imgtest/*
  [ $status -eq 0 ]
  [ $(imgcount) -eq $(($repo_image_count + $repo_image_count)) ]
}

@test "install adds symlink to runtime script when --global flag is passed" {
  eval $($APP vars DEX_BIN_PREFIX)
  run $APP install --global imgtest/alpine

  [ $status -eq 0 ]
  [ -e $DEX_BIN_DIR/${DEX_BIN_PREFIX}alpine ]
  [ -L $DEX_BIN_DIR/alpine ]
}

@test "install will not overwrite existing files, except when --force is passed" {

  eval $($APP vars DEX_BIN_PREFIX)
  touch $DEX_BIN_DIR/${DEX_BIN_PREFIX}alpine
  touch $DEX_BIN_DIR/alpine

  run $APP install --global imgtest/alpine
  [[ $output = *"$DEX_BIN_DIR/${DEX_BIN_PREFIX}alpine exists"* ]]
  [[ $output = *"skipped linking alpine to ${DEX_BIN_PREFIX}alpine-latest"* ]]

  run $APP install --global --force imgtest/alpine
  [ -L $DEX_BIN_DIR/dalpine ]
  [ -L $DEX_BIN_DIR/alpine ]
}


#@TODO test label failures, e.g. when org.dockerland.dex.api is missing
