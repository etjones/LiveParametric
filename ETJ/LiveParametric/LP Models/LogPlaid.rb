#-- ETJ 29-Jun-2007
require 'liveParametric.rb'

class LogPlaid < LiveParametric
	@@stepsStr = "Steps"
	@@propStr = "Proportion"
   def create_entities( data, container)
		steps = data[@@stepsStr]
		proportion = data[@@propStr]
		start = 0.0
		finish = 1.0
		
		list = logList( start, finish, steps, proportion)
		# puts list
		list.each {|e| 
			container.add_line( [start,e,0], [finish,e,0] )
			container.add_line( [e,start,0], [e,finish,0] )
		}
   
    end

    def default_variables
		[Slider.new(@@stepsStr, 1, 10, 2, true),
		 Slider.new(@@propStr)]
	
    end

	def logList( start, finish, steps, proportion)
		# Steps  |  List
		# 0		| 0, 1							(0,1)
		# 1		| 0,1/2, 1						(0,1,2)/2
		# 2		| 0,1/4,1/2,3/4,1				( 0,1,2,3,4)/4
		# 3		| 0,1/4, 3/8, 1/2, 5/8, 3/4, 1  ( 0,2,3,4,5,6,8)/8
		# 4		| 0,1/4, 3/8, 7/16, 1/2, 9/16, 5/8, 3/4 ( 0,4,6,7,8,9,10,12,16)/16
		
		list = [0,0.5,1]
		(steps-1).times{|i|
			center = list.length/2
			centerVal = list[center] 
			val = (1-proportion)*(list[center]-list[center-1])
			list.insert(center,   centerVal-val )
			list.insert(center+2, centerVal+val)
		}
		# puts list
		list.map{|e| e*(finish-start)+start}
	end
end


