## rm

---

Delete files from repository along with corresponding commit history.

### Description

Let's say you have a git repository that you are working on. Someday you find one file in this repository includes sensitive information that should not be exposed. Then you delete the sensitive information from the file in your local repository, and push the change to the remote repository hosted on GitHub by using `git commit` and `git push`.

However, since the previous copies of this file that include sensitive information have already been pushed to the remote repository. The sensitive information can still be seen in the commit history of this file. This is true even you delete the file completely from the repository. As long as the commit history is there, people can still reach the previous version of this file that includes the sensitive information by traversing the commit history.

In this case, it is not sufficient if you just delete the sensitive information from the file, or the file itself from the repository. What you really need is to delete both the file and the commit history. This is what `rm` used for.

It supports batch delete by specifying multiple files in a single command, or even wildcard in the filename so that all files whose names match the wildcard will be deleted.

Note:
* Please go into the root directory of a git repository, before you run the command.

### Usage

ga rm source_file ...

### Examples

To delete multiple files and their commit histories from the repository:
```shell
ga rm file1 file2
```

To delete all files whose names match the wildcard, `*.md` in this case, and the commit histories from the repository:
```shell
ga rm *.md
```

To learn how many commands that Git Assist supports, please read [Commands](../commands.md).