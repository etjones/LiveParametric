require 'liveParametric'

class ParametricCircle2 < LiveParametric
	@@radiusStr = "Radius"
	@@numSidesStr = "Number of Sides"

	def default_variables
		# NOTE: Because the controller app that uses these variables
		# doesn't have access to Sketchup's length handling routines,
		# it's best to pass measurements in as raw numbers and do any later
		# postprocessing in create_entities.
		# Another possibility would be to add some unit-handling to VariableDict,
		# but that seems like more complication than necessary -- ETJ 21-May-2007
		
		[# Slider args:  sliderLabel, minVal, maxVal, curVal, integer_only?
		Slider.new( @@radiusStr, 	1, 10, 2),	  
		Slider.new( @@numSidesStr, 	3, 20, 6, true) 		
		]
	end

	def create_entities(data, container)
		r = data[@@radiusStr]
		numSides = data[@@numSidesStr]

		center = Geom::Point3d.new( 0,0,0)
		normal = Geom::Vector3d.new( 0,0,1)

		circle = container.add_circle( center, normal, r, numSides)

		# ETJ DEBUG
		container.add_text( data["unique_ID"].to_s, circle[0].vertices[0].position)
		# END DEBUG

	end	
end

#=============================================================================
# Add a menu to create shapes
if( not file_loaded?(__FILE__) )
	menu = UI.menu("Draw")
	menu.add_separator
    menu.add_item("Parametric Circle") { ParametricCircle2.new }
    
    file_loaded(__FILE__)
end