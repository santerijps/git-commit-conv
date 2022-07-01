# git-commit-conv

Generate a git commit-msg hook easily to enforce a strict commit message format. Simply run the executable in your git repository to add the [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) standard to the commit-msg hook.

You can also provide a path to the git repository and a custom RegEx pattern to check the commit messages against.

## Usage

```txt
git-commit-conv 0.2.0
-----------------------------------------------
Usage: git-commit-conv 
   or: git-commit-conv --status
   or: git-commit-conv --regex '^TICKET-\d+: .+$'
   or: git-commit-conv --path /path/to/repo --regex '^TICKET-\d+: .+$'

Description: Generate a git commit-msg hook quickly!

This application does not expect any arguments

Options:
  -r, --regex <string>      The RegEx pattern to compare the commit message to. Defaults to conventional commits.
  -p, --path <string>       Path to a git repository where to add the hook. Defaults to current directory.       
  -r, --reset               Reset (remove) the commit-msg hook.
  -v, --verbose             Print program messages.
  -s, --status              Get the current commit-msg hook, if any.
  -i, --install <string>    Install a RegEx pattern with a name.
  -u, --uninstall <string>  Uninstall a RegEx pattern by name.
  -n, --name <string>       The name of the installed RegEx pattern to use.
  -l, --list                List all installed RegEx patterns.
  -h, --help                display this help and exit
  --version                 output version information and exit
```
