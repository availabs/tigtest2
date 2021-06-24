NymtcGateway::Application.configure do
  config.version = ENV['GATEWAY_VERSION'] || '1.0.0'

  config.preview_comments_count = 5;
  config.preview_comment_text_length = 50;

  config.data_models = ['demographic_fact',
                        'rtp_project',
                        'tip_project',
                        'bpm_summary_fact',
                        'comparative_fact',
                        'speed_fact',
                        'count_fact',
                        'upwp_project',
                        'upwp_related_contract',
                        'link_speed_fact',
                        'performance_measures_fact'
                       ]
end

# Patch for /gems/partitioned-1.3.4/lib/monkey_patch_activerecord.rb
# IdentityMap removed from AR 4, remove references
# connection moved to self.class
ActiveRecord::Persistence.module_eval do
  def destroy
    destroy_associations
    
    if persisted?
      pk         = self.class.primary_key
      column     = self.class.columns_hash[pk]
      substitute = self.class.connection.substitute_at(column, 0)
      
      if self.class.respond_to?(:dynamic_arel_table)
        using_arel_table = dynamic_arel_table()
        relation = ActiveRecord::Relation.new(self.class, using_arel_table).
                   where(using_arel_table[pk].eq(substitute))
      else
        using_arel_table = self.class.arel_table
        relation = self.class.unscoped.where(using_arel_table[pk].eq(substitute))
      end
      
      relation.bind_values = [[column, id]]
      relation.delete_all
    end
    
    @destroyed = true
    freeze
  end

  #
  # patch the create method to prefetch the primary key if needed
  #
  def create
    if self.id.nil? && self.class.respond_to?(:prefetch_primary_key?) && self.class.prefetch_primary_key?
      self.id = connection.next_sequence_value(self.class.sequence_name)
    end

    attributes_values = arel_attributes_values(!id.nil?)

    new_id = self.class.unscoped.insert attributes_values

    self.id ||= new_id

    @new_record = false
    id
  end

end
