(defun pckInstTree ()
  (let (indexTree treeField treeItem form instId)
    
    (setq winId (hiGetCurrentWindow))
    (setq cvId (geGetEditCellView winId))

    ;; create a root tree
    (setq indexTree (hiCreateTree (quote index)))
    
    ;; create tree items and append them to the root tree
    (foreach inst (dbGetq cvId instances)
             (setq treeItem (hiCreateTreeItem (stringToSymbol (dbGetq inst name)) (list (dbGetq inst cellName) (dbGetq inst name) (dbGetq inst libName))))
             (hiTreeAppendItem indexTree treeItem))

    ;; create tree table and use indexTree as the value for ?choice
    (setq treeField (hiCreateTreeTable
                                  ?name 'treeField
                                        ?title "Use <CTL> for multiple selections"
                                        ?titleAlignment 'center
                                        ?headers list(list("CellName" 150 'left 'string t) 
                                                          list("InstName" 100 'left 'string)
                                                          list("Library" 200 'center 'string)
                                                          )
                                        ?choice indexTree
                                        ?callback "instTreeCB"
                                        ?enableDeselectCB t
                                        ?selectMode 'extended
                                        ?sort (list 0 nil)
                                        ))
    
    ;; create a form
    (setq form (hiCreateAppForm
                           ?name 'form
                                 ?formTitle "Toggle Instance Selector"
                                 ?fields list(
                                              list(treeField 5:5 400:200 55)
                                                  )
                                 ?initialSize 750:250))
    
    hiDisplayForm(form)
    t))


(defun instTreeCB (name itemSymList)
                   (setq instId ())
                 while(itemSymList
                       itemSym=car(itemSymList)
                       (foreach inst (dbGetq cvId instances)
                                (when (rexMatchp (symbolToString itemSym) (dbGetq inst name))
                                  (setq instId (cons inst instId))))
                       itemSymList=cdr(itemSymList)
                       )
                 (pckToggleInst winId instId)
)



(defun pckToggleInst (win instSelect)
  (let (cv) 
    (putpropq win 0 stopLevel)
    (setq cv (geGetEditCellView win))
       
    (foreach inst (dbGetq cv instances)
             (setq depth (secondElement (geGetInstViewLevel win inst)))
             (unless (equal (dbGetq inst objType) "mosaicInst")

             (if (and depth (member inst instSelect))
                 (progn
                      (geDeleteInstViewLevel win inst))
                 (progn
                   (unless (member inst instSelect)
                        (geSetInstViewLevel win inst 0 (dbGetMaxHierDepth)))))))

       (foreach mosaic (dbGetq cv mosaics)
                (setq depth (secondElement (geGetInstViewLevel win mosaic)))
                (if (and depth (member mosaic instSelect))
                    (progn
                      (geDeleteInstViewLevel win mosaic))
                    (progn               
                      (unless (member mosaic instSelect)
                        (geSetInstViewLevel win mosaic 0 (dbGetMaxHierDepth))))))
       t
       ))


