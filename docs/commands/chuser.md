## chuser

---

Change committer and/or author of your commits to specified values

### Description

Given you have two git user accounts being used simultaneously. One is for your public projects hosted on GitHub. The other is for your private projects hosted internally within the company using GitHub Enterprise. It is a common case that you misuse the account when you switch among those projects. And, when you notice the misuse, maybe you have already submitted commits or even push them to the remote repository using the wrong account for a while.

The `chuser` command is designed to resolve such problem. By specifying the new user name and email, you can modify both the comitter and author references for all commits in the commit history. You can also choose to modify the committer information only if you want to keep the original author information.

By default, the command will modify all commits in the repository. If this is a repository where multiple people work on it, you can specify a filter by either user name or email, to indicate only the commits whose author name or email matches the specified value will be modified. So, you only modify the committer and author information for the commits made by you, not those made by others.

To avoid the account misuse in future, you can set the default user name and email to the correct values for your git repository. So, next time when you submit a commit, it will use the correct account. This can be done by specifying `-c` option when you run the command. It will help you set the default git account for the repository that you are working on. The setting is only scoped to this repository and will not impact your other repositories.

Note:
* Please go into the root directory of a git repository, before you run the command.

### Usage

ga chuser [OPTIONS]

### Options

* -u, --user            The git user name
* -e, --email           The git user email
* -c, --config-user     When update commits, also config local repository to use new git user
* -C, --committer-only  Change committer only, otherwise will change both committer and author
* -U, --filter-by-user  The git user to be changed specified by name
* -E, --filter-by-email The git user to be changed specified by email

### Examples

To modify both committer and author for all commits in the repository to use new values:
```shell
ga chuser -u morningspace -e morningspace@yahoo.com
```

To modify both committer and author for all commits whose author name should be `"William"` in the repository:
```shell
ga chuser -u morningspace -e morningspace@yahoo.com -U \"William\"
```

To learn how many commands that Git Assist supports, please read [Commands](../commands.md).