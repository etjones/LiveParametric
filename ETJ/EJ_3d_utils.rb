# #!/usr/bin/env ruby -wKU

require 'sketchup.rb'
module EJ
	def plugins
		$:[0]
	end
	
	def purge_dir( dir, delete_container=false)

	    return nil unless File.directory?(dir)

	    Dir.entries(dir).reject{|e| e =~ /^\./}.each{|e|
	        wholeE = File.join(dir,e)
	        if File.directory?(wholeE)
	            purge_dir( wholeE, true)
	        else
	            File.delete(wholeE)
	        end
	    }
	    Dir.delete(dir) if delete_container
	end
	
	def load_plugins
		load_all( $:[0])
	end
	
	def load_all(root_dir)
		rbFiles = recursive_file_list(root_dir).select{|f| File.extname(f) =~ /\.rb.?/}
		rbFiles.each{|f| load f}
	end
	
	# takes an absolute path and builds a depth-first list
	# of all files rooted in root_dir
	def recursive_file_list( root_dir)
		return nil unless File.directory?(root_dir)
		list = []
		Dir.entries( root_dir).reject{|e| e=~/^\./}.each { |e|  
			path = File.join( root_dir, e)
			if File.directory?( path)
				# puts "Dir: #{path}"
				 list += recursive_file_list(path)
			elsif File.file?(path)
				# puts "File: #{path}"
				 list << path
			end	
		}
		list
	end
end

def hardenEdges
    sel = Sketchup.active_model.selection
    arr = flattenSU_Obj(sel).find_all{|e| e.class == Sketchup::Edge}
    arr.each {|e| e.soft = false  }
    nil
end

def selectEdgesInSelectedGroup
    Sketchup.active_model.start_operation "Select Edges In Group"
    sel = Sketchup.active_model.selection

    arr = flattenSU_Obj(sel).find_all{|e| e.class == Sketchup::Edge}

    # edges in arr aren't contiguous.
    # assuming they _are_ a closed loop, put them in order
    ordered = [arr.first]
    0.upto(arr.length-2){|i|
        ordered << arr.find{|e| e.vertices[0].position == ordered[i].vertices[1].position}
    }
    if ordered.last.vertices[1].position != ordered.first.vertices[0].position
        print "Loop isn't closed\n"
    else print "Loop closed!\n" end

    ordered.each {|e| p e }
    #
    # 		print "\n\n"
    # 		arr.each {|e| p e }

    sel.clear
    sel.add(*ordered)
    Sketchup.active_model.commit_operation
end

def printSelectedEdges
    sel = Sketchup.active_model.selection
    arr = flattenSU_Obj(sel).find_all{|e| e.class == Sketchup::Edge}
    arr.each {|e| print "#{e.vertices[0].position} to #{e.vertices[1].position}\n" }
    nil
end

def rip(soften=nil)

    soften = true if soften # if anything is passed in, soften, otherwise, no

    Sketchup.active_model.start_operation "Print Faces"
    sel = Sketchup.active_model.selection
    printTree(sel, 0, soften)
    Sketchup.active_model.commit_operation
end

def printTree( obj, level, soften=false)
    str = nil

    case obj
    when Sketchup::Edge
        str = "Edge: " + obj.vertices.collect{|e| "#{e.position.to_s}, " }.join
        obj.soft = false if soften
    when Sketchup::Face
        str = "Face: " + obj.vertices.collect{|e| "#{e.position.to_s}, " }.join
    else
        str = obj.to_s
    end

    print "\t"*level,"#{str}\n" if str

    if  obj.respond_to?(:entities)
        obj.entities.each{ |e| printTree(e, level+1, soften)}
    elsif obj.respond_to?(:each)
        obj.each {|e| printTree(e, level+1,soften) }
    elsif
        obj.respond_to?(:definition)
        obj.definition.entities.each{|e| printTree(e, level+1, soften)}
    end
end

def allPoints(obj)
    all = flattenSU_Obj(obj)
    points = []
    all.each {|e|
        e.vertices.each {|f| points << f.position } 	if e.class == Sketchup::Edge
    }

    uniqePoints = []
    points.each {|e| uniqePoints<<e unless uniqePoints.find{|d| e==d} }

    uniqePoints
end

