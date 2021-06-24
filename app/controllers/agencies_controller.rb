class AgenciesController < ApplicationController
  before_action :set_agency, only: [:show, :edit, :update, :destroy]

  def index
    @agencies = Agency.all
    authorize! :index, @agencies
  end

  def show
    authorize! :show, @agency
  end

  def new
    @agency = Agency.new
    if user_signed_in?
      @users = User.with_any_role(:agency_user, :agency_admin, :public).reject{|u| !u.agency.nil? }.map{ |c| [(c.display_name.blank? ? c.email : c.display_name), c.id] }
    end
  end

  def edit
    add_breadcrumb "Edit Agency"
    @eligible_users = []
    users = User.with_any_role(:agency_user, :agency_admin, :public).reject{|u| !u.agency.nil? }
    users.each { |c| @eligible_users << [(c.display_name.blank? ? c.email : c.display_name), c.id] }
    @selected_users = @agency.users.map{|c| [(c.display_name.blank? ? c.email : c.display_name), c.id]}
    @users = @eligible_users + @selected_users
  end

  def create
    @agency = Agency.new(agency_params)

    respond_to do |format|
      if @agency.save
        if params[:agency][:user_ids]
          user_ids = params[:agency][:user_ids].reject(&:blank?).map(&:to_i)
          @agency.user_ids = user_ids
          User.find(user_ids).each {|user| user.has_role?(:agency_user) ? '' : user.add_role(:agency_user)}
        end

        format.html { redirect_to @agency, notice: 'Agency was successfully created.' }
        format.json { render json: @agency, status: :created, location: @agency }
      else
        format.html { render action: "new" }
        format.json { render json: @agency.errors, status: :unprocessable_entity }
        if user_signed_in?
          @eligible_users = User.with_any_role(:agency_user).reject{|u| u == current_user }.map{ |c| [c.email, c.id] }
          @selected_users = [[current_user.email, current_user.id]]
        end
      end
    end
  end

  def update
    respond_to do |format|
      if params[:agency][:user_ids]
        ids_before = @agency.user_ids
        ids_after = params[:agency][:user_ids].reject(&:blank?).map(&:to_i)
      end

      if @agency.update(agency_params)
        if params[:agency][:user_ids]
          @agency.user_ids = ids_after
          users_to_change = ids_before.length > ids_after.length ? (ids_before - ids_after) : (ids_after - ids_before)
          add_or_remove = ids_before.length > ids_after.length ? 'remove' : 'add'

          if add_or_remove == 'remove'
            User.find(users_to_change).each do |user|
              user.remove_role(:agency_user) if user.has_role?(:agency_user)
              user.remove_role(:agency_admin) if user.has_role?(:agency_admin)
            end
          else
            User.find(users_to_change).each {|user| user.has_role?(:agency_user) ? '' : user.add_role(:agency_user)}
          end
          User.find(users_to_change).each {|user| user.add_role(:public) if user.roles.empty?}
        end
        format.html { redirect_to (current_user.agency ? @agency : root_path), notice: 'Agency updated.' }
        format.json { render json: @agency, status: :created, location: @agency }
      else
        format.html { render action: "edit", notice: 'There was a problems saving the agency.' }
        format.json { render json: @agency, status: :created, location: @agency }
      end
    end
  end

  def destroy
    if @agency.destroy
      redirect_to agencies_path
      flash[:notice] = "Agency deleted."
    end
  end

  private
    def set_agency
      @agency = Agency.find(params[:id])
    end

    def agency_params
      params.require(:agency).permit(:name, :description, :url, :user_ids)
    end
end
