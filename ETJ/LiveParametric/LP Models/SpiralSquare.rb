#-- ETJ 03-Jun-2007


require 'liveParametric'


class Spiral < LiveParametric
    @@armCountStr = 'Arm Count'
    @@interSegAngleStr = 'Angle Between Segments'
    @@segLengthStr = 'Segment Length'
    @@numSegStr = 'Number of Segments'
    @@angleMultStr = 'Curvature'

    def default_variables
        [
            Slider.new(@@armCountStr, 2, 32, 6, true),
            Slider.new(@@interSegAngleStr), # range, 0 to 1 radians ~0 to 60 degrees
            Slider.new(@@segLengthStr, 0, 10, 1),
            Slider.new(@@numSegStr, 2, 100, 20, true),
            Slider.new(@@angleMultStr, 0, 5, 3)
        ]
    end

    def create_entities( data, container)
        armCount = data[@@armCountStr]
        interSegAngle = data[@@interSegAngleStr]
        segLength = data[@@segLengthStr]
        numSegs = data[@@numSegStr]
        angleMult = data[@@angleMultStr]

		whichOpt = 2
        case whichOpt
        when 1
            # Since the angle between each segment and the next is identical, this isn't really a spiral.
            #              Add enough segments for the angle between segments and each arm will complete a circle back
            #               to the center point.  True spirals wouldn't ever reach the center again
            armCount.times { |n|
                lastPoint = [0,0,0]
                numSegs.times { |i|
                    angle = n*360.degrees/armCount + i*interSegAngle
                    nextPoint = Geom::Point3d.new(lastPoint.x + segLength*Math.cos(angle), lastPoint.y + segLength*Math.sin(angle),0)
                    container.add_line( lastPoint, nextPoint)
                    lastPoint = nextPoint
                }
            }

        when 2
            #instead, decrease the angle slightly with each segment
            # This is even weirder -- angleMult around 0.9 starts with a spiral in
            # one direction and ends up going in another. Not what I was looking for but bitchin cool.
            armCount.times { |n|
                lastPoint = [0,0,0]
                numSegs.times { |i|
                    angle = n*360.degrees/armCount + (i*interSegAngle)*angleMult**i
                    nextPoint = Geom::Point3d.new(lastPoint.x + segLength*Math.cos(angle), lastPoint.y + segLength*Math.sin(angle),0)
                    container.add_line( lastPoint, nextPoint)
                    lastPoint = nextPoint
                }
            }

        when 3
			# Unsatisfactory
            center = Geom::Point3d.new(0,0,0)
            rad = 1

            armCount.times { |n|
                radialAngle = n*360.degrees/armCount
                lastPoint = Geom::Point3d.new(rad,0,0).transform( Geom::Transformation.rotation( center, [0,0,1], radialAngle))

                numSegs.times { |i|
                    # Equiangular spiral:  nextPoint lies on a line perpendicular to
                    # the (center, lastPoint) vector, and (lastPoint, nextPoint)
                    # has a length proportional to the length of the radial vector

                    radialVec = lastPoint-center
                    perpVec = (lastPoint - center).perpVec2d
                    perpVec.length = radialVec.length * angleMult
                    nextPoint = lastPoint+perpVec

                    container.add_line( lastPoint, nextPoint)
                    lastPoint = nextPoint
                }
            }
        end

    end
end
