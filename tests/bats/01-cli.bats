#!/usr/bin/env bats

#
# 01 - basic behavior
#

load dex

setup(){
  [ -e $DEX ] || install_dex
}

@test "cli recognizes ping command" {
  run $DEX ping
  [ $status -eq 0 ]
  [ "$output" = "pong" ]
}

@test "cli ping accepts positional args" {
  run $DEX ping "PING" "PONG"
  [ $status -eq 0 ]
  [ "$output" = "PING PONG" ]
}

@test "cli supports runfunc" {
  run $DEX runfunc abc_is_no_function
  [ $status -eq 1 ]
  [[ "$output" == *"abc_is_no_function"* ]]
}

@test "cli normalize_flags routine supports POSIX short and long flags" {
  run $DEX runfunc normalize_flags \"\" \"-abc\"
  [ "$output" = "-a -b -c" ]

  run $DEX runfunc normalize_flags \"om\" \"-abcooutput.txt\" \"--def=jam\" \"-mz\"
  [ "$output" = "-a -b -c -o output.txt --def jam -m z" ]
}

@test "cli normalize_flags routine handles space-delimited single arguments" {
  run $DEX runfunc normalize_flags \"om\" \"-abcooutput.txt --def=jam -mz\"
  [ "$output" = "-a -b -c -o output.txt --def jam -m z" ]
}

@test "cli normalize_flags routine terminates parsing on '--'" {
  run $DEX runfunc normalize_flags \"om\" \"-abcooutput.txt --def=jam -mz -- -abcx -my \"
  [ "$output" = "-a -b -c -o output.txt --def jam -m z -- -abcx -my" ]
}

@test "cli normalize_flags_first routine prints flags before args" {
  run $DEX runfunc normalize_flags_first \"\" \"-abc command -xyz otro\"
  [ "$output" = "-a -b -c -x -y -z command otro" ]
}

@test "cli normalize_flags_first routine terminates parsing on '--'" {
  run $DEX runfunc normalize_flags_first \"\" \"-abc command -xyz otro -- -def xyz\"
  [ "$output" = "-a -b -c -x -y -z command otro -- -def xyz" ]
}
