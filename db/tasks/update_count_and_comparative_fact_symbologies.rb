# update default symbologies for count_fact and comparative_fact

View.all.each do | view |
  if view.data_model == CountFact or view.data_model == ComparativeFact
    view.symbologies.destroy_all
    
    "#{view.data_model}SymbologyService".constantize.new(view).configure_symbology rescue nil
  end
end
