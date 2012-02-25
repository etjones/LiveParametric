require 'VariableDict.rb'

class Slider < VariableDict
    attr_reader :minVal, :maxVal, :curVal, :integerOnly, :showMinMax

    def initialize( varTitle, minVal=0, maxVal=1.0, curVal=0.5, integerOnly=false, showMinMax=false)
        super(varTitle)
        @minVal = minVal
        @maxVal = maxVal
        @curVal = curVal
        @integerOnly = integerOnly
        @showMinMax = showMinMax
        
        @html_width = 175
        @html_height = 60

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

        textW = Math::log10( maxVal).ceil + ( minVal < 0 ? 1 : 0) + 1
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
            textW += 3
        end
        minMaxStr = ''
        if showMinMax
            minMaxStr = %Q{\n        <tr><td align ="left">#{min}</td><td align="right">#{max}</td></tr>\n}
        end
        dgb = "document.getElementById"
        sliderChangeStr = %Q{onChange="#{dgb}('#{unique_id}').value = #{rValStr}; did_change('#{unique_id}', #{rValStr})"}
        textChangeStr   = %Q{onChange="#{dgb}('#{sliderId}' ).value = #{rValStr}; did_change('#{unique_id}', #{rValStr})"}
    
        sliderStr = <<-EOS
        <table border="0" width=#{sliderWidth}px align="center">
        <tr><td align ="left">#{title}:</td>
            <td align="right"> 
                <input type="text" id="#{unique_id}" size="#{textW}" value="#{cur}" #{textChangeStr}">
            </td>        
        </tr>
        <tr><td colspan="2" align="center">
            <input type="range" id="#{sliderId}" value="#{cur}" min="#{min}" max="#{max}" #{stepStr} #{sliderChangeStr}/>
        </td></tr>#{minMaxStr}
        </table>

        EOS

        sliderStr
    end
end
