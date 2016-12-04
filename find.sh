# dex helpers

dex/find-dockerfiles(){
  local repo
  local image
  local tag
  IFS="/:" read repo image tag <<< "$(dex/find-repostr $1)"

  local found=false
  local search_image
  local search_repo

  for search_repo in $(__format="\$name" dex/repo-ls $repo); do
    if [ -n "$image" ]; then
      local path="$__checkouts/$search_repo/dex-images/$image"
      find/dockerfiles "$path" "${tag:-latest}" || continue
      found=true
    else
      for search_image in $(find/dirs "$__checkouts/$search_repo/dex-images"); do
        local path="$__checkouts/$search_repo/dex-images/$search_image"
        find/dockerfiles "$path" || continue
        found=true
      done
    fi
  done

  $found && return 0
  return 127
}

# return first found built image matching repostr
dex/find-image(){
  local repo
  local image
  local tag
  IFS="/:" read repo image tag <<< "$(dex/find-repostr $1)"

  [ -z "$image" ] && return 2

  local flags=(
    "-q"
    "--filter \"dangling=false\""
    "--filter \"label=org.dockerland.dex.namespace=$DEX_NAMESPACE\""
    "--filter \"label=org.dockerland.dex.image=$image\""
  )

  [ -n "$repo" ] && flags+=( "--filter=\"label=org.dockerland.dex.repo=$repo\"" )
  [ -n "$tag" ] && flags+=( "--filter=\"label=org.dockerland.dex.repo=$tag\"" )

  docker/local images ${flags[@]} | head -n1
}

# normalizes a repostr
dex/find-repostr(){
  local repostr="$1"
  local imagestr
  local repo
  local image
  local tag
  local junk

  IFS="/" read repo imagestr junk <<< "$repostr"

  [ -n "$junk" ] && {
    io/warn "malformed repostr $repostr"
    return 2
  }

  [[ -z "$imagestr" && "$repostr" != "$repo/" ]] && {
    # no repo was specified.
    imagestr="$repo"
    repo=
  }

  IFS=":" read image tag junk <<< "$imagestr"

  [ -n "$junk" ] && {
    io/warn "malformed imagestr $imagestr"
    return 2
  }

  echo "$repo/$image:$tag"
}

# given a Dockerfile path in checkouts, print a fully qualified repostr
dex/find-repostr-from-dockerfile(){
  local Dockerfile="$1"
  local tag=$(find/dockerfile-tag $Dockerfile)
  local repo=${Dockerfile//$__checkouts\//}
  repo=${repo%%/*}
  local image=${Dockerfile//$__checkouts\/$repo\/dex-images\//}
  image=${image%%/*}

  [[ -z "$repo" || -z "$image" || -z "$tag" ]] && {
    io/warn "failed determining repostr from $Dockerfile"
    return 1
  }

  echo "$repo/$image:$tag"
}