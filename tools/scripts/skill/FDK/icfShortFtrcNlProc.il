;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; ICFshortFtrcNlProc(l_netDPL)
; 
; custom auCdl netlisting procedure to short a 3-terminal parasitic resistor.
; the goal of this procedure is to short the PLUS MINUS pins (*.CONNECT)
; and leave the the third terminal dangling 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

procedure(ICFshortFtrcNlProc(netDPL)
  let(((fp netDPL->fd->fp))
    artFprintf(fp "*.CONNECT ")
    ancPrintTerminals(netDPL)
    artFprintf(fp "\n")
  )
)