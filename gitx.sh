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

function pause {
  printf "Press Enter to continue or Ctrl+C to stop..."
  read -r
}

function confirm {
  local input
  while true; do
    read -r -p "$1 [Y/n] " input
    input=${input:-Y}
    case $input in
      [yY][eE][sS]|[yY])
        return 0
        ;;
      [nN][oO]|[nN])
        return 1
        ;;
      *)
        echo "Invalid input..."
        ;;
    esac
  done
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

# OPTIONS:
#   -n  The number of commits to be pushed
#   -r  Randomize the number of commits to be pushed
#   -f  Force to push
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
    warn "Everything is up-to-date. There's nothing to push!"
    exit 0
  fi

  if (( $num_commits < $num_to_push )); then
    num_to_push=$num_commits
  fi
  
  info "Get the latest commit on orgin/$branch..."
  latest_commit=$(git log --format="%h" -n 1 origin/$branch)
  info "$latest_commit"

  ! confirm "Are you sure to change commits in local repository?" && return

  info "Change commits since the lastest commit..."
  if ! git filter-branch -f --env-filter '
    export GIT_AUTHOR_DATE="$(date +"%c %z")"
    export GIT_COMMITTER_DATE="$(date +"%c %z")"
  ' $latest_commit..HEAD; then
    error "Change commits failed"
    exit 1
  fi

  info "Get the gap commits again..."
  git log --format="oneline" origin/$branch..$branch

  gap_commits=($(git log --format="%H" origin/$branch..$branch))
  info "Push $num_to_push commit(s):"
  for (( i=$num_commits-1 ; i>=$num_commits-$num_to_push ; i-- )) ; do
    local commit=${gap_commits[i]}
    git log --format=oneline -n 1 $commit
  done

  ! confirm "Are you sure to push local changes to remote repository?" && return

  info "Push local changes to remote repository..."
  local args
  [[ $@ =~ -f ]] && args+="--force"
  for (( i=$num_commits-1 ; i>=$num_commits-$num_to_push ; i-- )) ; do
    local commit=${gap_commits[i]}
    local command="git push $args origin $commit:$branch"
    $command
  done
}

# OPTIONS:
#   -u  The git user name
#   -e  The git user email
#   -a  Change both committer and author
function gitx_change {
  ensure_git_repo

  local user_name=$(git config user.name)
  local user_email=$(git config user.email)
  local change_author
  if [[ $@ =~ -u[[:space:]]+ ]]; then
    user_name=$(echo $@ | grep -o "\-u[[:space:]]\+[^\-]\+")
    user_name=$(echo ${user_name#-u} | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
  fi
  if [[ $@ =~ -e[[:space:]]+ ]]; then
    user_email=$(echo $@ | grep -o "\-e[[:space:]]\+[^\-]\+")
    user_email=$(echo ${user_email#-e} | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
  fi
  if [[ $@ =~ -a ]]; then
    change_author=1
  fi

  info "The user name: $user_name"
  info "The user email: $user_email"
  [[ $change_author == 1 ]] && info "Change both committer and author."

  ! confirm "Are you sure to change commits in local repository?" && return

  info "Change commits with specified user information..."
  if ! git filter-branch -f --env-filter "
    export GIT_COMMITTER_NAME=\"$user_name\"
    export GIT_COMMITTER_EMAIL=\"$user_email\"
    if [[ $change_author == 1 ]]; then
      export GIT_AUTHOR_NAME=\"$user_name\"
      export GIT_AUTHOR_EMAIL=\"$user_email\"
    fi
  " -- --all; then
    error "Change commits failed"
    exit 1
  fi

  ! confirm "Are you sure to push local changes to remote repository?" && return

  info "Push local changes to remote repository..."
  git push --force --all origin
}

function gitx_mv {
  error "Not supported yet"
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
