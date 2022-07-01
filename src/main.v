module main

import flag
import os

const (
	app_title = 'git-commit-conv'
	app_version = '0.1.0'
	app_description = 'Generate a git commit-msg hook quickly!'
	pattern_conventional_commits = '^(?:feat|fix|test|docs|refactor)(?:\\(\\w+\\))?: (?:add|update|remove) .+$'
)

fn main() {

	mut fp := flag.new_flag_parser(os.args)
	fp.application(app_title)
	fp.version(app_version)
	fp.description(app_description)
	fp.skip_executable()

	fp.limit_free_args(0, 0) or {
		eprintln('Invalid input!')
		eprintln('Type \'$app_title --help\' for usage.')
		exit(1)
	}

	fp.usage_example('')
	fp.usage_example('--status')
	fp.usage_example('--regex \'^TICKET-\\d+: .+$\'')
	fp.usage_example('--path /path/to/repo --regex \'^TICKET-\\d+: .+$\'')

	regex := fp.string('regex', `r`,
		pattern_conventional_commits,
		'The RegEx pattern to compare the commit message to. Defaults to conventional commits.')

	mut path := fp.string('path', `p`,
		'.',
		'Path to a git repository where to add the hook. Defaults to current directory.')

	reset := fp.bool('reset', `r`,
		false, 'Reset (remove) the commit-msg hook.')

	verbose := fp.bool('verbose', `v`,
		false, 'Print program messages.')

	status := fp.bool('status', `s`,
		false, 'Get the current commit-msg hook (if any)')

	fp.finalize() or {
		eprintln('Invalid input!')
		eprintln('Type \'$app_title --help\' for usage.')
		exit(1)
	}

	if path == '.' {
		path = os.getwd()
	}

	if verbose == true {
		println('git repository path:\t$path')
	}

	os.chdir(path) or {
		eprintln(err)
		exit(1)
	}

	r := os.execute('git status')

	if r.exit_code != 0 {
		eprintln(r.output)
		exit(1)
	}

	commit_msg_file_path := os.join_path(path, '.git', 'hooks', 'commit-msg')

	if verbose == true {
		println('commit-msg file path:\t$commit_msg_file_path')
	}

	if status == true {
		content := os.read_file(commit_msg_file_path) or {
			println('commit-msg hook has not been set!')
			exit(0)
		}
		println('commit-msg hook exists!')
		println(content)
		exit(0)
	}

	if reset == true {
		os.rm(commit_msg_file_path) or {}
		println('commit-msg hook was reset!')
		exit(0)
	}

	if verbose == true {
		println('RegEx pattern:\t\t$regex')
	}

	commit_msg_content := '#!/bin/sh
test "$(grep -P \'$regex\' "\$1")" || {
	echo >&2 \'Commit rejected due to invalid commit message format.\'
	echo >&2 \'Correct format is: $regex\'
	exit 1
}'

	os.write_file(commit_msg_file_path, commit_msg_content) or {
		eprintln(err)
		exit(1)
	}

	println('commit-msg hook was set!')
	exit(0)

}