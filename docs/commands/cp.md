## cp

---

Copy multiple files or one directory with commit history from one repository to another.

### Description

Let's say you have some experiment work ongoing in your private git repository. When the work is consolidated, you want to move it to a public git repository which is a more official place to publish your work.

Of course you can simply copy the corresponding files directly from the source repository to the target repository. However, this will lose all the commit history that you made against these files in the source repository. As a result, you can not track back the change history of these files any longer in the target repository.

By using the `cp` command, you can copy the files from one repsoitory to another while preserve the commit history at the same time.

It supports batch copy by specifying multiple files in a single command, or a directory where all the files underneath will be copied over to the target repository.

If you specify a directory when run this command, by default the directory will not be created in the target repository, it will just copy the files under the directory. If you want to preserve the direcctory structure when copy it, you can specify `-p` or `--preserve` option.

Note:
* Please go into the root directory of the source git repository, before you run the command.

### Usage

ga cp [OPTIONS] source_file ... target_repoistory

ga cp [OPTIONS] source_directory target_repoistory

### Options

* -p, --preserve  Preserve the structure when copy directory

### Examples


To copy multiple files from your current git repository to a new repository:
```shell
$ ga cp file1 file2 https://github.com/someuser/new-repo.git
```

To copy all files under a certain directory while preserve the diretory structure:
```shell
$ ga cp -p foodir https://github.com/someuser/new-repo.git
```

To learn how many commands that Git Assist supports, please read [Commands](commands.md).