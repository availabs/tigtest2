class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new # guest user (not logged in)
    can :read, StudyArea
    if user.has_role? :admin
      can :manage, :all
    elsif user.has_role? :agency_admin
      can :manage, Agency, id: user.agency_id
      can :manage, User, agency_id: user.agency_id
      can [:create, :read, :update, :delete], Comment
      can :manage, AccessControl
    elsif user.has_any_role? :contributor, :librarian
      can [:create, :read, :update], :source
      can [:create, :read, :update], Source
      can :manage, AccessControl
      can [:create, :read, :update, :delete], Comment
      can :read, User
    elsif user.has_role? :agency_user
      can [:create, :read, :update, :delete], Comment
      can :read, User
    elsif user.has_role? :public
      cannot :read, User do |u|
        u.id != user.id
      end
      cannot :manage, Comment
    else # guest
      cannot :manage, Comment
      cannot :manage, StudyArea
    end

    can :edit, User do |u|
      u.id == user.id
    end

  end
end
