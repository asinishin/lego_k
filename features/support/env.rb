require 'rubygems'

# Requires all development files
Dir[File.expand_path(File.dirname(__FILE__)) + "/../../lib/lego_k/**/*.rb"].each {|f| require f}
