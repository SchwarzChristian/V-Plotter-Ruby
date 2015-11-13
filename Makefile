SRC_FILES	= vplotter.rb

doc: $(SRC_FILES)
	rdoc $^
