require 'spec_helper'

describe PlanPortion, :type => :model do

  it "should support NamedValue and DisplayName methods" do
    pp = PlanPortion.find_or_create_by( name: 'test' )

    expect(pp.to_s).to eq('test')

    expect(PlanPortion['test']).to eq(pp.id)
    expect(PlanPortion[pp.id]).to eq('test')
  end
  
end
