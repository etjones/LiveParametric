require 'liveParametric.rb'

class SimplestLP < LiveParametric
	@@promptStr = "Square? "
	@@sizeStr = "Size"
	@@shapeStr = "Shape"
	
	def default_variables
		[Checkbox.new( 	@@promptStr, true),
			Slider.new( @@sizeStr, 10, 100, 100),
			# DropdownList.new( @@shapeStr, ["Square", "Circle", "Triangle"], "Circle")
			RadioButton.new( @@shapeStr, ["Square", "Circle", "Triangle"], "Circle")
				]
	end
	
    def create_entities( data, container)
		isSquare = data[@@promptStr]
		size = data[@@sizeStr]
		shape = data[@@shapeStr]
		# if isSquare
		# 		container.add_face( [0,0,0], [size,0,0], [size,size,0], [0,size,0])
		# 	else
		# 		container.add_face( [0,0,0], [size,0,0], [size,size,0])
		# 	end
		
		case shape
		when /Square/: 		container.add_face( [0,0,0], [size,0,0], [size,size,0], [0,size,0])
		when /Circle/: 		container.add_circle( [0,0,0], [0,0,1], size)
		when /Triangle/: 	container.add_face( [0,0,0], [size,0,0], [size,size,0])
		else puts shape
		end
	end
end 