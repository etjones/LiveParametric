require 'EJ_3d_utils.rb'
require 'liveParametric'

class SpiralFold < LiveParametric
    @@sidesStr = "Sides"
    @@crimpCountStr = "Folds Per Side"
	@@holeSizeStr = "Hole Size"
    @@tileStr = "Tile ?"

    def default_variables
        [
            Slider.new( @@sidesStr, 	3, 12, 	4, true),
            Slider.new( @@crimpCountStr, 3, 25, 7, true),
            Slider.new( @@holeSizeStr, 0.5, 0.9, 0.6),
            Checkbox.new( @@tileStr)
        ]
    end


    def create_entities( data, container)
        addToPluginsMenu(__FILE__)

        sides = data[@@sidesStr]
        folds = data[@@crimpCountStr]
        tile  = data[@@tileStr]
        @holeSize = data[@@holeSizeStr]

        #  TODO: calculate sideLength so that minimal span across the polygon is 20 cm-
        # -- lets it print to a page -- ETJ 08-Jul-2007
        sideLength = 20.cm

        mountainPoints, valleyPoints, cutPoints = foldPoints( sides, folds, sideLength)

        g = container.add_group
        cutPoints.each 		{|e|  g.entities.add_line(*e) 		if e[0].distance(e[1]) > 0}
        mountainPoints.each {|e|  g.entities.add_mountain_line( *e) if e[0].distance(e[1]) > 0}
        valleyPoints.each   {|e|  g.entities.add_valley_line( *e) 	if e[0].distance(e[1]) > 0}

        if tile
            tileGroups( g, cutPoints[0...sides], sides, sideLength, folds)
        end

    end

    def tileGroups( group, corners, sides, sideLength, folds, center = [0,0,0])
        sides.times{|i|
            g2 = group.copy.make_unique
            # first sides cutPoints are the outer polygon
            axisVec = corners[i][1]-corners[i][0]
            # offset each side by enough to make the folds line up on both objects
            al = (2*@holeSize-1)*sideLength + 2*sideLength/folds
            al = 0.01 if al== 0
            axisVec.length = al

            vec2 = axisVec.perpVec2d
            segMidPt = corners[i][0].midpoint( corners[i][1])
            vec2.length = 2*segMidPt.distance(center)

            # translationVec = axisVec
            translationVec = vec2+axisVec

            angle = 0.degrees
            angle = 360.degrees/(2*sides) if sides%2 == 1
            r = Geom::Transformation.rotation( center, [0,0,1], angle)
            t = Geom::Transformation.translation( translationVec)
            t = t*r
            g2.transform!( t)
        }
    end

    def foldPoints( sides, folds, sideLength, center = [0,0,0], rotationAngle = 0)
        mountainPoints = []
        valleyPoints = []
        cutPoints = []

		foldWidth = sideLength/folds
        innerAngle = 360.degrees/sides
        outerRad = (sideLength/2)/Math.sin(innerAngle/2)
        
        center = Geom::Point3d.new(*center)
        vert = Geom::Vector3d.new(0,0,1)

        sides.times { |n|
            # opbRatio = 0.5 + (foldWidth/2)/sideLength
            opbRatio = @holeSize

            outerPoints = []
            perpVec = []
            outerPointB = []

            3.times{|i|
                a= (n+i-1)*360.degrees/sides + rotationAngle
                outerPoints[i] = center + Geom::Vector3d.rTheta( outerRad, a)
            }
            2.times{|i|
                perpVec[i] = ( outerPoints[i+1]- outerPoints[i]).perpVec2d
                outerPointB[i] = Geom::linear_combination( 1-opbRatio, outerPoints[i], opbRatio, outerPoints[i+1])
            }

            innerPolygonPoint = Geom.intersect_line_line( [outerPointB[0], perpVec[0]], [outerPointB[1], perpVec[1]])
            cutPoints 		<< [outerPoints[1], outerPoints[2]]
            mountainPoints 	<< [outerPointB[0], innerPolygonPoint]
            mountainPoints 	<< [outerPointB[1], innerPolygonPoint]

            add_crimps( outerPointB[0], outerPointB[1], innerPolygonPoint, outerPoints[1], foldWidth, mountainPoints, valleyPoints)

        }
        [mountainPoints, valleyPoints, cutPoints]
    end

    def add_crimps( lp, rp, centerP, cornerP, crimpHeight, mountains, valleys)
=begin

lp                centerP
 o-----------------o      
 |______________ / |  ]- crimpHeight
 |              |  |
 |              |  |
 |              |  |
 |              |  |
 o-----------------o
cornerP           rp

	Make crimps all the way to the corner
=end
        lVec = cornerP - lp; lVec.length = crimpHeight unless lVec.length == 0
        rVec = cornerP - rp; rVec.length = crimpHeight unless lVec.length == 0

        nextL = lp + lVec
        nextR = rp + rVec
        oldCP = centerP
        nextCP = Geom::intersect_line_line([nextL, oldCP+lVec], [nextR, oldCP+rVec])


        # for the moment assume that mountain folds come first
        nextFolds = valleys

        while (nextL - lp).length < (cornerP-lp).length && (nextR-rp).length < (cornerP-lp).length
            nextFolds << [nextL, nextCP]
            nextFolds << [nextR, nextCP]
            nextFolds << [oldCP, nextCP]  

            nextFolds = (nextFolds == mountains ? valleys : mountains)
            nextL += lVec
            nextR += rVec
            oldCP = nextCP
            # nextCP = (oldCP + lVec) + rVec
            nextCP = Geom::intersect_line_line([nextL, oldCP+lVec], [nextR, oldCP+rVec])

        end

        # the last line, to the edge of the piece
        if cornerP && rp && oldCP && nextCP
            lastPoint = Geom.intersect_line_line( [cornerP,rp], [oldCP, nextCP])
            nextFolds << [oldCP, lastPoint]
        end
    end

end
