#/bin/bash

function info {
  # Cyan
  printf "\033[0;36mINFO\033[0m $@\n"
}

function warn {
  # Yellow
  printf "\033[0;33mWARN\033[0m $@\n"
}

function error {
  # Red
  printf "\033[0;31mERRO\033[0m $@\n"
}

function print_commits {
  info "Commits as below:"
  for commit in $@; do
    echo $commit
  done
}

function ensure_git_repo {
  if ! git remote -v 1>/dev/null 2>&1; then
    error "Not a git repository!"
    exit 0
  fi
}

function get_current_branch {
  git rev-parse --abbrev-ref HEAD
}

function gitx_change {
  # git filter-branch -f --env-filter '
  #   export GIT_COMMITTER_NAME="$CORRECT_NAME"
  #   export GIT_COMMITTER_EMAIL="$CORRECT_EMAIL"
  #   export GIT_AUTHOR_NAME="$CORRECT_NAME"
  #   export GIT_AUTHOR_EMAIL="$CORRECT_EMAIL"
  # ' $latest_commit..HEAD
  error "Not supported yet"
}

function gitx_mv {
  error "Not supported yet"
}

function gitx_push {
  ensure_git_repo

  local branch=$(get_current_branch)
  local num_to_push=1
  if [[ $@ =~ -[0-9]+ ]]; then
    num_to_push=$(echo $@ | grep -o "\-[0-9]\+")
    num_to_push=${num_to_push#-}
  fi
  if [[ $@ =~ -r ]]; then
    info "The number of commits to be pushed will be <= $num_to_push"
    num_to_push=$(( ( RANDOM % $num_to_push ) + 1 ))
  fi

  info "Get the gap between orgin/$branch and $branch..."
  git log --format="oneline" origin/$branch..$branch

  gap_commits=($(git log --format="%H" origin/$branch..$branch))
  num_commits=${#gap_commits[@]}
  if (( $num_commits == 0 )); then
    warn "Nothing to push!"
    exit 0
  fi

  if (( $num_commits < $num_to_push )); then
    num_to_push=$num_commits
  fi
  
  info "Get the latest commit on orgin/$branch..."
  latest_commit=$(git log --format="%h" -n 1 origin/$branch)
  info "$latest_commit"

  info "Update commit date since the lastest commit..."
  if ! git filter-branch -f --env-filter '
    export GIT_AUTHOR_DATE="$(date +"%c %z")"
    export GIT_COMMITTER_DATE="$(date +"%c %z")"
  ' $latest_commit..HEAD; then
    error "Update commit date failed"
    exit 1
  fi

  info "Get the gap commits again..."
  git log --format="oneline" origin/$branch..$branch

  gap_commits=($(git log --format="%H" origin/$branch..$branch))
  info "Push $num_to_push commit(s)..."

  if [[ ! $@ =~ -f ]]; then
    for (( i=$num_commits-1 ; i>=$num_commits-$num_to_push ; i-- )) ; do
      local commit=${gap_commits[i]}
      git log --format=oneline -n 1 $commit
    done

    printf "Press Enter to continue or Ctrl+C to stop..."
    read -r
  fi

  for (( i=$num_commits-1 ; i>=$num_commits-$num_to_push ; i-- )) ; do
    local commit=${gap_commits[i]}
    local command="git push origin $commit:$branch"
    $command
  done
}

function usage {
  cat << EOF

The Git eXtended Tool Set
 
Usage: ${0##*/} COMMAND [OPTIONS]

Commands:
  push    Only push part of the local commits while defer other ones
  change  Change committer and author for your commits
  mv      Move folders or files with commit history to another repository

EOF
}

if [[ $1 == push ]]; then
  gitx_push ${@:2}
elif [[ $1 == change ]]; then
  gitx_change ${@:2}
elif [[ $1 == mv ]]; then
  gitx_mv ${@:2}
else
  usage
fi
