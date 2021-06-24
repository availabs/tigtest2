# This is the fundamental step to resolve a list of symbology related stories
# https://www.pivotaltracker.com/story/show/89317526
# Summary: move symbology configs out of views_controller to Symbology and associated models

# remove existing symbology
Symbology.destroy_all if ENV['CLEAR_ALL']

View.all.each do | view |
  "#{view.data_model}SymbologyService".constantize.new(view).configure_symbology rescue nil
end
