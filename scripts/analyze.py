#!/usr/bin/env python
# PYTHON_ARGCOMPLETE_OK
# This script will analyze the workspace for errors.
# It can be run recursively on the whole workspace, on a single package or recursively on a path
import argparse
try:
  import argcomplete
  __argcomplete = True
except ImportError:
  __argcomplete = False
from catkin_pkg.packages import find_packages
import os


class PkgPathChoicesCompleter:
  def __init__(self, workspace_path):
    self.workspace_path = workspace_path
    self.directory_completer = argcomplete.completers.DirectoriesCompleter()

  def __call__(self, **kwargs):
    packages = find_packages(workspace_path)
    return [packages[path].name for path in packages] + list(self.directory_completer(**kwargs))

class RuleChoicesCompleter:
  def __call__(self, **kwargs):
    workspace_scripts = os.environ.get("ROSWSS_SCRIPTS", "").split(':')
    workspace_scripts = [ws for ws in workspace_scripts if len(ws) != 0]
    rules = []
    for path in workspace_scripts:
      rules_dir = os.path.split(path)[1]
      rules_dir_path = os.path.join(path, "rules")
      if not os.path.isdir(rules_dir_path):
        continue
      for f in os.listdir(rules_dir_path):
        if not f.endswith(".py"):
          continue
        rules.append(os.path.splitext(f)[0])
    return rules


if __name__ == "__main__":
  workspace_path = os.environ.get("ROS_WORKSPACE")
  parser = argparse.ArgumentParser(description="Analyzes the workspace, a package or a directory using a set of rules to ensure proper coding standards.")
  target_arg = parser.add_argument("target", default=None, metavar="PATHS_OR_PKGS", nargs='*')
  parser.add_argument("-s", "--strict", action="store_true", default=False)
  parser.add_argument("--this", action="store_true", default=False)
  rules_arg = parser.add_argument("-r", "--rules", nargs="+")
  if __argcomplete:
    target_arg.completer = PkgPathChoicesCompleter(workspace_path)
    rules_arg.completer = RuleChoicesCompleter()
    argcomplete.autocomplete(parser)
  args = parser.parse_args()

  import os
  import sys
  if sys.version_info >= (3,5):
    from importlib.util import spec_from_file_location, module_from_spec

    def load_rule(name, path):
      spec = spec_from_file_location(name, path)
      module = module_from_spec(spec)
      spec.loader.exec_module(module)
      return module.Rule()
  else:
    import imp

    def load_rule(name, path):
      module = imp.load_source(name, path)
      return module.Rule()

  class Style:
    Error='\033[0;31m'
    Warning='\033[0;33m'
    Info='\033[0;34m'
    Reset='\033[0;39m'

  def printWithStyle(style, msg):
    print(style + msg + Style.Reset)

  def check_package(path, package, rules, strict=False):
    header_printed = False
    no_error = True
    for key in rules:
      result = rules[key].check(path, package)
      if (not "errors" in result or len(result["errors"]) == 0)\
        and (not "warnings" in result or len(result["warnings"]) == 0)\
          and (not strict or not "notices" in result or len(result["notices"]) == 0):
          continue
      if not header_printed:
        printWithStyle(Style.Info, ">>> " + package.name)
        header_printed = True
      if "errors" in result:
        for error in result["errors"]:
          printWithStyle(Style.Error, error)
          no_error = False
      if "warnings" in result:
        for warning in result["warnings"]:
          printWithStyle(Style.Warning, warning)
          no_error = False
      if strict and "notices" in result:
        for notice in result["notices"]:
          print(notice)
          no_error = False
    return no_error

  # START OF MAIN
  if len(workspace_path) == 0:
    print("Could not locate workspace root. Is environment variable 'ROS_WORKSPACE' defined?")
    exit(1)
  packages = find_packages(workspace_path)

  # Load rules
  workspace_scripts = os.environ.get("ROSWSS_SCRIPTS", "").split(':')
  workspace_scripts = [ws for ws in workspace_scripts if len(ws) != 0]
  if len(workspace_scripts) == 0:
    print("No workspace scripts found! Is environment variable ROSWSS_SCRIPTS defined?")
    exit(1)
  # Gather rule scripts which have to be in a rules subfolder
  rules = {}
  for path in workspace_scripts:
    rules_dir = os.path.split(path)[1]
    rules_dir_path = os.path.join(path, "rules")
    if not os.path.isdir(rules_dir_path):
      continue
    for f in os.listdir(rules_dir_path):
      if not f.endswith(".py"):
        continue
      rule_name = os.path.splitext(f)[0]
      if args.rules is not None and len(args.rules) != 0 and not rule_name in args.rules:
        continue
      module_name = "{}_{}".format(rules_dir, rule_name)
      if module_name in rules:
        printWithStyle("Duplicate rule detected: {}!".format(module_name))
      rules[rule_name] = load_rule(module_name, os.path.join(rules_dir_path, f))
  if args.rules is not None:
    for rule_name in args.rules:
      if not rule_name in rules:
        printWithStyle(Style.Error, "Rule {} not found!".format(rule_name))
  if args.this:
    current_path = os.getcwd()
    package_path = None
    len_match = 0
    if current_path.startswith(workspace_path):
      current_path = os.path.relpath(current_path, workspace_path)
      for path in packages:
        if current_path.startswith(path) and len(path) > len_match:
          package_path = path
          len_match = len(path)
    if package_path is None:
      printWithStyle(Style.Error, "Current path is not a catkin package!")
    elif check_package(os.path.join(workspace_path, package_path), packages[package_path], rules, strict=args.strict):
      printWithStyle(Style.Info, "1 package checked and no errors found! Great!")
  elif args.target is None or len(args.target) == 0:
    no_error = True
    for path in packages:
      no_error &= check_package(os.path.join(workspace_path, path), packages[path], rules, strict=args.strict)
    if no_error:
      printWithStyle(Style.Info, "{} packages checked and no errors found! Great!".format(len(packages)))
  else:
    no_error = True
    to_check=list(args.target)
    count = 0
    for pkg in to_check:
      if_dir_path = os.path.abspath(os.path.join(os.path.curdir, pkg))
      is_dir = os.path.isdir(if_dir_path)
      found = False
      for path in sorted(packages):
        is_package = packages[path].name == pkg
        if not is_package and not is_dir:
          continue
        if is_package and is_dir and not if_dir_path == path:
          while True:
            answer = raw_input("{} is both a package and a local subdirectory. Which one should I check? (D)irectory/(P)ackage".format(pkg))
            if answer == "D" or answer == "d":
              is_package = False
              break
            if answer == "P" or answer == "p":
              is_dir = False
              break
            print("Please enter either D or P!")
        if is_package:
          no_error &= check_package(os.path.join(workspace_path, path), packages[path], rules, strict=args.strict)
          found = True
          count += 1
          break
      if is_dir:
        for path in sorted(packages):
          if not packages[path].filename.startswith(if_dir_path):
            continue
          no_error &= check_package(os.path.join(workspace_path, path), packages[path], rules, strict=args.strict)
          found = True
          count += 1
      if is_package and not found:
        printWithStyle(Style.Error, "Could not find '{}' in workspace '{}'!".format(pkg, workspace_path))
    if no_error:
      printWithStyle(Style.Info, "{} packages checked and no errors found! Great!".format(count))
