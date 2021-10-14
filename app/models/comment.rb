class Comment < ActiveRecord::Base
  belongs_to :user
  belongs_to :source
  belongs_to :view

  validates :user, presence: true
  validates :subject, presence: true
  validates :source, presence: true
  validates :view, presence: true, unless: -> { app.nil? }

  # enum app: [ :table, :map, :chart, :metadata ]

  scope :first_n, ->(n) { order("created_at desc").limit(n)}
  scope :query_by, ->(source, view, app) { 
    return where(source: nil, view: nil, app: nil) if source.nil? && view.nil? && app.nil?
    
    query_hash = Hash.new
    query_hash["source"] = source if source
    query_hash["view"] = view if view
    query_hash["app"] = Comment.apps[app] if app

    where(query_hash)
  }

  def self.is_commentable?(source, view, app)
    if !source && !view
      false 
    elsif app && !view
      false
    elsif app && !Comment.apps[app]
      false
    else 
      true
    end
  end

  def user
    super || User.default if user_id
  end
end
