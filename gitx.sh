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
  local random=0
  local force=0
  while [[ $# -gt 0 ]]; do    
    case "$1" in
    -r|--random)
      random=1
      shift # past argument
      ;;
    -f|--force)
      force=1
      shift # past argument
      ;;
    *)
      if [[ $1 =~ -[0-9]+ ]]; then
        num_to_push=${1#-}
      else
        POSITIONAL+=("$1") # save it in an array for later use
      fi
      shift # past argument
      ;;
    esac
  done

  if [[ $random == 1 ]]; then
    num_to_push=$(( ( RANDOM % $num_to_push ) + 1 ))
  fi

  info "We are going to push $num_to_push commit(s)"
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
  info "The commit(s) to be pushed:"
  for (( i=$num_commits-1 ; i>=$num_commits-$num_to_push ; i-- )) ; do
    local commit=${gap_commits[i]}
    git log --format=oneline -n 1 $commit
  done

  ! confirm "Are you sure to push local changes to remote repository?" && return

  info "Push local changes to remote repository..."
  local args
  [[ $force == 1 ]] && args+="--force"
  for (( i=$num_commits-1 ; i>=$num_commits-$num_to_push ; i-- )) ; do
    local commit=${gap_commits[i]}
    local command="git push $args origin $commit:$branch"
    $command
  done
}

# OPTIONS:
#   -u  The git user name
#   -e  The git user email
#   -c  Change committer only
#   -U  The git user to be changed specified by name
#   -E  The git user to be changed specified by email
function gitx_chuser {
  ensure_git_repo

  export USER_NAME=$(git config user.name)
  export USER_EMAIL=$(git config user.email)
  export COMMITTER_ONLY
  export USER_TO_CHANGE
  export EMAIL_TO_CHANGE
  while [[ $# -gt 0 ]]; do    
    case "$1" in
    -u|--user)
      USER_NAME="$2"
      shift # past argument
      shift # past value
      ;;
    -e|--email)
      USER_EMAIL="$2"
      shift # past argument
      shift # past value
      ;;
    -c|--committer-only)
      COMMITTER_ONLY=1
      shift # past argument
      ;;
    -U|--user-to-change)
      USER_TO_CHANGE="$2"
      shift # past argument
      shift # past value
      ;;
    -E|--email-to-change)
      EMAIL_TO_CHANGE="$2"
      shift # past argument
      shift # past value
      ;;
    *)      # unknown option
      POSITIONAL+=("$1") # save it in an array for later use
      shift # past argument
      ;;
    esac
  done

  info "The user name: $USER_NAME"
  info "The user email: $USER_EMAIL"
  if [[ $COMMITTER_ONLY == 1 ]]; then
    info "Change committer only."
  else
    info "Change both committer and author."
  fi

  ! confirm "Are you sure to change commits in local repository?" && return

  info "Change commits with specified user information..."
  if ! git filter-branch -f --env-filter '
    if [[ -z $USER_TO_CHANGE && -z $EMAIL_TO_CHANGE ]]; then
      change_it=0
    elif [[ $USER_TO_CHANGE == $GIT_AUTHOR_NAME || $USER_TO_CHANGE == $GIT_COMMITTER_NAME ]]; then
      change_it=1
    elif [[ $EMAIL_TO_CHANGE == $GIT_AUTHOR_EMAIL || $EMAIL_TO_CHANGE == $GIT_COMMITTER_EMAIL ]]; then
      change_it=1
    else
      change_it=0
    fi

    if [[ $change_it == 1 ]]; then
      export GIT_COMMITTER_NAME="$USER_NAME"
      export GIT_COMMITTER_EMAIL="$USER_EMAIL"
      if [[ $COMMITTER_ONLY != 1 ]]; then
        export GIT_AUTHOR_NAME="$USER_NAME"
        export GIT_AUTHOR_EMAIL="$USER_EMAIL"
      fi
    fi
  ' -- --all; then
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
  chuser  Change committer and author for your commits
  mv      Move folders or files with commit history to another repository

EOF
}

if [[ $1 == push ]]; then
  gitx_push "${@:2}"
elif [[ $1 == chuser ]]; then
  gitx_chuser "${@:2}"
elif [[ $1 == mv ]]; then
  gitx_mv "${@:2}"
else
  usage
fi
