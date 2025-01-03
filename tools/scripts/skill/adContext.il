procedure( adLoadContextDir(cxtDir)
let( (recLoad)
  when(isDir(cxtDir)
    recLoad = lambda( (dn fpat @optional (func 'loadi))
    cond(
      (rexMatchp("\\.$" dn) nil)
      (rexMatchp("\\.\\.$" dn) nil)
      (rexMatchp("\\.SYNC$" dn) nil)
      (isDir(dn)
	mapcar(lambda( (fn) 
          let( (ffn)
	    ffn = strcat(dn "/" fn)
	    cond(
	      (and(isDir(ffn) fn!="64bit") (apply recLoad (list ffn fpat func)))
	      (and(isFile(ffn) rexMatchp(fpat fn))
		printf(">> Executing %s(%L)\n" get_pname(func) ffn)
		when(func apply(func list(ffn))) )
	    );cond
	)) getDirFiles(dn)) ) 
      );cond
    t
    );lambda function
    if(system.ILP32 then apply(recLoad list(cxtDir "\\.cxt$" 'loadContext))
    else apply(recLoad list( strcat(cxtDir "/64bit") "\\.cxt$" 'loadContext)) );if
    apply(recLoad list(cxtDir "\\.ile$" 'loadi))
    apply(recLoad list(cxtDir "\\.ils$"  'loadi))
    apply(recLoad list(cxtDir "\\.il$"  'loadi))    
  );when
));let