def labelPoints
    Sketchup.active_model.start_operation "Label Selected Points"
    sel = Sketchup.active_model.selection

    #add the labels to the first group we find,
    # or just create a new group if we don't find
    # a group before finding a face.  This could
    # ETJ -- attach labels to the wrong group.  7 March
    g = findClassInTree(Sketchup::Group,sel)
    if g: ents = g.entities.add_group.entities
    else  ents = Sketchup.active_model.entities.add_group.entities  end


    points = allPoints(sel)
    points.each {|e| p e }
    # points.sort!{|a,b|
    # 			if a.x<b.x then -1
    # 			elsif a.x > b.x then 1
    # 			elsif a.z == b.x
    # 				if a.y < b.y then -1
    # 				elsif a.y > b.y then 1
    # 				elsif a.y == b.y && a.x == b.x # redundant test
    # 					if a.z < b.z then -1
    # 					elsif a.z > b.z then 1
    # 					else 0
    # 					end
    # 				end
    # 			end
    # 		}
    points.each_with_index { |e, i| ents.add_text( "#{i}", e)}

    Sketchup.active_model.commit_operation
end

def hier
    printContained(Sketchup.active_model.entities)
end

def printContained( ent, depth = 0)
    depthStr = "\t"*depth
    print "#{depthStr} #{ent}\n"

    printBlock = lambda	 {|e|
        printContained(e, depth+1) if e.respond_to?(:each) || e.respond_to?(:entities)
        if e.attribute_dictionaries
            e.attribute_dictionaries.each {|f|
                if !e.class.to_s.include?"Edge"
                    puts "#{depthStr}#{e} #{f.name} Keys: #{f.keys.join(", ")}"
                end
            }
        end
    }

    if ent.respond_to?(:each)
        ent.each(&printBlock)
    else
        ent.entities.each(&printBlock)
    end
end

# flattenSU_Obj & findClassInTree could both be
# done better using a proc
def flattenSU_Obj(o)
    arr = []
    arr << o
    if o.respond_to?(:entities)
        o.entities.each{|e|
            arr += flattenSU_Obj(e)
        }
    elsif o.respond_to?(:each)
        o.each{|e|
            arr+= flattenSU_Obj(e)
        }
    elsif o.respond_to?(:definition)
        o.definition.entities.each{ |e|
            arr+= flattenSU_Obj(e)
        }
    end
    arr
end

def findClassInTree( aClass, tree)
    if tree.class == aClass
        return tree
    elsif tree.respond_to?( :entities)
        return tree.entities.find {|e|  findClassInTree(aClass, e)}
    elsif tree.respond_to?( :each)
        return tree.find{|e| findClassInTree(aClass, e)}
    end
    nil
end

def findClassesInTree( aClass, tree= Sketchup.active_model.entities)
    classes = []
    classes << tree if tree.class == aClass

    if tree.respond_to?( :entities)
        tree.entities.each { |e| classes << findClassesInTree(aClass, e) }
    elsif tree.respond_to?( :each)
        tree.each { |e| classes << findClassesInTree(aClass, e) }
    end
    classes.flatten.compact
end

def labelObjects( sketchupClass)
    Sketchup.active_model.start_operation "Label Objects of Class #{sketchupClass}"

    sel = Sketchup.active_model.selection

    #add the labels to the first group we find,
    # or just create a new group if we don't find
    # a group before finding a face.  This could
    # ETJ -- attach labels to the wrong group.  7 March
    g = findClassInTree(Sketchup::Group,sel)
    if g: ents = g.entities.add_group.entities
    else  ents = Sketchup.active_model.entities.add_group.entities  end

    classCount = 0
    arr = 	flattenSU_Obj(sel)
    arr.each {|e|
        case e
        when sketchupClass
            ents.add_text( "#{classCount}", centerPoint(e))
            # e.parent.entities.erase_entities(e)
            classCount += 1
        when Sketchup::Edge # extraneous but useful
            e.soft = false
        end

    }
    print "#{arr.length} items traversed\n"
    Sketchup.active_model.commit_operation
end

# doesn't update live - needs help
def selectFacesInOrder
    oldSel = Sketchup.active_model.selection
    p "oldSel = #{oldSel}\n"
    arr = flattenSU_Obj(oldSel)
    p "arr = #{arr}\n"

    arr.each{|e|
        # print "#{e}\n"
        p e
        if e.class == Sketchup::Face
            p "Face detected\n"
            Sketchup.active_model.selection.clear
            Sketchup.active_model.selection.add(e)
            Sketchup.active_model.selection.add(e.edges)

            # sleep(0.5)
        end
    }
end

