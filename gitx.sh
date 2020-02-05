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
  printf "\033[0;37mPress Enter to continue or Ctrl+C to stop...\033[0m"
  read -r
}

function confirm {
  local input
  while true; do
    printf "\033[0;37m$1\033[0m [Y/n] "
    read -r input
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

function join_by {
  local d=$1; shift; printf "$1"; shift; printf "%s" "${@/#/$d}";
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

function do_ppush {
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

  info "Change commits in local repository since the lastest commit..."
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
    if ! $command; then
      error "Failed to push $commit to remote repository"
      exit 1
    fi
  done

  info "\033[0;33mCongratulations!\033[0m All changes have been pushed to remote repository."
}

function do_chuser {
  ensure_git_repo

  export USER_NAME=$(git config user.name)
  export USER_EMAIL=$(git config user.email)
  export COMMITTER_ONLY
  export USER_TO_CHANGE
  export EMAIL_TO_CHANGE
  local config_user
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
    -c|--config-user)
      config_user=1
      shift # past argument
      ;;
    -C|--committer-only)
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

  if [[ -n $USER_TO_CHANGE ]]; then
    info "The old user name: $USER_TO_CHANGE" 
  fi
  if [[ -n $EMAIL_TO_CHANGE ]]; then
    info "The old user email: $EMAIL_TO_CHANGE" 
  fi
  info "The new user name: $USER_NAME"
  info "The new user email: $USER_EMAIL"
  if [[ $config_user == 1 ]]; then
    info "Config local repository to use new git user"
  fi
  if [[ $COMMITTER_ONLY == 1 ]]; then
    info "Change committer only."
  else
    info "Change both committer and author."
  fi

  ! confirm "Are you sure to change commits in local repository?" && return

  info "Change commits with specified user information..."
  if ! git filter-branch -f --env-filter '
    if [[ -z $USER_TO_CHANGE && -z $EMAIL_TO_CHANGE ]]; then
      change_it=1
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

  if [[ $config_user == 1 ]]; then
    info "Config your local repository to use new git user..."
    git config user.name $USER_NAME
    git config user.email $USER_EMAIL
  fi

  ! confirm "Are you sure to push local changes to remote repository?" && return

  info "Push local changes to remote repository..."
  if ! git push --force --all origin; then
    error "Failed to push local changes to remote repository"
    exit 1
  fi

  info "\033[0;33mCongratulations!\033[0m All changes have been pushed to remote repository."
}

