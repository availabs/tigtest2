# patch for /gems/partitioned-1.3.4/lib/partitioned/multi_level/configurator/reader.rb
# in some cases ancestor::configurator_dsl did not exist so use try instead.
module Partitioned
  class MultiLevel
    module Configurator
      # coalesces and parses all {Data} objects allowing the
      # {PartitionManager} to request partitioning information froma
      # centralized source from multi level partitioned models
      class Reader < Partitioned::PartitionedBase::Configurator::Reader

        def using_configurators
          unless @using_configurators
            @using_configurators = []
            using_classes.each do |using_class|
              using_class.ancestors.each do |ancestor|
                next if ancestor.class == Module
                @using_configurators << UsingConfigurator.new(using_class, ancestor, ancestor::configurator_dsl) if ancestor.try(:configurator_dsl) 
                break if ancestor == Partitioned::PartitionedBase
              end
            end
          end
          return @using_configurators
        end
      end
    end
  end
end
