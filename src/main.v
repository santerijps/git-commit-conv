module main

import flag
import os

const (
	app_title = 'git-commit-conv'
	app_version = '0.0.1'
	app_description = 'Generate a git commit-msg hook quickly!'
	pattern_conventional_commits = '^(?:feat|fix|test|docs|refactor)(?:\(\w+\))?: (?:add|update|remove) .+$'
)

fn main() {

	mut fp := flag.new_flag_parser(os.args)
	fp.application(app_title)
	fp.version(app_version)
	fp.description(app_description)
	fp.skip_executable()

	fp.limit_free_args(0, 0) or {
		eprintln('Invalid input!')
		println(fp.usage())
		exit(1)
	}

	regex := fp.string('regex', `r`,
		pattern_conventional_commits,
		'The RegEx pattern to compare the commit message to. Defaults to conventional commits.')

	mut path := fp.string('path', `p`,
		'.',
		'Path to a git repository where to add the hook. Defaults to current directory.')

	fp.finalize() or {
		eprintln('Invalid input!')
		println(fp.usage())
		exit(1)
	}

	if path == '.' {
		path = os.getwd()
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

	println('Successfully added commit-msg hook: $regex')
	exit(0)

}