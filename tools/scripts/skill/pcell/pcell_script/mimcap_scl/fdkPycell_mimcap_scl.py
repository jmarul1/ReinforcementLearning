# * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
#
# Filename: mimcap.py 
#
##############################################################################
## Intel Top Secret                                                         ##
##############################################################################
## Copyright (C) 2010, Intel Corporation.  All rights reserved.             ##
##                                                                          ##
## This is the property of Intel Corporation and may only be utilized       ##
## pursuant to a written Restricted Use Nondisclosure Agreement             ##
## with Intel Corporation.  It may not be used, reproduced, or              ##
## disclosed to others except in accordance with the terms and              ##
## conditions of such agreement.                                            ##
##                                                                          ##
## All products, processes, computer systems, dates, and figures            ##
## specified are preliminary based on current expectations, and are         ##
## subject to change without notice.                                        ##
##############################################################################
# * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
# Original Authors: Mike Farabee & Steve Osugi
# Known bugs: None 
#
# Enhancements: 
# MikeF 1/25/2011 changed pin length to 0.001 as per request
# MikeF 2/3/2011 changed pin length to default width. 0.001 was too small to hit
#
# To-Do List:
#
#* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
#
# RCS Information:

#   $Author: kflowers $
#   $Source: /nfs/pdx/disks/icf_f1273_dsvault001/sync_vault/server_vault/Projects/fdk73/oalibs/common/custom/package/mimcap_scl/fdkPycell_mimcap_scl.py.rca $
#   $Date: Thu Oct 15 14:42:07 2015 $
#   $Revision: 1.10 $#
#   
#
#* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

from cni.dlo import *
from cni.geo import *
from cni.constants import *
from cni.integ.common import (stretchHandle)
from cni.integ.common import (autoAbutment)
import os
from fdkUtils import *

class mimcap_scl(DloGen):

    VERSION = '$Revision: 1.10 $'
    
    # Dictionary of all global class parameters
    # These parameters willdefine the look and feel of the GUI and impact all SUB classes
    myGCP = { 
        'PROCESS_GRID':0.001 ,
        'MIN_FEATURE_SIZE':0.001 ,
        'MAX_FEATURE_SIZE':1000 ,
    }
    
    ####################################
    # Subroutine: getGCP
    # Description: Generic subroutine to return the value of any global class parameter
    # If the parameter does not exist, "None" is returned
    ####################################
    @classmethod
    def getGCP(cls,key):
        if key in cls.myGCP:
            result = cls.myGCP[key]
        else:
            result = None
        return result
    # end def getGCP

    ####################################
    # Subroutine: setGCP
    # Description: Generic subroutine to set the value of any global class parameter
    # An exception will be raised, if the parameter is not predefined.
    ####################################
    @classmethod
    def setGCP(cls,key,value):
        if key in cls.myGCP:
            cls.myGCP[key] = value
        else:
            raise 
    # end def setGCP

    ####################################
    # Subroutine: listGCP
    # Description: Generic subroutine to list all valid global class parameters
    # Returns a sorted list 
    ####################################
    @classmethod
    def listGCP(cls):
        return(sorted(cls.myGCP.keys()))

    ####################################
    # Subroutine: defineParamSpecs
    # Description: Required PyCell method that defines User control
    #      This builds the interfacce parameters
    ####################################
    @classmethod
    def defineParamSpecs (cls, specs):

        # reads property bag information into myDr dictionary
        cls.myDr={}
        fdkUtils.readPropBag(cls.myDr)

        specs('w',"%4.3fu"%(cls.myDr['defaults']['minMimWidth']))
        specs('ldrawn',"%4.3fu"%(cls.myDr['defaults']['minMimLength']))
        specs('viaOffsetL',"%4.3fu"%(cls.myDr['defaults']['minViaOffsetL']))
        specs('viaOffsetR',"%4.3fu"%(cls.myDr['defaults']['minViaOffsetR']))
        #specs('viaType',cls.myDr['designRules']['viaList'][0],'viaChoices',ChoiceConstraint(cls.myDr['designRules']['viaList']))
        specs('viaType',cls.myDr['defaults']['viaTypeVal'])
        specs('metType',cls.myDr['defaults']['metType'])
        specs('stacked',cls.myDr['defaults']['stacked'])
#        specs('viaRotate',True)
    # end def defineParamSpecs


    ####################################
    # Subroutine: setupParams
    # Description: Required PyCell method that loads user values
    #     If options are not allowed in the GUI, then set them to a default value.
    ####################################
    def setupParams (self,params):
        processGrid = Grid(self.getGCP("PROCESS_GRID"))
        self.w= processGrid.snap(Numeric(params['w'])/Numeric.scale_factors["u"],SnapType.CEIL)
        self.ldrawn= processGrid.snap(Numeric(params['ldrawn'])/Numeric.scale_factors["u"],SnapType.CEIL)
        self.viaOffsetR= processGrid.snap(Numeric(params['viaOffsetR'])/Numeric.scale_factors["u"],SnapType.CEIL)
        self.viaOffsetL= processGrid.snap(Numeric(params['viaOffsetL'])/Numeric.scale_factors["u"],SnapType.CEIL)
        self.viaType=params['viaType']
        self.metType=params['metType']
        self.stacked=params['stacked']
