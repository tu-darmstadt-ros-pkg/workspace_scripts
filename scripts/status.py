#!/usr/bin/env python3
from __future__ import print_function
try:
  import git
except ImportError:
  print("GitPython is required! Install using 'pip3 install --user gitpython' or 'apt install python3-git'")
  exit(1)
import argparse
import argcomplete
import subprocess
import os


class Style:
  RED = '\033[0;31m'
  GREEN = '\033[0;32m'
  ORANGE = '\033[0;33m'
  BLUE = '\033[0;34m'
  PURPLE = '\033[0;35m'
  CYAN = '\033[0;36m'
  LGRAY = '\033[0;37m'
  DGRAY = '\033[1;30m'
  LRED = '\033[1;31m'
  LGREEN = '\033[1;32m'
  YELLOW = '\033[1;33m'
  LBLUE = '\033[1;34m'
  LPURPLE = '\033[1;35m'
  LCYAN = '\033[1;36m'
  WHITE = '\033[1;37m'
  Error = '\033[0;31m'
  Warning = '\033[0;33m'
  Info = '\033[0;34m'
  Success = '\033[0;32m'
  Reset = '\033[0;39m'


def printWithStyle(style, msg, end=None):
  print(style + msg + Style.Reset, end=end)


def getGitHeadState(repo: git.Repo):
  try:
    if not repo.head.is_detached:
      return repo.active_branch
    for tag in repo.tags:
      if tag.commit.hexsha == repo.head.commit.hexsha:
        return tag.name
    return repo.head.commit.hexsha
  except:
    printWithStyle(Style.Error, f"Failed to get head state for repo: {os.path.dirname(repo.git_dir)}")
    return "unknown"


def printChanges(path: str, show_all=False, base_path=''):
  try:
    repo = git.Repo(path, search_parent_directories=True)
  except git.exc.InvalidGitRepositoryError:
    printWithStyle(Style.Error, "Failed to obtain git info for: {}".format(path))
    return
  stash = repo.git.stash('list')
  changes = repo.index.diff(None)
  try:
    # Need to reverse using R=True, otherwise we get the diff from tree to HEAD meaning deleted files are added and vice versa
    changes += repo.index.diff("HEAD", R=True)
  except git.BadName as e:
    printWithStyle(Style.Error, "{} has no HEAD!\nException: {}".format(path, e.message))

  # Check branches for uncommited commits and pure local branches
  uncommited_commits = []
  local_branches = []
  deleted_branches = []
  for branch in repo.branches:
    if branch.tracking_branch() is None:
      local_branches.append(branch)
      continue
    if not branch.tracking_branch().is_valid():
      deleted_branches.append(branch)
      continue
    try:
      if any(True for _ in repo.iter_commits('{0}@{{u}}..{0}'.format(branch.name))):
        uncommited_commits.append(branch)
    except (git.exc.GitCommandError, Exception) as e:
      printWithStyle(Style.Error, f"{path} has error on branch {branch.name}: {e.message}")

  has_changes = any(repo.untracked_files) or any(stash) or any(uncommited_commits) or any(local_branches) or any(changes)
  if show_all or has_changes or repo.is_dirty():
    printWithStyle(Style.Info, path[len(base_path)+1:] if path.startswith(base_path) else path, end=' ')
    printWithStyle(Style.PURPLE, f"({getGitHeadState(repo)})")
  if has_changes:
    for branch in uncommited_commits:
      printWithStyle(Style.RED, "  Unpushed commits on branch {}!".format(branch))
    for branch in local_branches:
      printWithStyle(Style.LRED, "  Local branch with no remote set up: {}".format(branch))
    for branch in deleted_branches:
      printWithStyle(Style.LRED, "  Local branch for which remote was deleted: {}".format(branch))
    if any(stash):
      printWithStyle(Style.LCYAN, "  Stashed changes")
    for item in changes:
      if item.change_type.startswith('M'):
        printWithStyle(Style.ORANGE, "  Modified: {}".format(item.a_path))
      elif item.change_type.startswith('D'):
        printWithStyle(Style.RED, "  Deleted: {}".format(item.a_path))
      elif item.change_type.startswith('R'):
        printWithStyle(Style.GREEN, "  Renamed: {} -> {}".format(item.a_path, item.b_path))
      elif item.change_type.startswith('A'):
        printWithStyle(Style.GREEN, "  Added: {}".format(item.a_path))
      elif item.change_type.startswith('U'):
        printWithStyle(Style.Error, "  Unmerged: {}".format(item.a_path))
      elif item.change_type.startswith('C'):
        printWithStyle(Style.GREEN, "  Copied: {} -> {}".format(item.a_path, item.b_path))
      elif item.change_type.startswith('T'):
        printWithStyle(Style.ORANGE, "  Type changed: {}".format(item.a_path))
      else:
        printWithStyle(Style.RED, "  Unhandled change type '{}': {}".format(item.change_type, item.a_path))
    if len(repo.untracked_files) < 10:
      for file in repo.untracked_files:
        printWithStyle(Style.DGRAY, "  Untracked: {}".format(file))
    else:
      printWithStyle(Style.DGRAY, "  {} untracked files.".format(len(repo.untracked_files)))
    print("")
  elif repo.is_dirty():
    printWithStyle(Style.Error, "  Dirty but I don't know why")
    print("")


class WsToolInfo:
  def __init__(self, git, version):
    self.git = git
    self.version = version


if __name__ == "__main__":
  parser = argparse.ArgumentParser(prog="status", description="Scans your workspace for local changes in your repositories.")
  parser.add_argument("--show-all", action='store_true', default=False, help="Show all repositories including those that are not dirty.")
  args = parser.parse_args()
  argcomplete.autocomplete(parser)

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
    parts = item.decode().split(",")
    ws_tool_paths[parts[0]] = WsToolInfo(parts[1] == "git", parts[2])

  def scanWorkspace(path):
    if not os.path.isdir(path):
      return
    try:
      subdirs = os.listdir(path)
    except Exception as e:
      printWithStyle(Style.Error, "Error while scanning '{}'!\nMessage: {}".format(path, str(e)))
      return
    if ".git" in subdirs:
      printChanges(path, show_all=args.show_all, base_path=ws_src_path)
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
