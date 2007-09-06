require 'sketchup.rb'
require 'liveParametric.rb'


class BatWing < LiveParametric
    @@boneSeparationStr = "Bone Separation"
    @@curveStr = "Bone Curve"
    @@openStr = "Opened Angle"
    @@radiusLengthStr = "Radius Bone Length"

    def default_variables
        [ 	Slider.new( @@boneSeparationStr),
            Slider.new(@@curveStr),
            Slider.new(@@radiusLengthStr),
            Slider.new(@@openStr)
        ]
    end

    def create_entities( data, container)
      
        maxBoneSep = 20.cm
        maxExtensionAngle = 60.degrees
        boneSep = data[@@boneSeparationStr] * maxBoneSep
        # boneCurve = data[@@curveStr] # Need to figure how to work this
        openAngle = data[@@openStr] *maxExtensionAngle

        # radius is above ulna.  This may not be anatomically correct
        ulnaPoint = Geom::Point3d.new(2.cm, 20.cm, 0)
        radiusPoint = ulnaPoint + [0,boneSep, 0]

        minRadiusLength = 20.cm
        maxRadiusLength = 40.cm
        radiusLength = minRadiusLength + data[@@radiusLengthStr]*( maxRadiusLength- minRadiusLength)

        ulnaLength = fingerLength = 30.cm


        # For the moment, leave out curves
        radiusEnd = radiusPoint + Geom::Vector3d.rTheta(radiusLength, 90.degrees - openAngle)
        ulnaEnd  = ulnaPoint + Geom::Vector3d.rTheta( ulnaLength, 90.degrees - openAngle)

        fingerVec = ulnaEnd - radiusEnd
        fingerVec.length = fingerLength
        fingerPoint = Geom::Point3d.new(radiusEnd)
        fingerEnd = radiusEnd + fingerVec

        radiusEdge = container.add_line(radiusPoint, radiusEnd)
        ulnaEdge   = container.add_line(ulnaPoint, ulnaEnd)
        fingerEdge = container.add_line(fingerPoint, fingerEnd)

        # Draw the wing
        segmentPoints = [radiusPoint, radiusEnd, ulnaPoint, ulnaEnd, fingerPoint, fingerEnd]
        (0...segmentPoints.length).step(2){|i| container.add_line( segmentPoints[i], segmentPoints[i+1])}
        #Mirror the wing on the other side
        segmentPoints.map!{|p| p.x *= -1;  p}
        (0...segmentPoints.length).step(2){|i| container.add_line( segmentPoints[i], segmentPoints[i+1])}

    end

    # from ELSheetEdge
    def curved_edge( p1, p2, curvature, entities)
        normal = Geom::Vector3d.new(0,0,1)

        radius = curvature*(p1.distance(p2))

        # this is all about calculating center, startAngle, & endAngle

        midDist = p1.distance(p2)/2.0
        radius = radius< midDist ? midDist: radius

        midPoint = Geom.linear_combination( 0.5, p1, 0.5, p2)

        #which direction this faces isn't specified yet
        # May need to mult by -1
        puts "normal: #{normal.class} p2-p1: #{(p2-p1).class}"
        bulgeVec = normal*(p2-p1)

        if normal.length == 0
            puts "Zero-length normal vector in ELSheet.  Returning."
            return
        end

        midDist = midPoint.distance(p1)
        lengthSq = radius*radius - midDist*midDist
        p "radius: #{radius}  midDist:#{midDist} lengthSq: #{lengthSq}"
        centerDistFromMidPoint =  Math.sqrt(lengthSq)

        bulgeVec.length = centerDistFromMidPoint
        center = midPoint + bulgeVec
        # p "center = #{center}"
        x_axis = p1 - center

        startAngle = 0.degrees
        endAngle = (p1-center).angle_between(p2-center)

        entities.add_arc( center, x_axis, normal, radius, startAngle, endAngle, @segments)
    end

end