#        self.viaRotate=params['viaRotate']
    # end def setupParams

    ####################################
    # Subroutine: setMyOrigin
    # Description: Located shape with origin tag and sets this shape as the origin of the cell
    # Trick: Needed to "getBBox" of the shape because the shape could be a rectangle or a path.
    #        Path objects do not have a getCoord method.
    #        You can do a getCoord on a rect or a bbox, but not a path.
    #        but you can get a bbox for a path and then do a getCoord.
    #        This allows common processing for both rects and paths
    ####################################
    def setMyOrigin (self,xDirection,xOffset,yDirection,yOffset):
        originObject = PhysicalComponent.find('origin') # find shape with "origin" name
        if originObject != None:
            bbox=originObject.getBBox()
            xCoord=bbox.getCoord(xDirection)
            yCoord=bbox.getCoord(yDirection)
            self.setOrigin(Point(xCoord+xOffset,yCoord+yOffset))
        else:
            print "ERROR: Can't set origin, no origin object!"
    # end def setMyOrigin

    ####################################
    # Subroutine: drawVia
    # Description: Builds an array (group) of via cuts based on rowCount
    ####################################
    def drawVia (self,Layer, width, length, space, rowCount, colCount):
        myGroup = Grouping( components = [] )
        processGrid = self.processGrid
        length = fdkUtils.fdkSnapGrid(processGrid,length)
        width = fdkUtils.fdkSnapGrid(processGrid,width)
        space = fdkUtils.fdkSnapGrid(processGrid,space)
        prevRect = None
        prevCol = None
        if length >0.0 and width >0.0:
            for colIndex in range(1,(colCount+1)):
                myCol = Grouping( components = [] )
                for rowIndex in range(1,(rowCount+1)):
                    rect=Rect(Layer,Box(0.0,0.0,length,width))
                    if prevRect != None:
                        rect.alignEdge(SOUTH,prevRect,refDir=NORTH,offset=space)
                    myCol.add(rect)
                    prevRect=rect

                if prevCol != None:
                    myCol.alignEdge(WEST,myGroup,refDir=EAST,offset= space)
                    myCol.alignEdge(NORTH,myGroup,refDir=NORTH)
                prevCol=myGroup
                myGroup.add(myCol)
        return myGroup
    # end def drawVia

    ####################################
    # Subroutine: drawMetal
    # Description: Builds an array (group) of via cuts based on rowCount
    ####################################
    def drawMetal (self, vias, botPinName, botTermName, LayerBot,
                   enclosure, minWBot, topPinName, topTermName, LayerTop,
                   coverage, minWTop, pinLayerBottom, pinLayerTop):
        myGroup = Grouping( components = [] )
        #no longer one big bottom piece...customer wants to connect or fill as needed
        #bboxBot=vias.getBBox()
        #bboxBot.expand(enclosure)

        # Build bottom metals for each via: not one big bottom piece
        viaCt=0
        minWBot = fdkUtils.fdkSnapGrid(self.processGrid,minWBot)
        minWTop = fdkUtils.fdkSnapGrid(self.processGrid,minWTop)
        enclosure = fdkUtils.fdkSnapGrid(self.processGrid,enclosure)
        for viaGroup in vias.getComps():
            for via in viaGroup.getComps():
                viaCt=viaCt+1
                #print("viaCt",viaCt,"for botTermName",botTermName,"for topTermName",topTermName)
                bboxBot=via.getBBox()
                bboxBot.expand(enclosure)
                if bboxBot.getWidth() < minWBot :
                    bboxBot.expandForMinWidth(EAST_WEST,minWBot)
                botRect=Rect(LayerBot,bboxBot)
                if botPinName != None:
                    botPin=Pin(botPinName,botTermName,botRect)
                    botPin.setAccessDir(Direction.ANY)
                    if pinLayerBottom != None:
                        rectPin=Rect(pinLayerBottom,bboxBot)
                        text=Text(pinLayerBottom,botTermName,bboxBot.centerCenter(),2.0)
                        text.setVisible(True)
                        text.setFont(Font.ROMAN)
                        text.setOrientation(Orientation.R90)
                        myGroup.add(text)
                        myGroup.add(rectPin)
                myGroup.add(botRect)

        # Build top metals
        bboxTop=vias.getBBox()
        bboxTop.expand(coverage)
        if bboxTop.getWidth() < minWTop :
            bboxTop.expandForMinWidth(EAST_WEST,minWTop)
        topRect=Rect(LayerTop,bboxTop)
        if topPinName != None:
            topPin=Pin(topPinName,topTermName,topRect)
            topPin.setAccessDir(Direction.ANY)
            if pinLayerTop != None:
                rectPin=Rect(pinLayerTop,bboxTop)
                text=Text(pinLayerTop,topTermName,bboxTop.centerCenter(),2.0)
                text.setVisible(True)
                text.setFont(Font.ROMAN)
                text.setOrientation(Orientation.R90)
                myGroup.add(text)
                myGroup.add(rectPin)

        myGroup.add(topRect)

        return myGroup
    # end def drawMetal

    ####################################
    # Subroutine: calculateOutsideNotchSpace
    # Description: 
    ####################################
    def calculateOutsideNotchSpace(self,count,height,notchInsideHeight,notchSpace,side):
        #processGrid = Grid(self.getGCP("PROCESS_GRID"))
        processGrid = self.processGrid
        topAndBottomSpace=height-((notchInsideHeight*count)+(notchSpace*(count-1)))
        space=fdkUtils.fdkSnapGrid(processGrid,(topAndBottomSpace/2))
        #space = fdkUtils.fdkSnapGrid(processGrid,space)
        #if you are calculating from the top we want a non-divideable height
        #to go to the next higher grid, but if we want the larger space
        #to appear at the bottom we want the space at the top to be one 
        #grid smaller...so that is floor! Floor is how pcell does it
        
        if fdkUtils.fdkCmp((space*2),"!=",topAndBottomSpace):
            if side == "bottom":
                space=space-processGrid

        return space 
    # end def calculateOutsideNotchSpace


    ####################################
    # Subroutine: drawNotches
    # Description: 
    ####################################
    def drawNotches (self,Layer,count,height,width,wOffset,notchInsideHeight,notchSpace,side):
        myGroup = Grouping( components = [] )
        pointList=[]
        notchRight=width
        #hOffset=(height-((notchInsideHeight*count)+(notchSpace*(count-1))))/2
        hOffset=self.calculateOutsideNotchSpace(count,height,notchInsideHeight,notchSpace,"bottom")
        currentHeight=height-hOffset
        pointList=[Point(0.0,0.0),Point(0,height),Point(notchRight,height)]
        if count > 0 :
            pointList.append(Point(width,currentHeight))

            notchLeft=width-wOffset
            # Build C shaped notch
            for rowIndex in range(0,count):
                pointList.append(Point(notchLeft,currentHeight))
                currentHeight=currentHeight-notchInsideHeight
                pointList.append(Point(notchLeft,currentHeight))
                pointList.append(Point(notchRight,currentHeight))
                currentHeight=currentHeight-notchSpace
                if rowIndex != (count-1):
                    pointList.append(Point(notchRight,currentHeight))
                
        pointList.append(Point(notchRight,0.0))

        #print   pointList
        myGroup.add(Polygon(Layer,pointList))

        if side == "right":
            myGroup.mirrorY()

        return myGroup
    # end def drawNotches



    ####################################
    # Subroutine: genLayout
    # Description: builds layout
    ####################################
    def genLayout (self):
        self.processGrid = 0.001
        if self.stacked == "double":
            #run genLayout for mimcap_scl_stk
            self.genLayoutStk()
        else:
            #run genLayout for mimcap_scl
            self.genLayoutScl()
    # end def genLayout

    ####################################
    # Subroutine: genLayoutScl
    # Description: builds the mimcap_scl layout (parameter-scaled with overlapping plates)
    ####################################
    def genLayoutScl (self):

        # Initialization #######################################################################
        #set up groups and basic values
        processGrid = self.processGrid
        #Grid(self.processGrid)
        myGroupList= []
        myGroup = Grouping( components = myGroupList )
        viaType =  self.viaType

        #get property bag values
        mimOverlap=self.myDr['designRules']['MIMOffset']
        viaRotate = self.myDr['designRules']['defaultViaRotate']
        notchSpace=self.myDr['designRules']['MIMMinWidth']
        viaHoleSpace=self.myDr['designRules']['MIMSpaceVia']

        #get Layers
        viaLayer        =fdkUtils.fdkLayer(self.myDr['designRules']['viaLayer'])
        topMetalLayer   =fdkUtils.fdkLayer(self.myDr['designRules']['upperMetal']['layer'])
        topPinLayer     =fdkUtils.fdkLayer(self.myDr['designRules']['upperMetal']['pinLayer'])
        bottomMetalLayer=fdkUtils.fdkLayer(self.myDr['designRules']['lowerMetal']['layer'])
        bottomPinLayer  =None
        topLayer        =fdkUtils.fdkLayer(self.myDr['designRules']['MIMTLayer'])
        bottomLayer     =fdkUtils.fdkLayer(self.myDr['designRules']['MIMBLayer'])
        viaBlockLayer   =fdkUtils.fdkLayer(self.myDr['designRules']['viaBlockageLayer'])
    
        #derived or hard-coded Layers (consider fixing this later)
        #don't use Layer command--Layer must be in tech otherwise visualization difficult
        blockagePurpose ="keepGenAway"
        #topBlockLayer   =Layer(topLayer.getLayerName(),blockagePurpose)
        #bottomBlockLayer=Layer(topLayer.getLayerName(),blockagePurpose)
        topBlockLayer   =fdkUtils.fdkLayer(topLayer.getLayerName()+":"+blockagePurpose)
        bottomBlockLayer=fdkUtils.fdkLayer(bottomLayer.getLayerName()+":"+blockagePurpose)
        mimcapIdName    ="scl_mim"
        #leftIdLayer     =Layer(mimcapIdName,"id3")
        #rightIdLayer    =Layer(mimcapIdName,"id2")
        #centerIdLayer   =Layer(mimcapIdName,"id1")
        leftIdLayer     =fdkUtils.fdkLayer(mimcapIdName+":"+"id3")
        rightIdLayer    =fdkUtils.fdkLayer(mimcapIdName+":"+"id2")
        centerIdLayer   =fdkUtils.fdkLayer(mimcapIdName+":"+"id1")

        #create nets using property bag names 
        net1=self.myDr['designRules']['term_name_B']
        net2=self.myDr['designRules']['term_name_A']
        Net(net1, SignalType.SIGNAL)
        term1 = Term(net1, termType=TermType.INPUT_OUTPUT)
        Net(net2, SignalType.SIGNAL)
        term2 = Term(net2, termType=TermType.INPUT_OUTPUT)

        #get via information and reverse if needed
        viaWidth = self.myDr['designRules']['viaType'][viaType]['width']
        viaLength = self.myDr['designRules']['viaType'][viaType]['length']
        if viaRotate == True:
            viaLength = self.myDr['designRules']['viaType'][viaType]['width']
            viaWidth = self.myDr['designRules']['viaType'][viaType]['length']

        #calculate notch and tab dimensions
        notchInsideHeight=viaWidth+(viaHoleSpace*2)
        notchInsideWidth=(viaLength/2.0)+viaHoleSpace
        #notchCount=int((self.w+notchSpace-(self.myDr['designRules']['MIMMinWidth']*2))/(notchInsideHeight+notchSpace))
        notchCount=int((self.w+notchSpace-(notchSpace*2))/(notchInsideHeight+notchSpace))
        outsideNotchSpace=self.calculateOutsideNotchSpace(notchCount,self.w,notchInsideHeight,notchSpace,"bottom")
        tabWidth=notchInsideWidth+(self.viaOffsetL-notchInsideWidth)
        sideIdWidth = tabWidth-notchInsideWidth

        #calculate or set bottom plate and top late overall dimensions
        bottomPlateLength = self.ldrawn
        bottomPlateWidth = self.w
        topPlateLength = self.ldrawn+(mimOverlap*2)
        topPlateWidth = self.w+(mimOverlap*2)

        # Create MBE (smaller bottom plate) Layer ###########################################

        #create the notched geometry on the left (the bottomLayer skinny C : [ )
        mbeTab=self.drawNotches(
                bottomLayer,
                notchCount,
                bottomPlateWidth,
                tabWidth,
                notchInsideWidth,
                notchInsideHeight,
                notchSpace,
                "left"
        )
        myGroup.add(mbeTab)

        # Make the MBE (bottom plate) the origin setting geometry
        mbeTab.setName('origin')

        #create the notched geometry on the right (the bottomLayer backwards fat C : ]|| )
        mbeCenter=self.drawNotches(
                bottomLayer,
                notchCount,
                bottomPlateWidth,
                bottomPlateLength-tabWidth,
                notchInsideWidth,
                notchInsideHeight,
                notchSpace,
                "right"
        )
        myGroup.add(mbeCenter)

        #align the bottom of the backwards-C with the bottom of the C
        mbeCenter.alignEdge(SOUTH,mbeTab,refDir=SOUTH)
        #align the left side of the backwards-C with the right side of the C: []  
        mbeCenter.alignEdge(WEST,mbeTab,refDir=EAST)

        # Create MTE (top plate) Layer (larger plate)#############################################
        #create the notched geometry on the left (the topLayer fat C: ||[ )
        tabWidth=notchInsideWidth+(self.viaOffsetR-notchInsideWidth)+mimOverlap
        sideId2Width = tabWidth-notchInsideWidth-mimOverlap

        #create notched geometry on the right (the skinny backwards C : ] )
        mteCenter=self.drawNotches(
                topLayer,
                notchCount,
                topPlateWidth,
                topPlateLength - tabWidth,
                notchInsideWidth,
                notchInsideHeight,
                notchSpace,
                "left"
        )
        myGroup.add(mteCenter)
        mteTab=self.drawNotches(
                topLayer,
                notchCount,
                topPlateWidth,
                tabWidth,
                notchInsideWidth,
                notchInsideHeight,
                notchSpace,
                "right"
        )
        myGroup.add(mteTab)

        #offset the top plate center from the bottom plate tab
        mteCenter.alignEdge(SOUTH,mbeTab,refDir=SOUTH,offset=-mimOverlap)
        mteCenter.alignEdge(WEST,mbeTab,refDir=WEST,offset=-mimOverlap)
        #align the bottom of the backwards C with the bottom of the C
        mteTab.alignEdge(SOUTH,mteCenter,refDir=SOUTH)
        #align the left side of the backwards C with the right side of the C: []  
        mteTab.alignEdge(WEST,mteCenter,refDir=EAST)

        #pin1=Pin(net1,net1,mteCenter)

        # Create Vias ##########################################################################
        if viaType != "none":
            # Create vias for Left via tab
            viaLeft=self.drawVia(viaLayer,
                        viaWidth,
                        viaLength,
                        (notchSpace+notchInsideHeight)-viaWidth,
                        notchCount,1)
            myGroup.add(viaLeft)
            viaSideOffset = fdkUtils.fdkSnapGrid(processGrid,(self.viaOffsetL-(viaLength/2.0)))
            viaLeft.alignEdge(WEST,mbeTab,refDir=WEST,offset=viaSideOffset)
            viaBottomOffset = outsideNotchSpace+viaHoleSpace
            viaBottomOffset = fdkUtils.fdkSnapGrid(processGrid,viaBottomOffset)
            viaLeft.alignEdge(NORTH,mbeTab,refDir=NORTH,offset=-viaBottomOffset)

            #Create metals over Left via tab
            viaMetalLeft=self.drawMetal(viaLeft,
                        None,
                        None,
                        bottomMetalLayer,
                        self.myDr['designRules']['lowerMetal']['overlap'],
                        self.myDr['designRules']['lowerMetal']['minWidth'],
                        net1+"_top",
                        net1,
                        topMetalLayer,
                        self.myDr['designRules']['upperMetal']['overlap'],
                        self.myDr['designRules']['upperMetal']['minWidth'],
                        bottomPinLayer,
                        topPinLayer
                        )
            myGroup.add(viaMetalLeft)
            
            # Create vias for Right via tab
            viaRight=self.drawVia(viaLayer,
                        viaWidth,
                        viaLength,
                        (notchSpace+notchInsideHeight)-viaWidth,
                        notchCount,1)
            myGroup.add(viaRight)
            viaSideOffset = fdkUtils.fdkSnapGrid(processGrid,-(self.viaOffsetR-(viaLength/2.0)+mimOverlap))
            viaRight.alignEdge(EAST,mteTab,refDir=EAST,offset=viaSideOffset)
            viaBottomOffset = outsideNotchSpace+viaHoleSpace+mimOverlap
            #print("right viaBottomOffset before snapping:",viaBottomOffset)
            viaBottomOffset = fdkUtils.fdkSnapGrid(processGrid,viaBottomOffset)
            #print("right viaBottomOffset after snapping:",viaBottomOffset)
            viaRight.alignEdge(NORTH,mteTab,refDir=NORTH,offset=-viaBottomOffset)

            viaMetalRight=self.drawMetal(viaRight,
                        None,
                        None,
                        bottomMetalLayer,
                        self.myDr['designRules']['lowerMetal']['overlap'],
                        self.myDr['designRules']['lowerMetal']['minWidth'],
                        net2+"_top",
                        net2,
                        topMetalLayer,
                        self.myDr['designRules']['upperMetal']['overlap'],
                        self.myDr['designRules']['upperMetal']['minWidth'],
                        bottomPinLayer,
                        topPinLayer
                        )
            myGroup.add(viaMetalRight)

        # Add Mimcap ID Layers #############################################################################
        sideIdBbox= Box(0.0,0.0,sideIdWidth,self.w)
        sideId2Bbox= Box(0.0,0.0,sideId2Width,self.w)
        idLayer=Rect(leftIdLayer,sideIdBbox)
        idLayer.alignEdge(SOUTH,mbeTab,refDir=SOUTH)
        idLayer.alignEdge(WEST,mbeTab,refDir=WEST)
        myGroup.add(idLayer)

        idLayer=Rect(rightIdLayer,sideId2Bbox);
        idLayer.alignEdge(SOUTH,mbeCenter,refDir=SOUTH)
        idLayer.alignEdge(EAST,mbeCenter,refDir=EAST)
        myGroup.add(idLayer)

        #this combines mbeCenter and mbeTab for bbox, align to mbeTab which is on left of center
        groupBbox= myGroup.getBBox(filter=ShapeFilter(bottomLayer))
        idLayer=Rect(centerIdLayer,groupBbox)
        idLayer.alignEdge(SOUTH,mbeTab,refDir=SOUTH)
        idLayer.alignEdge(WEST,mbeTab,refDir=WEST)
        myGroup.add(idLayer)

        # Create Routing Blockages

        # TM PIN Layer routing blockage
        for pin_fig in myGroup.fgMerge(topPinLayer, ShapeFilter([topPinLayer])):
          try:
            LayerBlockage(BlockageType.ROUTING, topPinLayer, pin_fig.getPoints())
          except:
            LayerBlockage(BlockageType.ROUTING, topPinLayer, pin_fig.getBBox().getPoints())

        # Create PRBoundary shape if necessary
        if PRBoundary.find() is None:
          bb = None
          for cr in self.getComps():
            try:
              cr.getFont()
            except:
              if bb is None:
                bb = cr.getBBox()
              else:
                bb = bb.merge(cr.getBBox())
          pts = PointList([bb.lowerLeft(), bb.upperLeft(), bb.upperRight(), bb.lowerRight()])
          prb = PRBoundary(pts, ['left', 'top', 'right', 'bottom'])

        # VIA ROUTING BLOCKAGE AROUND PRBOUNDARY
        if PRBoundary.find() is not None:
          LayerBlockage(BlockageType.ROUTING, viaLayer, PRBoundary.find().getPoints())
        else:
          LayerBlockage(BlockageType.ROUTING, viaLayer, self.getBBox().getPoints())

        # BM Layer routing blockage
        for pin_fig in myGroup.fgSize(ShapeFilter([bottomMetalLayer]), -1.0e-03, bottomMetalLayer):
          try:
            LayerBlockage(BlockageType.ROUTING, bottomMetalLayer, pin_fig.getPoints())
          except:
            LayerBlockage(BlockageType.ROUTING, bottomMetalLayer, pin_fig.getBBox().getPoints())

        # Create Fill Blockage Layers
        groupBbox= myGroup.getBBox(filter=ShapeFilter([topLayer,bottomLayer,viaLayer]))
        pointsList=groupBbox.getPoints()
        viaBlockage=LayerBlockage(BlockageType.FILL,viaBlockLayer,pointsList)
        topBlockage=LayerBlockage(BlockageType.FILL,topBlockLayer,pointsList)
        bottomBlockage=LayerBlockage(BlockageType.FILL,bottomBlockLayer,pointsList)
        #blockage=Rect(viaBlockLayer,groupBbox)
        #blockage=Rect(topBlockLayer,groupBbox)
        #blockage=Rect(bottomBlockLayer,groupBbox)
        myGroup.add(viaBlockage)
        myGroup.add(topBlockage)
        myGroup.add(bottomBlockage)

        # Set Origin using Origin Object
        self.setMyOrigin(Direction.WEST,0.0,Direction.SOUTH,0.0)
    # end def genLayoutScl

    ####################################
    # Subroutine: genLayoutStk
    # Description: builds the mimcap_scl_stk layout 
    # (parameter scaled with gapped plates and floating stacked plate on both)
    ####################################
    def genLayoutStk (self):
        # Initialization #######################################################################
        #set up groups and basic values
        processGrid = self.processGrid
        #Grid(self.processGrid)
        myGroupList= []
        myGroup = Grouping( components = myGroupList )
        viaType =  self.viaType

        #get property bag values
        mimOverlap=self.myDr['designRules']['MIMOffset']
        viaRotate = self.myDr['designRules']['defaultViaRotate']
        notchSpace=self.myDr['designRules']['MIMMinWidth']
        viaHoleSpace=self.myDr['designRules']['MIMSpaceVia']

        #get Layers
        viaLayer        =fdkUtils.fdkLayer(self.myDr['designRules']['viaLayer'])
        topMetalLayer   =fdkUtils.fdkLayer(self.myDr['designRules']['upperMetal']['layer'])
        topPinLayer     =fdkUtils.fdkLayer(self.myDr['designRules']['upperMetal']['pinLayer'])
        bottomMetalLayer=fdkUtils.fdkLayer(self.myDr['designRules']['lowerMetal']['layer'])
        bottomPinLayer  =None
        topLayer        =fdkUtils.fdkLayer(self.myDr['designRules']['MIMTLayer'])
        bottomLayer     =fdkUtils.fdkLayer(self.myDr['designRules']['MIMBLayer'])
        viaBlockLayer   =fdkUtils.fdkLayer(self.myDr['designRules']['viaBlockageLayer'])
    
        #derived or hard-coded Layers (consider fixing this later)
        #don't use Layer command--Layer must be in tech otherwise visualization difficult
        blockagePurpose ="keepGenAway"
        topBlockLayer   =fdkUtils.fdkLayer(topLayer.getLayerName()+":"+blockagePurpose)
        bottomBlockLayer=fdkUtils.fdkLayer(bottomLayer.getLayerName()+":"+blockagePurpose)
        mimcapIdName    ="scl_mim"
        leftIdLayer     =fdkUtils.fdkLayer(mimcapIdName+":"+"id3")
        rightIdLayer    =fdkUtils.fdkLayer(mimcapIdName+":"+"id2")
        centerIdLayer   =fdkUtils.fdkLayer(mimcapIdName+":"+"id1")

        #create nets using property bag names 
        net1=self.myDr['designRules']['term_name_B']
        net2=self.myDr['designRules']['term_name_A']
        Net(net1, SignalType.SIGNAL)
        term1 = Term(net1, termType=TermType.INPUT_OUTPUT)
        Net(net2, SignalType.SIGNAL)
        term2 = Term(net2, termType=TermType.INPUT_OUTPUT)

        #get via information and reverse if needed
        viaWidth = self.myDr['designRules']['viaType'][viaType]['width']
        viaLength = self.myDr['designRules']['viaType'][viaType]['length']
        if viaRotate == True:
            viaLength = self.myDr['designRules']['viaType'][viaType]['width']
            viaWidth = self.myDr['designRules']['viaType'][viaType]['length']

        #calculate notch and tab dimensions
        notchInsideHeight=viaWidth+(viaHoleSpace*2)
        notchInsideWidth=(viaLength/2.0)+viaHoleSpace
        notchCount=int((self.w+notchSpace-(notchSpace*2))/(notchInsideHeight+notchSpace))
        outsideNotchSpace=self.calculateOutsideNotchSpace(notchCount,self.w,notchInsideHeight,notchSpace,"bottom")
        tabWidth=self.viaOffsetL+mimOverlap
        sideIdWidth = tabWidth-notchInsideWidth-mimOverlap

        #calculate or set bottom plate and top late overall dimensions
        bottomPlateLength = self.ldrawn
        bottomPlateWidth = self.w
        topPlateLength = self.ldrawn+(mimOverlap*2)
        topPlateWidth = self.w+(mimOverlap*2)

        #special calculations for STK 
        bottomPlateGap = self.myDr['designRules']['MIMBspace']
        bottomPlateIdWidth = bottomPlateGap
        bottomPlateHalfLength = fdkUtils.fdkSnapGrid(self.processGrid,((bottomPlateLength-bottomPlateGap)/2.0))
        bottomPlateHalfLengthRight = bottomPlateHalfLength
        bottomPlateHalfLengthLeft = bottomPlateLength-bottomPlateHalfLength-bottomPlateGap
    
        topPlateHalfLength = fdkUtils.fdkSnapGrid(self.processGrid,(topPlateLength/2.0))
        topPlateHalfLengthLeft = topPlateHalfLength
        if fdkUtils.fdkCmp((topPlateHalfLength*2),">",topPlateLength):
            topPlateHalfLengthRight = topPlateHalfLength - self.processGrid
        else:
            if fdkUtils.fdkCmp((topPlateHalfLength*2),"<",topPlateLength):
                topPlateHalfLengthRight = topPlateHalfLength + self.processGrid
            else:
                topPlateHalfLengthRight = topPlateHalfLength

        #create MBE plates (two rectangles)
        mbeBboxLeft= Box(0.0,0.0,bottomPlateHalfLengthLeft,bottomPlateWidth)
        mbeBboxRight= Box(0.0,0.0,bottomPlateHalfLengthRight,bottomPlateWidth)
        mbeLeft=Rect(bottomLayer,mbeBboxLeft)
        mbeRight=Rect(bottomLayer,mbeBboxRight)
        myGroup.add(mbeLeft)
        myGroup.add(mbeRight)

        # Make the MBE (bottom plate) the origin setting geometry
        mbeLeft.setName('origin')

        # Create MTE (top plate) Layer (larger plates)#############################################
        #create the notched geometry on the left (the top Layer skinny C : [ )
        mteLeftTab=self.drawNotches(
                topLayer,
                notchCount,
                topPlateWidth,
                tabWidth,
                notchInsideWidth,
                notchInsideHeight,
                notchSpace,
                "left"
        )
        myGroup.add(mteLeftTab)

        #create the notched geometry on the right (the bottomLayer backwards fat C : ||[ )
        mteLeftCenter=self.drawNotches(
                topLayer,
                notchCount,
                topPlateWidth,
                topPlateHalfLengthLeft-tabWidth,
                notchInsideWidth,
                notchInsideHeight,
                notchSpace,
                "right"
        )
        myGroup.add(mteLeftCenter)

        #align the bottom of the backwards-C with the bottom of the C
        mteLeftCenter.alignEdge(SOUTH,mteLeftTab,refDir=SOUTH)
        #align the left side of the backwards-C with the right side of the C: []  
        mteLeftCenter.alignEdge(WEST,mteLeftTab,refDir=EAST)

        #create the notched geometry on the center right (the topLayer fat C : ||[ )
        tabWidth=self.viaOffsetR+mimOverlap
        sideId2Width = tabWidth-notchInsideWidth-mimOverlap
        mteRightCenter=self.drawNotches(
                topLayer,
                notchCount,
                topPlateWidth,
                topPlateHalfLengthRight - tabWidth,
                notchInsideWidth,
                notchInsideHeight,
                notchSpace,
                "left"
        )
        myGroup.add(mteRightCenter)
        mteRightTab=self.drawNotches(
                topLayer,
                notchCount,
                topPlateWidth,
                tabWidth,
                notchInsideWidth,
                notchInsideHeight,
                notchSpace,
                "right"
        )
        myGroup.add(mteRightTab)

        #align the left side of the mteRightCenter with the right side of the mteLeftCenter
        mteRightCenter.alignEdge(SOUTH,mteLeftCenter,refDir=SOUTH)
        mteRightCenter.alignEdge(WEST,mteLeftCenter,refDir=EAST)

        #align the bottom of the backwards C with the bottom of the C
        mteRightTab.alignEdge(SOUTH,mteRightCenter,refDir=SOUTH)
        #align the left side of the backwards C with the right side of the C: []  
        mteRightTab.alignEdge(WEST,mteRightCenter,refDir=EAST)

        #now all the top Layer geometries are aligned with each other

        #offset the top plate center from the bottom plate tab
        mbeLeft.alignEdge(SOUTH,mteLeftTab,refDir=SOUTH,offset=mimOverlap)
        mbeLeft.alignEdge(WEST,mteLeftTab,refDir=WEST,offset=mimOverlap)
        #offset the bottom right plate from the top plate tab (to avoid offset by gap)
        mbeRight.alignEdge(SOUTH,mteRightTab,refDir=SOUTH,offset=mimOverlap)
        mbeRight.alignEdge(EAST,mteRightTab,refDir=EAST,offset=-mimOverlap)

        #pin1=Pin(net1,net1,mteCenter)

        # Create Vias
        if viaType != "none":
            # Create vias for Left via tab
            viaLeft=self.drawVia(viaLayer,
                        viaWidth,
                        viaLength,
                        (notchSpace+notchInsideHeight)-viaWidth,
                        notchCount,1)
            myGroup.add(viaLeft)
            viaSideOffset = fdkUtils.fdkSnapGrid(processGrid,(viaLength/2.0))
            viaLeft.alignEdge(WEST,mteLeftTab,refDir=EAST,offset=-viaSideOffset)
            viaBottomOffset = outsideNotchSpace+viaHoleSpace+mimOverlap
            viaBottomOffset = fdkUtils.fdkSnapGrid(processGrid,viaBottomOffset)
            viaLeft.alignEdge(NORTH,mteLeftTab,refDir=NORTH,offset=-viaBottomOffset)

            #Create metals over Left via tab
            viaMetalLeft=self.drawMetal(viaLeft,
                        None,
                        None,
                        bottomMetalLayer,
                        self.myDr['designRules']['lowerMetal']['overlap'],
                        self.myDr['designRules']['lowerMetal']['minWidth'],
                        net1+"_top",
                        net1,
                        topMetalLayer,
                        self.myDr['designRules']['upperMetal']['overlap'],
                        self.myDr['designRules']['upperMetal']['minWidth'],
                        bottomPinLayer,
                        topPinLayer
                        )
            myGroup.add(viaMetalLeft)
            
            # Create vias for Right via tab
            viaRight=self.drawVia(viaLayer,
                        viaWidth,
                        viaLength,
                        (notchSpace+notchInsideHeight)-viaWidth,
                        notchCount,1)
            myGroup.add(viaRight)
            viaSideOffset = fdkUtils.fdkSnapGrid(processGrid,(viaLength/2.0))
            viaRight.alignEdge(EAST,mteRightTab,refDir=WEST,offset=viaSideOffset)
            viaBottomOffset = outsideNotchSpace+viaHoleSpace+mimOverlap
            viaBottomOffset = fdkUtils.fdkSnapGrid(processGrid,viaBottomOffset)
            viaRight.alignEdge(NORTH,mteRightTab,refDir=NORTH,offset=-viaBottomOffset)

            viaMetalRight=self.drawMetal(viaRight,
                        None,
                        None,
                        bottomMetalLayer,
                        self.myDr['designRules']['lowerMetal']['overlap'],
                        self.myDr['designRules']['lowerMetal']['minWidth'],
                        net2+"_top",
                        net2,
                        topMetalLayer,
                        self.myDr['designRules']['upperMetal']['overlap'],
                        self.myDr['designRules']['upperMetal']['minWidth'],
                        bottomPinLayer,
                        topPinLayer
                        )
            myGroup.add(viaMetalRight)

        # Add Mimcap ID Layers
        sideIdBbox= Box(0.0,0.0,sideIdWidth,self.w)
        sideId2Bbox= Box(0.0,0.0,sideId2Width,self.w)
        idLayer=Rect(leftIdLayer,sideIdBbox)
        idLayer.alignEdge(SOUTH,mbeLeft,refDir=SOUTH)
        idLayer.alignEdge(WEST,mbeLeft,refDir=WEST)
        myGroup.add(idLayer)

        idLayer=Rect(rightIdLayer,sideId2Bbox);
        idLayer.alignEdge(SOUTH,mbeRight,refDir=SOUTH)
        idLayer.alignEdge(EAST,mbeRight,refDir=EAST)
        myGroup.add(idLayer)

        # Also need to add the gap id boxes for both leftIdLayer and rightIdLayer
        gapIdBbox=Box(0.0,0.0,bottomPlateIdWidth,self.w)
        gapIdLeft=Rect(leftIdLayer,gapIdBbox)
        gapIdLeft.alignEdge(SOUTH,mbeLeft,refDir=SOUTH)
        gapIdLeft.alignEdge(WEST,mbeLeft,refDir=EAST)
        myGroup.add(gapIdLeft)
        gapIdRight=Rect(rightIdLayer,gapIdBbox)
        gapIdRight.alignEdge(SOUTH,mbeRight,refDir=SOUTH)
        gapIdRight.alignEdge(EAST,mbeRight,refDir=WEST)
        myGroup.add(gapIdRight)
        #this combines mbeLeft and mbeRight, align to mbeLeft
        groupBbox= myGroup.getBBox(filter=ShapeFilter(bottomLayer))
        idLayer=Rect(centerIdLayer,groupBbox)
        idLayer.alignEdge(SOUTH,mbeLeft,refDir=SOUTH)
        idLayer.alignEdge(WEST,mbeLeft,refDir=WEST)
        myGroup.add(idLayer)

        # Create Routing Blockages

        # TM PIN Layer routing blockage
        for pin_fig in myGroup.fgMerge(topPinLayer, ShapeFilter([topPinLayer])):
          try:
            LayerBlockage(BlockageType.ROUTING, topPinLayer, pin_fig.getPoints())
          except:
            LayerBlockage(BlockageType.ROUTING, topPinLayer, pin_fig.getBBox().getPoints())

        # Create PRBoundary shape if necessary
        if PRBoundary.find() is None:
          bb = None
          for cr in self.getComps():
            try:
              cr.getFont()
            except:
              if bb is None:
                bb = cr.getBBox()
              else:
                bb = bb.merge(cr.getBBox())
          pts = PointList([bb.lowerLeft(), bb.upperLeft(), bb.upperRight(), bb.lowerRight()])
          prb = PRBoundary(pts, ['left', 'top', 'right', 'bottom'])

        # VIA ROUTING BLOCKAGE AROUND PRBOUNDARY
        if PRBoundary.find() is not None:
          LayerBlockage(BlockageType.ROUTING, viaLayer, PRBoundary.find().getPoints())
        else:
          LayerBlockage(BlockageType.ROUTING, viaLayer, self.getBBox().getPoints())

        # BM Layer routing blockage
        for pin_fig in myGroup.fgSize(ShapeFilter([bottomMetalLayer]), -1.0e-03, bottomMetalLayer):
          try:
            LayerBlockage(BlockageType.ROUTING, bottomMetalLayer, pin_fig.getPoints())
          except:
            LayerBlockage(BlockageType.ROUTING, bottomMetalLayer, pin_fig.getBBox().getPoints())

        # Create Fill Blockage Layers
        groupBbox= myGroup.getBBox(filter=ShapeFilter([topLayer,bottomLayer,viaLayer]))
        pointsList=groupBbox.getPoints()
        viaBlockage=LayerBlockage(BlockageType.FILL,viaBlockLayer,pointsList)
        topBlockage=LayerBlockage(BlockageType.FILL,topBlockLayer,pointsList)
        bottomBlockage=LayerBlockage(BlockageType.FILL,bottomBlockLayer,pointsList)
        myGroup.add(viaBlockage)
        myGroup.add(topBlockage)
        myGroup.add(bottomBlockage)

        # Set Origin using Origin Object
        self.setMyOrigin(Direction.WEST,0.0,Direction.SOUTH,0.0)

    # end def genLayoutStk
