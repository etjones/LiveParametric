require 'VariableDict.rb'

class Slider < VariableDict
    attr_reader :minVal, :maxVal, :curVal, :integerOnly

    def initialize( varTitle, minVal=0, maxVal=1.0, curVal=0.5, integerOnly=false)
        super(varTitle)
        @minVal = minVal
        @maxVal = maxVal
        @curVal = curVal
        @integerOnly = integerOnly

    end

    def val
        @curVal
    end
	
	def setVal( val)
		if integerOnly
			@curVal = val.to_i
		else
			@curVal = val.to_f
		end
	end
	
	def headerCode
	    return []
	end

    def to_html
        sliderWidth = @html_width -25

        title = varTitle
        sliderId = unique_id+"_slider"

        if integerOnly
            cur = curVal.to_i
            min = minVal.to_i
            max = maxVal.to_i
			rValStr = 'Number(this.value).toFixed(0)' 
		    stepStr = ''
		else
            cur = sprintf("%.2f",curVal)
            min = sprintf("%.2f",minVal)
            max = sprintf("%.2f",maxVal)		    
    		rValStr = 'Number(this.value).toFixed(2)'
            stepStr = "step='#{(maxVal-minVal)/20.0}'"
		end
		
		onChangeStr = %Q{onChange="document.getElementById('#{unique_id}').innerHTML = #{rValStr}; did_change('#{unique_id}', #{rValStr})"}
   
        sliderStr = <<-EOS
        <table border="0" width=#{sliderWidth}px align="center">
        <tr><td align ="left">#{title}:</td><td align="right" id="#{unique_id}">#{cur}</td></tr>
        <tr><td colspan="2">
            <input type="range" id="#{sliderId}" value="#{cur}" min="#{min}" max="#{max}" #{stepStr} #{onChangeStr}/>
        </td></tr>
        <tr><td align ="left">#{min}</td><td align="right">#{max}</td></tr>
        </table>

        EOS

        sliderStr
    end
end
