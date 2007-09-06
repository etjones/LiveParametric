
require 'parametric'
require 'LiveParametricHTMLWriter.rb'
require 'ParameterDict.rb'

include EJ
# TODO: make sure all VariableDict classes are loaded here, so all subclasses of 
# LiveParametric have access to them without specifically requiring them
class LiveParametric < Parametric
	@@current_instances = {}


    # Initialize
    def initialize(*args)
        data = args[0]
		
		if not data
 
            @dict = self.default_dict
			@dialog_open = false
			
			Sketchup.file_new if not Sketchup.active_model
            # Launch the WebDialog to control the app
            launchWebDialog()

            ## THIS would be good to encapsulate here, but we need to know
            # the file the subclass is defined in.  Instead, addToPluginsMenu
            # is called in create_entities -- ETJ 29-Jun-2007
            # self.addToPluginsMenu
        end

        super(data)
    end

	def LiveParametric.current_instance(anID)
		@@current_instances[anID]
	end

	def launchWebDialog
		return if @dialog_open
		
		# puts "in LiveParametric.initialize: #{@dict.variableDicts} variableDicts is nil before"
        # Create the html code that will run the WebDialog.
		#TODO htmlFilename should have a unique identifier that's linked this run so multiple instances don't confuse it.
		fileArr = ["ETJ","LiveParametric","html", "#{self.class}_#{@dict.unique_ID}.html"]
		htmlFilename = File.join( EJ::plugins, *fileArr )
        htmlWriter = LiveParametricHTMLWriter.new( @dict, htmlFilename)

		# return nil if @dialog_open or (htmlWriter.filename.length == 0)
			
		#Create the web dialog
		scrollable = true
		resizable = false
		html_width  = [htmlWriter.width, 350].max # SU tend to pop this to 350 regardless of whether resizable is true
		html_height = htmlWriter.height
		# puts "launchWebDialog: dict = #{@dict} title:#{@dict.title} w:#{html_width} h:#{html_height}"
		dialog = UI::WebDialog.new(@dict.title, scrollable, "nil", html_width, html_height, 850, 150, resizable);

		# Process variable changes from the WebDialog
		dialog.add_action_callback("did_change") {|d,p| 
			key,val = p.split(",") if p
			# puts "LiveParametric.did_change:  #{key}: #{val}"
			
			# Only redraw if we have valid data
			if key and val
				# Find the dictionary that describes the changed variable
				changedVarDict = @dict.variableDicts.find{|d| d.unique_id == key}
				
				# Change its variable
				changedVarDict.setVal( val)
			
				# reload from the changed values
				LiveParametric.editFromDict( @dict)
			end
		}
	
		# Remove the html file when the dialog closes so we don't clutter everything up. 
		dialog.set_on_close{
			@dialog_open = false
			htmlWriter.delete_file
		}
	
		@dialog_open = true
		dialog.set_file(htmlWriter.filename, nil)
		# dialog.set_html(htmlWriter.html)
		dialog.show

	end

    def addToPluginsMenu( file)
        if not file_loaded?(file)
            m = UI.menu("Plugins")
            m.add_separator
            m.add_item(self.pluginMenuName) {LiveParametric.editFromDict( )}
        end
        file_loaded(file)
    end

    def pluginMenuName
        "Update #{self.class}"
    end

    # Parametric asks the user for input,  resulting in a 'data' object.
	# Supply it here
    def prompt( operation)
		if not @dict
			@dict = self.default_dict unless @dict
			launchWebDialog
		end
       	LiveParametric.dataFromDict( @dict)	
    end

    def default_dict
        # ParameterDict args: ( title, parametricClassName, *variableDicts)
        p = ParameterDict.new( 	self.controller_title,
        					self.class.to_s,
        					self.default_variables
        					)
		@@current_instances[p.unique_ID] = self

		p
    end
  
	def LiveParametric.dataFromDict( dict)
		data = dict.to_param_hash
	end
	
	def setDict(dict)
		@dict = dict
	end
	
	#override the method defined in parametric.rb, so that WebDialogs 
	# can be persistently attached to a single object
	def Parametric.edit(ent)
		puts "Parametric.edit defined in LiveParametric called. currentInstances is: #{@@current_instances.keys.join(" ")}"
	    if( not Parametric.parametric?(ent) )
	        UI.beep
	        puts "#{ent} is not a parametric Entity"
	        return false
	    end

		# Have we been asked to edit a LiveParametric object?
		# If the passed in SU entity was formed by an instance of LiveParametric, 
		# then we want to preserve its current values and just call its associated 
		# WebDialog.  If not... continue with the normal Parametric behaviors
		
		if id = ent.get_attribute("skpp", "unique_ID")
			if obj = LiveParametric.current_instance(id)
				obj.launchWebDialog 
				return
			end
		end

	    # Get the class of the parametric object
	    klass = Parametric.get_class(ent)

	    # Create a new parametric object of that class
	    new_method = eval "#{klass}.method :new"
	    obj = new_method.call ent
	    if not obj
	        puts "Could not create the parametric object for #{klass}"
	        return false
	    end

	    # Now edit the object
	    obj.edit
	end
	
	
	def LiveParametric.editFromDict(dict)
		if not dict
			puts "LiveParametric.editFromDict  called with nil. returning"
			return nil
		end
		# puts "LiveParametric.editFromDict: d = #{dict}"
		data = LiveParametric.dataFromDict(dict)
        return unless data

        # create a new window if there's no window that's active
        Sketchup.file_new unless Sketchup.active_model

        ent_ID = data["unique_ID"]
		# If the LiveParametric object is already inside a group, this won't work...
        entity = Sketchup.active_model.active_entities.find{|e| e.get_attribute("skpp", "unique_ID") == ent_ID}

        klass = data["class_name"]
        new_method = eval "#{klass}.method :new"

		# ETJ DEBUG
		# entity = nil
		# puts "LiveParametric.editFromDict:  ent_ID: #{ent_ID}, entity: #{entity} "
		# END DEBUG

        if entity
            # if there's already an entity, edit will replace it with the new version
            obj = new_method.call entity
			obj.setDict( dict)
            obj.edit
        else
            # otherwise, just create a new object
            obj = new_method.call data
        end
        nil
    end

  	########################################
    # Methods required of all LiveParametric subclasses
    ########################################
    def create_entities( data, container)
        puts <<-EOS
		#{self.class}: create_entities(data, container) method must be overridden by all subclasses
        # Valid implementations parse data and create shapes which are added to container:
        # ex:
        #
        # radius = data[@@radiusStr]
        # numSides = data[@@numSidesStr]
        #
        #  center = Geom::Point3d.new( 0,0,0)
        #  normal = Geom::Vector3d.new( 0,0,1)
        #
        #  circle = container.add_circle (center, normal, radius, numSides)
        EOS
    end

    def default_variables
        puts <<-EOS
		#{self.class}: default_variables() method must be overridden by all subclasses
        # A valid return value is an array of instances of VariableDict subclasses:
        # ex:
        # [# Slider args:  sliderLabel, minVal, maxVal, curVal, integer_only?
        # 	Slider.new( @@radiusStr,   1,  10, 2),
        # 	Slider.new( @@numSidesStr, 3, 100, 6, true)
        # ]
		EOS
    end

    ########################################
    # Methods optional for all LiveParametric subclasses
    # See also optional methods in parametric.rb for key translation, data validation, etc.
    ########################################
    def controller_title
        # Override with a more descriptive title in subclass if desired
        self.class.to_s
    end

end 

 

  