def centerPoint(face)
    x = 0
    y= 0
    z = 0
    face.vertices.each {|e|
        x += e.position.x
        y += e.position.y
        z += e.position.z
    }
    n = face.vertices.length

    Geom::Point3d.new(x/n, y/n, z/n)
end

# **************************************************************************
# * modifications or additions to Sketchup's classes
# **************************************************************************
class ComponentInstance
    def entities
        definition.entities
    end
end

# add dashed and evenly spaced lines, like mountain and valley folds
module Sketchup
	def plugins_dir
		Waybe::plugins
	end
	
    class Entity
        def addCopyToEntities( entities)
            added =	case self
            when Face
                # puts "#{self.class} added"
                # Faces in a new model have to be made up of Point3d's since the Edges
                # all have a parent that can't be changed.  In order to do this without
                # any crossovers, we need to sort the points in an unbroken order:
                # Edges:   (a,b), (b,c), (c,d), (d,a)
                # Sometimes, though, these will be out of order: (a,b), (c,b), (c,d), (a,d)
                # So generate the correct list of points:  (a,b,c,d):

                # Pick an initial edge and add its points
                # Find another edge that contains the last point in that edge
                # Add the second point of the found edge to the list of points
                # remove the found edge  from consideration
                # look for the next edge which contains the point just added, until face.edges.length points are found
                arr = self.edges.clone

                points = arr.shift.vertices.map{|v| v.position}
                points_found = 2
                while points_found < self.edges.length
                    arr.each {|e|
                        pa, pb = e.vertices.map{|v| v.position}
                        if pa == points.last or pb == points.last
                            points << (pa == points.last ? pb : pa)
                            arr.delete(e)
                            points_found += 1
                            break
                        end
                    }
                end
                # points.each {|e| puts e }
                entities.add_face( points)
            when Edge
                # puts "#{self.class} added"
				added = entities.add_line( self.vertices.map{|v| v.position})
            when Group
                puts "#{self.class} added clumsily.  Works? "+self.to_s

                added = entities.add_group

                to_add = self.entities.map{|e| e.addCopyToEntities( added.entities)}
                # I bet this doesn't work-- ETJ 12-Jul-2007
            when Entities, ComponentInstance
                puts "#{self.class} ignored"

                # Should handle these some time... TODO -- ETJ 12-Jul-2007
                nil
            else # lots of other things here need to be covered
                puts "#{self.class} ignored "+self.to_s
                nil
            end
            added
        end
    end

    class Entities
		def add_valley_line( p1, p2)
			self.add_cline( p1, p2, "--")
		end
		
		def add_mountain_line( p1, p2)
			self.add_cline( p1, p2, "-.-")
		end
    end
end

module Geom
    class Point3d
        def Point3d.rTheta( r, theta, phi=0)
            x = r*Math.cos(theta)
            y = r*Math.sin(theta)
            z = r*Math.sin(phi)
            Point3d.new( x,y,z)
        end

        def midpoint( p2)
            Geom::linear_combination( 0.5, self, 0.5, p2)
        end

    end

    class Vector3d
        def Vector3d.rTheta( r, theta, phi=0)
            x = r*Math.cos(theta)
            y = r*Math.sin(theta)
            z = r*Math.sin(phi)
            Vector3d.new( x,y,z)
        end

        def perpVec2d
            self.transform( Geom::Transformation.rotation( [0,0,0], [0,0,1], -90.degrees))
        end

        def to_s
            sprintf("(%8.3f, %8.3f, %8.3f)", self.x, self.y, self.z)
        end
    end

    def intersect_segment_segment( p1, p2, p3, p4)
        intersection = Geom::intersect_line_line([p1,p2],[p3,p4])
        return nil if intersection == nil

        comboVal1 = combinationVal( p1, p2, intersection)
        comboVal2 = combinationVal( p3, p4, intersection)

        if comboVal1 >= 0 && comboVal1 <= 1 &&  comboVal2 >= 0 && comboVal2 <=1
            return intersection
        else
            return nil
        end
        # Possible cases:
        # -- lines are parallel:  					return nil
        # -- lines intersect, but segments don't: 	return nil
        # -- segments intersect: 					return point
    end
end
# ============================================================================
#  Sketchup menu setup
# ============================================================================
# if( not file_loaded?(__FILE__) )
#     # add_separator_to_menu("Plugins")
#     UI.menu("Plugins").add_item("Harden Selected Edges") {hardenEdges}
# end
# file_loaded(__FILE__)
