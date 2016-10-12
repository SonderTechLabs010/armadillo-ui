#!/bin/sh
# Copyright 2016 The Fuchsia Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Extensions for the jiri tool.
#
# Usage:
#     jiri runp $PWD/sysui/tools/jiri_commands.sh <command>
#
# Available commands:
#   - branch: list projects which have non-master branches;
#   - master: switch all projects to their master branch;
#   - local: list projects which are not currently on the master branch;
#   - delete: delete a branch in all projects;
#   - status: list uncommitted changes.

command=$1
project=`pwd`
current_branch=`git rev-parse --abbrev-ref HEAD`
branches=`git for-each-ref --format='%(refname:short)' refs/heads/`

if [[ "$command" == "branch" ]]; then
  if [[ "$branches" != "master" ]]; then
    tput setaf 4
    echo "$project"
    tput sgr0
    echo "$branches"
  fi
elif [[ "$command" == "master" ]]; then
  if [[ "$current_branch" != "master" ]]; then
    tput setaf 4
    echo "$project"
    tput sgr0
    git checkout master
  fi
elif [[ "$command" == "local" ]]; then
  if [[ "$current_branch" != "master" ]]; then
    tput setaf 4
    echo -n "$project"
    tput sgr0
    echo -n " is on "
    tput setaf 2
    echo "$current_branch"
    tput sgr0
  fi
elif [[ "$command" == "delete" ]]; then
  branch=$2
  if [[ "$branches" == *"$branch"* ]]; then
    tput setaf 4
    echo "$project"
    tput sgr0
    if [[ "$current_branch" == "$branch" ]]; then
      git checkout master
    fi
    git branch -D $branch
  fi
elif [[ "$command" == "status" ]]; then
  changes=`git status -s`
  if [[ "$changes" != "" ]]; then
    tput setaf 4
    echo "$project"
    tput sgr0
    echo "$changes"
  fi
else
  echo "Unknown command: $command"
fi
