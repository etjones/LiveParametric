
class ParameterDict
    attr_reader :variableDicts, :outputPath, :title, :updateMethodStr, :unique_ID, :className

    def initialize( title, parametricClassName, variableDicts)
        @title = title
        @className = parametricClassName
        @updateMethodStr = updateMethodStr
        @outputPath = outputPath
        @unique_ID = self.object_id
        @variableDicts = variableDicts
		
		# Set unique_ids for each variableDict
		@variableDicts.each_with_index {|e, i|  
			e.unique_id = "#{e.class}_#{i}"
		}

    end

    def to_param_hash
        data = {}
        @variableDicts.each{ |e| data[e.title] = e.val}
        data["unique_ID"] = @unique_ID
        data["class_name"] = @className
        data
    end

    def setVariableDicts( dictsArr)
        @variableDicts = dictsArr
    end

end