# Copy this file (must be in a scripts subfolder named rules), rename it to end in .py and modify the rule to your liking

# This class must be called Rule
class Rule:
  # The rule is constructed once per analyze call. Do costly initializations here
  def __init__(self):
    pass
  
  # This method is called for each pkg and should return a dictionary with a list of errors,
  # warnings and notices. The last are only printed if argument --strict is provided
  def check(self, path, pkg):
    return {"errors": [], "warnings": [], "notices": []}
