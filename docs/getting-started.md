## Getting Started

---

### Install and run

It is easy to install Git Assist since it is just a single script file. You can clone the git repository of Git Assist as below:
```shell
$ git clone https://github.com/morningspace/git-assist.git
```

Then go into the root directory of the git repository, find the script file and run it:
```shell
$ cd git-assist
$ ./ga.sh
```

You will see the general help information and a list of commands that are currently supported by Git Assist. Run the script file with a specified command along with `--help` option, you will see more information on how to use each command. For example:
```shell
$ ./ga.sh cp --help
```

### Run using shortcut

For convenience, you can add the path to the git repository to the `PATH` environment variable, so that you can run Git Assist anywhere. Take MacOS as an example, you can run below commands to set the path and run the script in any directory:
```
$ export PATH=$PATH:path/to/git-assist
$ ga.sh
```

Alternatively, you can also define an alias that points to the script file and put the alias into the shell rc file, e.g. `.bashrc` for Bash, or `.zshrc` for Zsh, etc. which is usually in user home direcctory.
```
$ cat ~/.bashrc
...
# Define alias for Git Assist
alias ga="~/Code/git-assist/ga.sh"
...
```

Then, each time when you open a new Terminal, you can use the alias to invoke Git Assist anywhere.

To learn how many commands that Git Assist supports, and what problem that each command resolves, please read [Commands](commands.md).
