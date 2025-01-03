procedure( fdkLibanaType(typeDisplayed)
    let((actualType)
        case(typeDisplayed
              ("center-tap"
                  actualType = "ctp"
              )
              ("left-tap"
                  actualType = "ltp"
              )
              ("right-tap"
                  actualType = "rtp"
              )
              ("center-tap1"
                  actualType = "ct1"
              )
              ("center-tap2"
                  actualType = "ct2"
              )
              ("nwell use"
                  actualType = "ct2"
              )
              ("overlay"
                  actualType = "ovr"
              )
              ("outside corner-left"
                  actualType = "clo"
              )
              ("outside corner-right"
                  actualType = "cro"
              )
              ("inside corner-left"
                  actualType = "cli"
              )
              ("inside corner-right"
                  actualType = "cri"
              )
              ("side-left"
                  actualType = "slx"
              )
              ("side-right"
                  actualType = "srx"
              )
              ("top-bottom"
                  actualType = "tbx"
              )
              ("abut enabled outside corner-left"
                  actualType = "clo_special"
              )
              ("abut enabled outside corner-right"
                  actualType = "cro_special"
              )
              ("abut enabled side-left"
                  actualType = "slx_special"
              )
              ("abut enabled side-right"
                  actualType = "srx_special"
              )
              ("abut enabled top-bottom"
                  actualType = "tbx_special"
              )
              ("sdx"
                  actualType = "sdx"
              )
              ("cox"
                  actualType = "cox"
              )
              ("left-edge"
                  actualType = "lft"
              )
              ("right-edge"
                  actualType = "rgt"
              )
              ("lowerLeft-corner"
                  actualType = "cl2"
              )
              ("upperLeft-corner"
                  actualType = "cl1"
              )
              ("lowerRight-corner"
                  actualType = "cr2"
              )
              ("upperRight-corner"
                  actualType = "cr1"
              )
              ("top-edge"
                  actualType = "tb1"
              )
              ("bottom-edge"
                  actualType = "tb2"
              )
              ("gnc"
                  actualType = "gnc"
              )
              ("spacer"
                  actualType = "spacer"
              )
              (t
               err("Unknown type selected")
              ) 
     )
     actualType
  )
)

                    
           