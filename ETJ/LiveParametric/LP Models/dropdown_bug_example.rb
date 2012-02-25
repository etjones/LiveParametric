#!/usr/bin/env ruby -wKU

class DropdownBugExample < LiveParametric
    # Correct behavior would yield a dropdown list with these entries:
    #    good element
    #    missing <bracketed> word
    #
    # Actual behavior yields:
    #    good element
    #    missing word
    def default_variables
        possible_vals = ["good element", "missing <bracketed> word"]
        [ DropdownList.new("test_dropdown", possible_vals)]
    end
    def create_entities( data, container)
        container.add_face( [[0,0,0],[0,1,0],[1,0,0]])
    end
end