
require 'liveParametric'
require 'EL/ELSheet.rb'

class AspendedNGoda < LiveParametric

    @@numPetalStr 			= "Number of Petals "
    @@summitHeightStr 		= "Summit Height "
    @@innerPoleHeightStr 	= "Inner Pole Height"
    @@outerPoleHeightStr 	= "Outer Pole Height"
    @@outerPole2HeightStr 	= "Outer Pole 2 Height"
    @@innerPoleRadStr 		= "Inner Pole Rad"
    @@outerPoleRadStr 		= "Outer Pole Rad"
    @@outerPole2RadStr 		= "Outer Pole 2 Rad"
    @@scallopLocRatioStr 	= "Scallop Loc Ratio"
    @@scallopWidthRatioStr	= "Scallop 1 Width Ratio"
    @@scallop2WidthRatioStr = "Scallop 2 Width Ratio"
    @@scallop3WidthRatioStr = "Scallop 3 Width Ratio"
    @@centerPointStr 		= "Center Point"

    @@units = :m
 

    def default_variables
        [
        	Slider.new( @@numPetalStr            , 3,     17,      5, true),
	        # Slider.new( @@summitHeightStr        , 3,10,  8.5, false),
	        Slider.new( @@innerPoleHeightStr     , 2, 17,  4.5, false),
	        Slider.new( @@outerPoleHeightStr     , 2, 17,  4.5, false),
	        Slider.new( @@outerPole2HeightStr    , 2, 17,    6, false),
	        Slider.new( @@innerPoleRadStr        , 2, 25,   4, false),
	        Slider.new( @@outerPoleRadStr        , 2, 25,   9, false),
	        Slider.new( @@outerPole2RadStr		 , 2, 25,  12, false),
	        # Slider.new( @@scallopLocRatioStr     ),
	        # Slider.new( @@scallopWidthRatioStr   ),
	        Slider.new( @@scallop2WidthRatioStr  ),
	        Slider.new( @@scallop3WidthRatioStr  )
		]
    end

   #-----------------------------------------------------------------------------
    # create_entities is called to create the entities for the parametric object.
    # the parameters needed to create the object are passed in as a Hash.
    # This must be implemented by any class that includes Parametric
    def create_entities(data, container)
        @numSides			=data[@@numPetalStr         ]

        # @summitHeight		=data[@@summitHeightStr     ].method(@@units).call
        @summitHeight 		= 8.method(@@units).call
        @innerPoleHeight	=data[@@innerPoleHeightStr  ].method(@@units).call
        @outerPoleHeight	=data[@@outerPoleHeightStr  ].method(@@units).call
        @outerPole2Height   =data[@@outerPole2HeightStr].method(@@units).call

        @innerPoleRad		=data[@@innerPoleRadStr     ].method(@@units).call
        @outerPoleRad		=data[@@outerPoleRadStr     ].method(@@units).call
        @outerPole2Rad 		=data[@@outerPole2RadStr].method(@@units).call


        # @scallopWidthRatio=data[@@scallopWidthRatioStr]
        @scallopWidthRatio = 0.8
        # @scallopLocRatio	=data[@@scallopLocRatioStr  ]
        @scallopLocRatio = 0.5
        @scallop2WidthRatio =data[@@scallop2WidthRatioStr]
        @scallop3WidthRatio =data[@@scallop3WidthRatioStr]

        @computeSkins = false
        @centerPoint = Geom::Point3d.new( 0,0,0)

        @poleThickness = 0.1.method(@@units).call # make this non-zero to draw poles as cylinders rather than lines

        @poles = []
        @sheets = []
        @wires = []

        # set up poles all around
        makePoles
        # makeWires

        # create the first sheet
        @sheets << sheet

        # Make everything visible, with separate groups for poles, wires, & sheets
        [@poles, @wires].each {|e|
            ge = container.add_group.entities
            e.each {|f| f.addToEntities(ge) }
        }
        @sheets.each {|f|
            g = container.add_group
            f.addToEntities(g.entities)
            f.copyAroundPoint(@centerPoint, @numSides, g)
        }

        #store centerPoint in our attr_dict
        attribute_dictionary(true)[@@centerPointStr] = @centerPoint

        # Add Labels and print cutList
        # puts cutList
        # all_objects.each { |e| e.addLabelToEntities(container) }

        # Show where the bases of all the poles are
        # poleBase(container)

        nil
    end

    def all_objects
        @poles + @wires + @sheets
    end

    def to_s
        nil
    end

    def cutList
        # List of all wires & poles, calling shortName for each?
        all_objects.map{ |e| e.cutStr}.join("\n")
        # Some textual representation of sheets for the future?
    end

    def poleBase(ent)
        # find all points on the ground
        points 		= all_objects.map{|e| e.vertices.map{|f| f.loc if f.loc.z == 0}}.flatten.compact.uniq
        whichPoles  = all_objects.map{|e| e.vertices.map{|f| f.spars.first if f.loc.z == 0}}.flatten.compact.uniq

        # find the bounding box
        bb = Geom::BoundingBox.new
        bb.add( *points)

        margin = bb.width/10
        dotRad = bb.width/100

        min = bb.min

        t = Geom::Transformation.translation( [-min.x+margin, -min.y+margin, 0])

        # shift all the points by the minimum so everything's based at 0,0
        points.map!{ |e| e.transform(t) }

        #add a face between the points
        bb.clear
        bb.add(*points)
        min = [0,0,0]
        max = bb.max
        max = [max.x+2*margin, max.y+2*margin, 0]

        facePoints = [
            Geom::Point3d.new(min.x, min.y, 0),
            Geom::Point3d.new(min.x, max.y, 0),
            Geom::Point3d.new(max.x, max.y, 0),
            Geom::Point3d.new(max.x, min.y, 0)
        ]
        ent.add_face(facePoints)

        puts "Pole locations:"
        # points.each { |e|
        #             ent.add_circle( e, [0,0,1], dotRad)
        #             label = "(#{e.x}, #{e.y})"
        #             ent.add_text( label, e)
        #             puts label
        #         }

        points.each_index { |i|
            e = points[i]
            poleStr = whichPoles[i].shortName
            ent.add_circle( e, [0,0,1], dotRad)
            label = "#{poleStr}: (#{e.x}, #{e.y})"
            ent.add_text( label, e)
            puts label
        }
    end

    def makePoles
        @poles = []
        # central pole
        @poles[0] = ELSpar.new( Geom::Point3d.new(@centerPoint.x,@centerPoint.y,@centerPoint.z+@summitHeight-@innerPoleHeight), Geom::Point3d.new(@centerPoint.x,@centerPoint.y,@centerPoint.z+@summitHeight), @poles.length, "Center Pole", @poleThickness)

        stepAngle = 360.degrees/@numSides
        angleOffset = stepAngle/2  # ETJ - 24-Apr-2007 --  Cool spiral effects by changing this fraction --   

        addRadialPoles( @poles, @centerPoint, @numSides, angleOffset, @innerPoleRad, @innerPoleHeight, "Inner Pole")
        addRadialPoles( @poles, @centerPoint, @numSides, 		  0, @outerPoleRad, @outerPoleHeight, "Outer Pole")
        addRadialPoles( @poles, @centerPoint, @numSides, angleOffset, @outerPole2Rad, @outerPole2Height, "Outer Pole (Second Tier)")
    end

    def addRadialPoles( poleArr, centerPoint, numPoles, offsetAngle, poleRad, poleHeight, labelStr)
        numPoles.times{|i|
            angle = 360.degrees/numPoles*i + offsetAngle
            x = centerPoint.x + poleRad *Math.cos(angle)
            y = centerPoint.y + poleRad *Math.sin(angle)
            z = centerPoint.z
            poleArr << ELSpar.new( Geom::Point3d.new(x,y,z), Geom::Point3d.new(x,y,z+poleHeight), poleArr.length, labelStr, @poleThickness)
        }
    end

    # Can't be called until makePoles has created the poles
    def sheet
        # Sheet has 8 corners:
        # 1 central point top
        # 2 fabric-fabric points (the scallop)
        # 2 points on inner poles
        # 2 points between 2nd tier of outer poles
        # 1 outer pole top

        # 4 of these points haven't been created yet
        # To get them, find points @scallopLocRatio of the way between
        # the inner poles and the central pole.
        # On the chord between those two points, make a
        # chord that's @scallopWidthRatio of the length
        # of the original chord, centered (although it would
        # look cool if it wasn't-- all spirally)
        p1 = Geom.linear_combination( 1-@scallopLocRatio,@poles[1].top.loc , @scallopLocRatio, @poles[0].top.loc)
        p2 = Geom.linear_combination( 1-@scallopLocRatio,@poles[@numSides].top.loc , @scallopLocRatio, @poles[0].top.loc)
        cp1 = cp2 = cp3 = cp4 = cp5 = cp6 = nil

        spiralled = false
        if spiralled
            p1 = p1
            p2 = p2
            cp1 = p1
            cp2 = Geom.linear_combination(  1-@scallopWidthRatio, p1, @scallopWidthRatio, p2)

            p1 = @poles[1].top.loc
            p2 = @poles[@numSides].top.loc
            cp3 = p1
            cp4 = Geom.linear_combination( 1-@scallop2WidthRatio, p1, @scallop2WidthRatio,p2)

            # cp5 = @poles[2*@numSides+1].top.loc
            # 			cp6 = Geom.linear_combination( 1-@scallop3WidthRatio, cp5, @scallop3WidthRatio, @poles[2*@numSides+2].top.loc)
            #
            r = @scallop3WidthRatio + (1-@scallop3WidthRatio)/2
            p1 = @poles[2*@numSides+1].top.loc
            p2 = @poles[3*@numSides].top.loc
            cp5 = Geom.linear_combination(   r, p1, 1-r, p2)
            cp6 = Geom.linear_combination( 1-r, p1,   r, p2)
        else
            #centered scallop
            r = @scallopWidthRatio + (1-@scallopWidthRatio)/2
            cp1 = Geom.linear_combination(r, p1, 1-r, p2)
            cp2 = Geom.linear_combination(1-r, p1, r, p2)

            # ETJ - 15-Apr-2007 --  if the ratios are multiples, we end up with a bad normal vector --   
            @scallop2WidthRatio *= 0.9 if @scallop2WidthRatio == @scallopWidthRatio/2

            r = @scallop2WidthRatio + (1-@scallop2WidthRatio)/2
            p1 = @poles[1].top.loc
            p2 = @poles[@numSides].top.loc
            cp3 = Geom.linear_combination( r, p1, 1-r, p2)
            cp4 = Geom.linear_combination( 1-r, p1, r, p2)

            r = @scallop3WidthRatio + (1-@scallop3WidthRatio)/2
            p1 = @poles[2*@numSides+1].top.loc
            p2 = @poles[3*@numSides].top.loc
            cp5 = Geom.linear_combination( r,   p1, 1-r, p2)
            cp6 = Geom.linear_combination( 1-r, p1, r, p2)
        end

        sheetPoints = [@poles[0].top.loc, cp1, cp3, cp5, @poles[@numSides+1].top.loc, cp6, cp4, cp2]

        innerNorm  = (sheetPoints[ 0] - sheetPoints[-1])*(sheetPoints[0] - sheetPoints[1])
        mid1Norm   = (sheetPoints[-1] - sheetPoints[-2])*(sheetPoints[1] - sheetPoints[2])
        mid2Norm   = (sheetPoints[-2] - sheetPoints[-3])*(sheetPoints[2] - sheetPoints[3])
        outerNorm  = (sheetPoints[3] - sheetPoints[4])*(sheetPoints[-3] - sheetPoints[-4])

        highCurvature = 0.6
        mediumCurvature = 1.3
        lowCurvature = 3

        sheetEdges = [
            ELSheetEdge.new( sheetPoints[0], sheetPoints[1],  innerNorm, mediumCurvature, 0),
            ELSheetEdge.new( sheetPoints[1], sheetPoints[2],  mid1Norm,   mediumCurvature,1),
            ELSheetEdge.new( sheetPoints[2], sheetPoints[3],  mid2Norm, mediumCurvature,  2),
            ELSheetEdge.new( sheetPoints[3], sheetPoints[4],  outerNorm, lowCurvature,    3),
            ELSheetEdge.new( sheetPoints[4], sheetPoints[5],  outerNorm, lowCurvature,    4),
            ELSheetEdge.new( sheetPoints[5], sheetPoints[6],  mid2Norm, mediumCurvature,  6),
            ELSheetEdge.new( sheetPoints[6], sheetPoints[7],  mid1Norm, mediumCurvature,  7),
            ELSheetEdge.new( sheetPoints[7], sheetPoints[0],  innerNorm, mediumCurvature, 8)
        ]
        ELSheet.new(sheetEdges, 0, @computeSkins)
    end

    # Can't be called until makePoles has created the poles
    def makeWires
        # from inner poles to center pole
        @numSides.times{|i|
            @wires << ELWire.new(@poles[0].top, @poles[i+1].top, @wires.length)
            @wires << ELWire.new(@poles[0].bot, @poles[i+1].top, @wires.length)
        }

        1.upto(@numSides-1){|i|
            @wires << ELWire.new(@poles[i].top, @poles[i+@numSides].top, @wires.length)
            @wires << ELWire.new(@poles[i].top, @poles[1+i+@numSides].top, @wires.length)
        }
        @wires << ELWire.new(@poles[@numSides].top, @poles[1+@numSides].top, @wires.length)
        @wires << ELWire.new(@poles[@numSides].top, @poles[2*@numSides].top, @wires.length)

        # ETJ - 15-Apr-2007 --  This doesn't add wires between sheets or between poles and sheets. Needed --   
        # first scallops connect to the sheets next to them
        # second scallops connect to inner poles
    end

      # Copy all sheets made with soapSkinBubble around a radial point
    def AspendedNGoda.copySheet
        # ETJ - 23-Apr-2007 --  requires methods in SSB.rb --   
        #
        # Optimally, we could have multiple pagodas
        # in a model.  A complication is that SoapSkinBubble
        # adds a groups to the top-level entities in the model,
        # so there's no obvious way to know which sheet goes with which
        # ETJ - 24-Apr-2007 --  pagoda. What to do? --   

        groups = findClassesInTree(Sketchup::Group)
        parametricGroup = groups.find{|e| e.attribute_dictionary("skpp")}

        numPetals = parametricGroup.attribute_dictionary("skpp")[@@numPetalStr].to_i
        centerPoint = parametricGroup.attribute_dictionary("skpp")[@@centerPointStr]
        sheetGroups = groups.select{|e| e.attribute_dictionary("Tensile-Structures.de")}

        sheetGroups.each{ |e|
            (1...numPetals).each {|i|
                angle = 360.degrees/numPetals*i
                t = Geom::Transformation.rotation( centerPoint, [0,0,1], angle)
                nextGroup = e.copy
                nextGroup.transform!(t)
            }
        }

    end
end


# ============================================================================
#  Sketchup menu setup
# ============================================================================
if( not file_loaded?(__FILE__) )
	UI.menu("Draw").add_separator
    UI.menu("Draw").add_item("NGoda") {AspendedNGoda.new}
    UI.menu("Draw").add_item("Copy NGoda Sheets") {AspendedNGoda.copySheet}
end

file_loaded(__FILE__)
#-----------------------------------------------------------------------------


