from catkin_lint.environment import CatkinEnvironment
from catkin_lint.linter import CMakeLinter, ERROR, WARNING, NOTICE
from catkin_lint.main import add_linter_check
import os

class Rule:
  env=None
  linter=None
  def __init__(self):
    self.env = CatkinEnvironment(os_env=os.environ, quiet=True)
    if not self.env.ok:
      return
    if "ROS_PACKAGE_PATH" in os.environ:
      for pkg_path in os.environ["ROS_PACKAGE_PATH"].split(os.path.sep):
        self.env.add_path(pkg_path)
    self.linter = CMakeLinter(self.env)
    add_linter_check(self.linter, "all")

  def check(self, path, pkg):
    if not self.env.ok:
      return {"errors": ["Failed to initialize CatkinEnvironment!"]}
    
    # self.env.add_path(path)
    # try:
    #   path, manifest = self.env.find_local_pkg(pkg.name)
    # except KeyError:
    #   return {"errors": ["Could not find package '{}' in '{}'!".format(pkg.name, path)]}
    try:
      self.linter.lint(path, pkg)
    except Exception as err:
      return {"errors": ["catkin_lint - Failed to lint: {}".format(str(err))]}
    errors = []
    warnings = []
    notices = []
    for msg in sorted(self.linter.messages):
      msg_loc = msg.package
      if msg.file:
        msg_loc = "{}:{}".format(msg.file, msg.line) if msg.line else msg.file
        msg_loc = "{}: {}".format(msg.package, msg_loc)
      if msg.level == ERROR:
        errors.append("{}: {}".format(msg_loc, msg.text))
      elif msg.level == WARNING:
        warnings.append("{}: {}".format(msg_loc, msg.text))
      elif msg.level == NOTICE:
        notices.append("{}: {}".format(msg_loc, msg.text))
    self.linter.messages = []
    return {"errors": errors, "warnings": warnings, "notices": notices}
