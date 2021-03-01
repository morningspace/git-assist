## push

---

Only push part of your local commits to remote repository.
 
### Description

Suppose you are actively working on a project with a lot of commits submitted to your local git repository, but these commits have not been pushed to the remote git repository yet. You want to continue the work in local repository and only push the staged contents that you think they are OK to be published as offical contents via the remote repository.

Of course we can achieve this by creating a featrue branch so that you can work on this branch and merge your work to a release branch periodically, then push it to the remote repository from the local release branch.

Alternatively, you can use `push` command to stay at your current single branch without the need to work on multiple branches and switch among them from time to time.

It supports to push part of your local commits to the remote repository. Before it starts to push the commits, the command will compare the commit history between the local repository and the remote repository to caculate the gap. For example, if your local repository is ahead of the remote repository by 50 commits, then you can specify a number not more than 50 to indicate, start from the earliest commit in the gap, how many commits that you want to push to the remote repository. For example, if you specify `-10`, then the first 10 commits in the gap will be pushed.

Some interesting additional features to this command include:
* By adding `-r` along with a number, it can randomize the number of commits to be pushed. So, if you use `-10 -r`, the final number of commits to be pushed will be a random number not more than `10`.
* By adding `-f`, it will force push your local commits to the remote repository. So, this will overwrite your commit history in the remote repository if there is any overlap for the commit history.

Note:
* Please go into the root directory of a git repository, before you run the command.

### Usage

ga push [OPTIONS]

### Options

* -n            The number of commits to be pushed
* -r, --random  Randomize the number of commits to be pushed
* -f, --force   Force to push

### Examples

To push the first 5 commits in the gap caculated by comparing the commit history between the local and remote repository:
```shell
ga push -5
```

To push a random number of commits where the number is not more than 10:
```shell
ga push -10 -r
```

To learn how many commands that Git Assist supports, please read [Commands](commands.md).