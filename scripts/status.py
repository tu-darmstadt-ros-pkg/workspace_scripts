#!/usr/bin/env python
from __future__ import print_function
try:
  import git
except ImportError:
  print("GitPython is required! Install using 'pip install --user gitpython'")
  exit(1)
import subprocess
import os

class Style:
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  ORANGE='\033[0;33m'
  BLUE='\033[0;34m'
  PURPLE='\033[0;35m'
  CYAN='\033[0;36m'
  LGRAY='\033[0;37m'
  DGRAY='\033[1;30m'
  LRED='\033[1;31m'
  LGREEN='\033[1;32m'
  YELLOW='\033[1;33m'
  LBLUE='\033[1;34m'
  LPURPLE='\033[1;35m'
  LCYAN='\033[1;36m'
  WHITE='\033[1;37m'
  Error='\033[0;31m'
  Warning='\033[0;33m'
  Info='\033[0;34m'
  Success='\033[0;32m'
  Reset='\033[0;39m'


def printWithStyle(style, msg):
  print(style + msg + Style.Reset)


def printChanges(path):
  try:
      repo = git.Repo(path, search_parent_directories=True)
  except git.exc.InvalidGitRepositoryError:
    printWithStyle(Style.Error, "Failed to obtain git info for: {}".format(path))
    return
  stash = repo.git.stash('list')
  modified = set([item.a_path for item in repo.index.diff("HEAD") + repo.index.diff(None)])

  # Check branches for uncommited commits and pure local branches
  uncommited_commits = []
  local_branches = []
  for branch in repo.branches:
    if branch.tracking_branch() is None:
      local_branches.append(branch)
      continue
    if any(True for _ in repo.iter_commits('{0}@{{u}}..{0}'.format(branch.name))):
      uncommited_commits.append(branch)

  if any(repo.untracked_files) or any(stash) or any(uncommited_commits) or any(local_branches) or any(modified):
    printWithStyle(Style.Info, path)
    for branch in uncommited_commits:
      printWithStyle(Style.RED, "  Unpushed commits on branch {}!".format(branch))
    for branch in local_branches:
      printWithStyle(Style.LRED, "  Local branch with no remote set up: {}".format(branch))
    if any(stash):
      printWithStyle(Style.LCYAN, "  Stashed changes")
    for path in modified:
      printWithStyle(Style.ORANGE, "  Modified: {}".format(path))
    if len(repo.untracked_files) < 10:
      for file in repo.untracked_files:
        printWithStyle(Style.DGRAY, "  Untracked: {}".format(file))
    else:
      printWithStyle(Style.DGRAY, "  {} untracked files.".format(len(repo.untracked_files)))
    print("")
  elif repo.is_dirty():
    printWithStyle(Style.Info, path)
    printWithStyle(Style.Error, "  Dirty but I don't know why")
    print("")

class WsToolInfo:
  def __init__(self, git, version):
    self.git = git
    self.version = version


if __name__ == "__main__":
  ws_root_path = os.environ.get("ROSWSS_ROOT")
  os.chdir(ws_root_path)
  printWithStyle(Style.GREEN, "Looking for changes in {}...".format(ws_root_path))
  printChanges(ws_root_path)

  try:
    ws_tool_info = subprocess.check_output(["wstool", "info", "--only=path,scmtype,version"])
  except subprocess.CalledProcessError:
    printWithStyle(Style.Error, "Failed to get wstool info!")
    exit(1)

  ws_tool_paths = {}
  for item in ws_tool_info.splitlines():
    parts = item.split(",")
    ws_tool_paths[parts[0]] = WsToolInfo(parts[1] == "git", parts[2])
  
  def scanWorkspace(path):
    if not os.path.isdir(path):
      return
    subdirs = os.listdir(path)
    if ".git" in subdirs:
      printChanges(path)
    elif path in ws_tool_paths:
      if not ws_tool_paths[path]:
        output = subprocess.call(["wstool", "status", path])
        if output is not None and len(output) > 0:
          print(output)
          print("")

    for dir in sorted(subdirs):
      scanWorkspace(os.path.join(path, dir))

  ws_src_path = os.path.join(ws_root_path, "src")
  printWithStyle(Style.GREEN, "Looking for changes in {}...".format(ws_src_path))
  scanWorkspace(ws_src_path)