function do_copy {
  ensure_git_repo

  local preserve
  while [[ $# -gt 0 ]]; do    
    case "$1" in
    -p|--preserve)
      preserve=1
      shift # past argument
      ;;
    *)      # unknown option
      POSITIONAL+=("$1") # save it in an array for later use
      shift # past argument
      ;;
    esac
  done

  local src_items=() src_item dest_repo position
  for (( position=0; position<${#POSITIONAL[@]}-1; position++ )); do
    src_item=${POSITIONAL[$position]}
    if [[ -f $src_item || -d $src_item ]]; then
      export SRC_FILES="$SRC_FILES -e \"\\t\"$src_item$"
    else
      error "$src_item not found"
      exit 1
    fi
    src_items+=("$src_item")
  done
  dest_repo="${POSITIONAL[$position]}"

  local src_repo_dir=$PWD
  local src_repo_name=${PWD##*/}
  local dest_repo_name=${dest_repo##*/}
  dest_repo_name=${dest_repo_name%.git}

  info "The item(s) to be copied from $src_repo_name to $dest_repo_name: $(join_by ', ' ${src_items[@]})"

  ! confirm "Are you sure to copy the items?" && return

  info "Copy repository $src_repo_name to temp directory for commit history rewritting..."
  mkdir -p ~/.gitx
  rm -rf ~/.gitx/$src_repo_name
  cp -r $PWD ~/.gitx/
  cd ~/.gitx/$src_repo_name

  info "Start to rewrite local commit history..."
  git remote rm origin
  if [[ ${#src_items[@]} == 1 && -d $src_items ]]; then
    git filter-branch --subdirectory-filter $src_items -- --all

    if [[ $preserve == 1 ]]; then
      mkdir $src_items
      mv *[^$src_items]* $src_items
      git add .
      git commit -m "Move $src_items from $src_repo_name to $dest_repo_name"
    fi
  else
    git filter-branch -f --index-filter "
      git ls-files -s | grep $SRC_FILES |
      GIT_INDEX_FILE=\$GIT_INDEX_FILE.new git update-index --index-info &&
      [[ -f \$GIT_INDEX_FILE.new ]] && mv \$GIT_INDEX_FILE.new \$GIT_INDEX_FILE ||
      :
    " --prune-empty -- --all
  fi

  info "Clean up local cache..."
  git reset --hard
  git gc --aggressive
  git prune
  git clean -fd

  cd -
  cd ..
  info "Clone $dest_repo_name into directory $PWD/$dest_repo_name..."
  if ! git clone $dest_repo; then
    error "Fail to clone $dest_repo_name"
    exit 1
  fi
  cd $dest_repo_name

  info "Pull the items from repository $src_repo_name..."
  git remote add $src_repo_name ~/.gitx/$src_repo_name
  git pull $src_repo_name master --allow-unrelated-histories
  git fetch $src_repo_name master --tags
  git remote rm $src_repo_name

  ! confirm "Are you sure to push local changes to remote repository?" && return

  info "Push local changes to remote repository..."
  if ! git push --force --all origin || ! git push --force --tags origin; then
    error "Failed to push local changes to remote repository"
    exit 1
  fi

  info "\033[0;33mCongratulations!\033[0m All changes have been pushed to remote repository."
}

function do_delete {
  ensure_git_repo

  if [[ $# == 0 ]]; then
    error "You have to specify file(s) to be deleted"
    exit 1
  fi

  local files=("$@")

  info "The file(s) to be deleted: $(join_by ', ' ${files[@]})"

  ! confirm "Are you sure to delete file(s)?" && return

  info "Delete file(s) from local repository..."
  for file in ${files[@]}; do
    export FILE_TO_REMOVE=$file
    git filter-branch --force --index-filter '
      git rm --cached --ignore-unmatch $FILE_TO_REMOVE
    ' --prune-empty --tag-name-filter cat -- --all
  done

  git for-each-ref --format='delete %(refname)' refs/original | git update-ref --stdin
  git reflog expire --expire=now --all

  info "Clean up local cache..."
  git gc --prune=now

  ! confirm "Are you sure to push local changes to remote repository?" && return

  info "Push local changes to remote repository..."
  if ! git push --force --all origin || ! git push --force --tags origin; then
    error "Failed to push local changes to remote repository"
    exit 1
  fi

  info "\033[0;33mCongratulations!\033[0m All changes have been pushed to remote repository."
}

function usage {
  if [ $# -eq 0 ]; then
    echo "$USAGE_GENERAL"
  else
    local COMMAND=$(echo $1 | tr '[:lower:]' '[:upper:]')
    eval "echo \"\$USAGE_$COMMAND\""
  fi
}

USAGE_GENERAL="
The Command Line Tools to eXtend Git for Advanced Use
 
Usage: ${0##*/} COMMAND [OPTIONS]

Commands:
  ppush   Only push part of your local commits to remote repository 
  chuser  Change committer, author of your commits to specified values
  copy    Copy files or directory with commit history from one repository to another repository
  delete  Delete files from repository including corresponding commit history
"

USAGE_PPUSH="
Only push part of your local commits to remote repository 
 
Usage: ${0##*/} ppush [OPTIONS]

OPTIONS:
  -n            The number of commits to be pushed
  -r, --random  Randomize the number of commits to be pushed
  -f, --force   Force to push

Examples:
  ${0##*/} ppush -5
  ${0##*/} ppush -10 -r
"

USAGE_CHUSER="
Change committer, author of your commits to specified values

Usage: ${0##*/} chuser [OPTIONS]

OPTIONS:
  -u, --user            The git user name
  -e, --email           The git user email
  -c, --config-user     Config local repository to use new git user
  -C, --committer-only  Change committer only
  -U, --user-to-change  The git user to be changed specified by name
  -E, --email-to-change The git user to be changed specified by email

Examples:
  ${0##*/} chuser -u morningspace -e morningspace@yahoo.com
  ${0##*/} chuser -u morningspace -e morningspace@yahoo.com -U \"William\"
"

USAGE_COPY="
Copy files or directory with commit history from one repository to another repository

Usage: ${0##*/} copy [OPTIONS] source_file ... target_repoistory
       ${0##*/} copy [OPTIONS] source_directory target_repoistory

OPTIONS:
  -p, --preserve  Preserve the structure when copy directory

Examples:
  ${0##*/} copy file1 file2 https://github.com/someuser/new-repo.git
  ${0##*/} copy -p foodir https://github.com/someuser/new-repo.git
"

USAGE_DELETE="
Delete files from repository including corresponding commit history

Usage: ${0##*/} delete source_file ...

Examples:
  ${0##*/} delete file1 file2
  ${0##*/} delete *.md
"

case $1 in
  "ppush"|"chuser"|"copy"|"delete")
    if [[ $2 == "-h" || $2 == "--help" ]]; then
      usage $1
    else
      do_$1 "${@:2}"
    fi
    ;;
  *)
    usage
    ;;
esac
