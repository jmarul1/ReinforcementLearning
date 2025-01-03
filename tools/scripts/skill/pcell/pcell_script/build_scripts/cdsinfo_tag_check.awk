BEGIN {
  cdslibrary_flag=0;
  namespace_flag=0;
  dmtype_flag=0;
}
$1 == "CDSLIBRARY" {
  cdslibrary_flag=1;
}
$1 == "NAMESPACE" && $2 == "LibraryUnix" {
  namespace_flag=1;
}
$1 == "DMTYPE" {
  dmtype_flag=1;
}
{ next; }
END {
  if (!cdslibrary_flag || !namespace_flag || dmtype_flag) {
    exit 1;
  }
}
