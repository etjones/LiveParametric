require 'sketchup.rb'
curDir = File.dirname(__FILE__)

def require_recursive( topDir)
	# puts "require_recursive called on #{topDir}"
	return nil unless File.directory?(topDir)
	
	$: << topDir
	subdirs = Dir.entries(topDir).map{|d|
			# don't include any directories starting with .
		 	next if d[0,1] == '.'
			fullDir = File.join(topDir,d)
			fullDir if File.directory?(fullDir) 
	}.compact
	
	# puts "Subdirs:\n\t"+subdirs.join("\n\t") if subdirs.length >0
	
	subdirs.each{|d| require_recursive(d)} if subdirs.length > 0
	
	 rbFiles = Dir[File.join(topDir, "*.rb")]
	 rbFiles.each {|e| require e }	if rbFiles.length > 0
end

require_recursive( File.join(curDir, "LiveParametric"))