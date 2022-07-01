module main

import encoding.csv
import flag
import os

const (
	app_title = 'git-commit-conv'
	app_version = '0.2.0'
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

	mut regex := fp.string('regex', `r`,
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
		false, 'Get the current commit-msg hook, if any.')

	install := fp.string('install', `i`,
		'', 'Install a RegEx pattern with a name.')

	uninstall := fp.string('uninstall', `u`,
		'', 'Uninstall a RegEx pattern by name.')

	name := fp.string('name', `n`,
		'', 'The name of the installed RegEx pattern to use.')

	list := fp.bool('list', `l`,
		false, 'List all installed RegEx patterns.')

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
	install_file_path := os.join_path(os.home_dir(), '.git-commit-conv')

	if verbose == true {
		println('commit-msg file path:\t$commit_msg_file_path')
		println('install file path:\t$install_file_path')
	}

	if os.exists(install_file_path) == false {
		os.write_file(install_file_path, '') or {
			eprintln(err)
			exit(1)
		}
		if verbose == true {
			println('Created install file!')
		}
	}

	if name.len > 0 {
		data := os.read_file(install_file_path) or {
			eprintln(err)
			exit(1)
		}
		mut reader := csv.new_reader(data)
		mut found := false
		for {
			items := reader.read() or { break }
			if items[0] == name {
				regex = items[1]
				found = true
				if verbose == true {
					println('Using installed pattern "$name"')
				}
			}
		}
		if found == false {
			eprintln('Could not find installed pattern "$name"')
			exit(1)
		}
	}

	// SHORT CIRCUIT

	// STATUS
	if status == true {
		content := os.read_file(commit_msg_file_path) or {
			println('commit-msg hook has not been set!')
			exit(0)
		}
		println('commit-msg hook exists!')
		println(content)
		exit(0)
	}

	// RESET
	if reset == true {
		os.rm(commit_msg_file_path) or {}
		println('commit-msg hook was reset!')
		exit(0)
	}

	// LIST
	if list == true {
		data := os.read_file(install_file_path) or { '' }
		mut reader := csv.new_reader(data)
		for {
			items := reader.read() or { break }
			println('${items[0]}\t\t->\t\t${items[1]}')
		}
		exit(0)
	}

	if uninstall.len > 0 {
		data := os.read_file(install_file_path) or { '' }
		mut reader := csv.new_reader(data)
		mut writer := csv.new_writer()
		for {
			items := reader.read() or { break }
			if items[0] != uninstall {
				writer.write(items) or {
					eprintln(err)
					exit(1)
				}
			}
		}
		os.write_file(install_file_path, writer.str()) or {
			eprintln(err)
			exit(1)
		}
		if verbose == true {
			println('Unstalled:\t\t$install')
		}
		exit(0)
	}

	// INSTALL
	if install.len > 0 {
		data := os.read_file(install_file_path) or { '' }
		mut reader := csv.new_reader(data)
		mut writer := csv.new_writer()
		for {
			items := reader.read() or { break }
			if items[0] != install {
				writer.write(items) or {
					eprintln(err)
					exit(1)
				}
			}
		}
		writer.write([install, regex]) or {
			eprintln(err)
			exit(1)
		}
		os.write_file(install_file_path, writer.str()) or {
			eprintln(err)
			exit(1)
		}
		if verbose == true {
			println('Install:\t\t$install -> $regex')
		}
	}

	// CONFIGURE COMMIT-MSG

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