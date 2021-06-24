class SymbologiesController < ApplicationController

  def create
    base_sym = Symbology.find_by_id(params[:base_symbology_id])
    @new_sym = base_sym.get_clone(params[:symbology][:subject], JSON.parse(params[:color_schemes], symbolize_names: true))

    @new_sym.save
  end

  def destroy
    @sym = Symbology.find_by_id(params[:id])
    @sym.destroy
  end
end
