;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Intel Top Secret                                                         ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Copyright (C) 2014, Intel Corporation.  All rights reserved.             ;;
;;                                                                          ;;
;; This is the property of Intel Corporation and may only be utilized       ;;
;; pursuant to a written Restricted Use Nondisclosure Agreement             ;;
;; with Intel Corporation.  It may not be used, reproduced, or              ;;
;; disclosed to others except in accordance with the terms and              ;;
;; conditions of such agreement.                                            ;;
;;                                                                          ;;
;; All products, processes, computer systems, dates, and figures            ;;
;; specified are preliminary based on current expectations, and are         ;;
;; subject to change without notice.                                        ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  fdkFindFiles
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
putd( 'fdkFindFiles nil )
procedure(

  fdkFindFiles(
    dirpath
  @key
    (path_prune_func lambda((p) isDir(p) && rexMatchp("^\\." car(last(parseString(p "/"))))))
    (fname_match_func lambda((fn) rexMatchp("\\.il$" fn)))
  )

let((fpath_list full_path)

  ;;; Do a breadth-first search of all the relevant filenames
  ;;; at the current directory level to make sure these
  ;;; definitions are available for code defined at
  ;;; lower levels of hierarchy.
  foreach( fname sort(getDirFiles(dirpath) nil)
    sprintf(full_fpath "%s/%s" dirpath fname)
    when( !funcall(path_prune_func full_fpath)
      when( !isDir(full_fpath)
        when( funcall(fname_match_func fname)
          fpath_list = cons(full_fpath fpath_list)
        )
      )
    )
  )
  fpath_list = reverse(fpath_list)

  ;;; Recursively scan subdirectories to add any files from them
  foreach( fname sort(getDirFiles(dirpath) nil)
    sprintf(full_fpath "%s/%s" dirpath fname)
    when( !funcall(path_prune_func full_fpath)
      when( isDir(full_fpath)
      let((subdir_fpath_list)
        subdir_fpath_list = fdkFindFiles(
                              full_fpath
                              ?path_prune_func path_prune_func
                              ?fname_match_func fname_match_func
                            )
        fpath_list = append(fpath_list subdir_fpath_list)
      ))
    )
  )

fpath_list))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  fdkScanForSkillFiles
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
putd( 'fdkScanForSkillFiles nil )
procedure(

  fdkScanForSkillFiles(
    dirpath
  @key
    (path_prune_func lambda((p) isDir(p) && rexMatchp("^\\." car(last(parseString(p "/"))))))
  )

  fdkFindFiles(dirpath ?path_prune_func path_prune_func ?fname_match_func lambda((fn) rexMatchp("\\.il$" fn)))

)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  fdkScanForTclFiles
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
putd( 'fdkScanForTclFiles nil )
procedure(

  fdkScanForTclFiles(
    dirpath
  @key
    (path_prune_func lambda((p) isDir(p) && rexMatchp("^\\." car(last(parseString(p "/"))))))
  )

  fdkFindFiles(dirpath ?path_prune_func path_prune_func ?fname_match_func lambda((fn) rexMatchp("\\.tcl$" fn)))

)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  fdkScanForPythonFiles
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
putd( 'fdkScanForPythonFiles nil )
procedure(

  fdkScanForPythonFiles(
    dirpath
  @key
    (path_prune_func lambda((p) isDir(p) && rexMatchp("^\\." car(last(parseString(p "/"))))))
  )

  fdkFindFiles(dirpath ?path_prune_func path_prune_func ?fname_match_func lambda((fn) rexMatchp("\\.py$" fn)))

)
