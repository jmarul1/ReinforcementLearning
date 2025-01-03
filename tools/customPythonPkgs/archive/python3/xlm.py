### xlm plays

class read():
  def __init__(self,xlmFile):
    with open(xlmFile) as fin:
      self.content = fin.read()
      
  def getTag(self,tag): #tag is a \w
    import re
    test = re.search(fr'(\<{tag}\b.*?\</{tag}.*?\>)|(\<{tag}\b.*?/>)',self.content,flags=re.DOTALL)
    if test: return test.group(1) or test.group(2)
    else: return False

  def remove(self,tags):
    import re
    for tag in tags:
      regex = fr'\s*(\<{tag}\b.*?\</{tag}.*?\>)|(\<{tag}\b.*?/>)\s*'
      self.content = re.sub(regex,'',self.content,flags=re.DOTALL)

  def write(self,tgt):
    with open(tgt,'w') as fout: fout.write(self.content)
