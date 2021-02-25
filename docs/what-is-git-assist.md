## What is Git Assist?

---

Git Assist is designed as a set of command line tools that can assist your daily work on git and GitHub use.

If you use git and GitHub very often like me, sometimes you may encounter problems which may not be easily resolved by just using a git GUI client or executing one or two git commands.

For example, you may want to copy files or directory from one git repository to another repository but still want to keep the commit history of these files or directory. Another example is that you may want to delete a file from a git repository completely including its commit history. These are all advanced git usage scenarios which may need a whole bunch of git commands run sequentially. Usually, it could be documented including step by step instructions with caveats, and you need to be very careful when you go through the steps, because if you do it wrong at some step, your git repository and the commit history can be damaged which is very difficult to get them back, or even no way to recover.

Git Assist provides a list of commands that you can use to address these problems. It encapsulates the instructions into executable scripts with some best practices embedded, so that you can run the commands as black box without worring about making mistakes as you do when run the steps manually by following the instructions. It also provides options for each command so that you can customize the behavior of the command to meet your specific need.

To learn how to install and run Git Assist, please read [Getting Started](getting-started.md).