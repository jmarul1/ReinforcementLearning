def shorten(longString,width):
  """Whitespace replaced to single. If result fits in width, return it. If result > width
  then keep text of width-5( ... ) and output the inserted " ... " as longgggg" ... "Stringgggg"""
  longString = longString.strip()
  if len(longString)<width: return longString
  else:
    firstI,last = int(width/2)-2,width-int(width/2)-3
    longString = longString[0:firstI] + ' ... ' + longString[len(longString)-last:] 
    return longString
