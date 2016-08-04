#
# lib.d/display_help.sh for dex -*- shell-script -*-
#

display_help_image(){
  cat <<-EOF

Piping hot docker executables to your door.

"dexecutables" are images built and executed from Dockerfiles and scripts
contained in git "source repositories" and manged by 'dex remote'.

Source repositories are defined in $DEX_HOME/sources.list
  (typically ~/.dex/sources.list), one per line, and space delimited (name url).

Removing or adding repositories will not effect built images, allowing
installed dexecutables to function as normal.

Usage: dex remote <command> [options]

  # Add an additional dexecutable source repository named "extras"
  dex remote add extras git@github.com:dockerland/dex-dockerfiles-extra.git

Commands:

  add <name> <url>       Add (and pulls) a dexecutable source repository.
  pull <name|url>        Pull (refresh) source repository matching name || url
  rm <name|url>          Remove source repository matching name || url.
  ls                     List available source repositories

Options:

  -h|--help|help        Display help

  -f|--force            When pulling, discard any working copy changes
                        When adding, first remove any matching name || url

EOF
}
