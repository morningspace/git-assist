#/bin/bash

max_to_push=2

function logger::info {
  echo -e "\033[1;36mINFO\033[0m $@"
}

function logger::warn {
  echo -e "\033[1;33mWARN\033[0m $@"
}

function logger::error {
  echo -e "\033[1;31mERRO\033[0m $@"
}

function print_commits {
  logger::info "Commits as below:"
  for commit in $@; do
    echo $commit
  done
}

function git_auto_push {
  num_to_push=$(( ( RANDOM % $max_to_push ) + 1 ))

  logger::info "Get the gap between orgin/master and master..."
  git log --format="oneline" origin/master..master

  gap_commits=($(git log --format="%H" origin/master..master))
  num_commits=${#gap_commits[@]}
  if (( $num_commits == 0 )); then
    logger::error "Nothing to push!"
    exit 0
  fi

  if (( $num_commits < $num_to_push )); then
    num_to_push=$num_commits
  fi
  
  logger::info "Get the latest commit on orgin/master..."
  latest_commit=$(git log --format="%h" -n 1 origin/master)
  logger::info "$latest_commit"

  logger::info "Update commit date since the lastest commit..."
  git filter-branch -f --env-filter '
    export GIT_AUTHOR_DATE="$(date +"%c %z")"
    export GIT_COMMITTER_DATE="$(date +"%c %z")"
  ' $latest_commit..HEAD

  # git filter-branch -f --env-filter '
  #   export GIT_COMMITTER_NAME="$CORRECT_NAME"
  #   export GIT_COMMITTER_EMAIL="$CORRECT_EMAIL"
  #   export GIT_AUTHOR_NAME="$CORRECT_NAME"
  #   export GIT_AUTHOR_EMAIL="$CORRECT_EMAIL"
  # ' $latest_commit..HEAD

  logger::info "Get the gap commits again..."
  git log --format="oneline" origin/master..master

  gap_commits=($(git log --format="%H" origin/master..master))
  logger::info "Push $num_to_push commit(s)..."

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
    local command="git push origin $commit:master"
    echo $command
  done
}

function git_test_repo {
  if ! git remote -v 1>/dev/null 2>&1; then
    logger::error "Not a git repository!"
    exit 0
  fi
}

git_test_repo
git_auto_push $@
