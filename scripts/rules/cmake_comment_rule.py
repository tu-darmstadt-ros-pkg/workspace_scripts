import os
import re

class Rule:
  def __init__(self):
    pass
  
  def check(self, path, pkg):
    if not os.path.isfile(os.path.join(path, "CMakeLists.txt")):
      return {"warnings": ["Could not find a CMakeLists.txt."]}
    with open(os.path.join(path, "CMakeLists.txt"), "r") as f:
      lines = f.readlines()
    pattern = re.compile("^\s*#")
    comments = 0
    for line in lines:
      if pattern.match(line) is not None:
        comments += 1
    if comments > 20:
      comment_percentage = comments * 1.0 / len(lines)
      error_type = None
      if comment_percentage > 0.5:
        error_type = "errors"
      elif comment_percentage > 0.2:
        error_type = "warnings"

      if error_type is not None:
        return {error_type: ["CMakeLists.txt consists of more than {}% line comments.".format(int(comment_percentage * 100))], "notices": []}
    return {"errors": [], "warnings": [], "notices": []}
