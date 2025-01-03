;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Intel Top Secret                                                         ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Copyright (C) 2013, Intel Corporation.  All rights reserved.             ;;
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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;   fdkCustomCopyFilesToWorkDir
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
putd( 'fdkCustomCopyFilesToWorkDir nil )
procedure(

  fdkCustomCopyFilesToWorkDir(
    src_fpath_list dest_dirpath
  )
  
let((oport error_flag)

  foreach( src_fpath src_fpath_list
  let((iport dest_fname dest_fpath oport l)
    if( !inportp(iport = infile(src_fpath))
    then fprintf(stderr "ERROR: Couldn't open file %L for reading\n" src_fpath)
         error_flag = t
    else dest_fname = car(reverse(parseString(src_fpath "/")))
         sprintf(dest_fpath "%s/%s" dest_dirpath dest_fname)
         if( !outportp(oport = outfile(dest_fpath))
         then fprintf(stderr "ERROR: Couldn't open file %L for writing\n" dest_fpath)
              error_flag = t
         else while( gets(l iport)
                fprintf(oport "%s" l)
              )
              when( !close(oport)
                fprintf(stderr "ERROR: Couldn't finish writing to file %L\n" dest_fpath)
                deleteFile(dest_fpath)
                error_flag = t
              )
         )
         when( !close(iport)
           fprintf(stderr "ERROR: Couldn't finish reading file %L\n" src_fpath)
           error_flag = t
         )
    )
  ))

!error_flag))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;   fdkCustomRecursivelyDeleteDir
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
putd( 'fdkCustomRecursivelyDeleteDir nil )
procedure(

  fdkCustomRecursivelyDeleteDir(
    dirpath
  )
  
let((error_flag)

  foreach( nm getDirFiles(dirpath)
    when( !member(nm '("." ".." ".snapshot"))
    let((path)
      sprintf(path "%s/%s" dirpath nm)
      if( isDir(path)
      then when( !fdkCustomRecursivelyDeleteDir(path)
             error_flag = nil
           )
      else when( !deleteFile(path)
             fprintf(stderr "ERROR: Couldn't remove file %L\n" path)
           )
      )
    ))
  )
  when( !deleteDir(dirpath)
    fprintf(stderr "ERROR: Couldn't remove directory %L\n" dirpath)
    error_flag = t
  )

!error_flag))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;   fdkCustomGenAndLoadModelSelCallbacks
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
putd( 'fdkCustomGenAndLoadModelSelCallbacks nil )
procedure(

  fdkCustomGenAndLoadModelSelCallbacks(
    gen_script_fpath csv_fpath
  )
  
let((fdk_managed_area fdk_work work_dirpath start_fname_list gen_script_fname error_flag)

  cond(
    ( !stringp(fdk_managed_area = getShellEnvVar("FDK_MANAGED_AREA")) || blankstrp(fdk_managed_area)
      fprintf(stderr "ERROR: FDK_MANAGED_AREA env var is not defined.\n")
      error_flag = t
    )
    ( !stringp(fdk_work = getShellEnvVar("FDK_WORK")) || blankstrp(fdk_work)
      fprintf(stderr "ERROR: FDK_WORK env var is not defined.\n")
      error_flag = t
    )
    ( !stringp(work_dirpath = makeTempFileName(sprintf(nil "%s/p1273buildXXXX" fdk_work)))
      fprintf(stderr "ERROR: Couldn't generate work dir path\n")
      error_flag = t
    )
    ( !createDir(work_dirpath)
      fprintf(stderr "ERROR: Couldn't create work directory %L\n" work_dirpath)
      error_flag = t
    )
    ( !fdkCustomCopyFilesToWorkDir(list(gen_script_fpath csv_fpath) work_dirpath)
      fprintf(stderr "ERROR: Couldn't copy model files to work dir %L\n" work_dirpath)
      error_flag = t
    )
    ( !dtpr(start_fname_list = getDirFiles(work_dirpath))
      fprintf(stderr "ERROR: No files in work dir %L after copy?!\n" work_dirpath)
      error_flag = t
    )
    ( progn(
        gen_script_fname = car(reverse(parseString(gen_script_fpath "/")))
        !sh(sprintf(nil "cd %L && . %L" work_dirpath gen_script_fname))
      )
      fprintf(stderr "ERROR: executing model sel script %L in work dir %L\n" gen_script_fname work_dirpath)
      error_flag = t
    )
    ( t foreach( fname getDirFiles(work_dirpath)
          when( !member(fname start_fname_list) && rexMatchp("MS\\.il$" fname)
          let((fpath)
            sprintf(fpath "%s/%s" work_dirpath fname)
            when( !errset(load(fpath) t)
              fprintf(stderr "ERROR: Couldn't load %L in work dir %L\n" fname work_dirpath)
              error_flag = t
            )
          ))
        )
    )
  )

  if( error_flag
  then when( isDir(work_dirpath)
         fprintf(stderr "Model-selection generation work directory has been left at %L\n" work_dirpath)
       )
  else when( isDir(work_dirpath)
         fdkCustomRecursivelyDeleteDir(work_dirpath)
       )
  )

!error_flag))
