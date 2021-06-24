require 'spec_helper'

describe View, :type => :model do
  
  before(:all) do
  end

  before(:each) do
    Action.find_or_create_by( name: 'action1' )
    Action.find_or_create_by( name: 'action2' )
    Action.find_or_create_by( name: 'view_metadata' )
    Action.find_or_create_by( name: 'edit_metadata' )
    @view = View.create(name: "view", data_model: CountFact)
  end

  describe "actions" do

    it "should have an actions attribute" do
      expect(@view).to respond_to(:actions)
    end

    it "should accept a valid action" do
      action = Action.all_names[1]
      @view.add_action action
      expect(@view).to have_action action
      expect(@view.actions[0]).to eq(action)
    end

    it "should reject an invalid action" do
      expect {
        @view.add_action :foo
        }.to raise_error(ArgumentError)
    end

    it "should list assigned actions" do
      allActions = Action.all_names
      expect(allActions.length).to eq(4)

      @view.add_action allActions[0]
      @view.add_action allActions[1]

      expect(@view.actions.length).to eq(2)
      expect(allActions).to include(@view.actions[0])
      expect(allActions).to include(@view.actions[1])
    end

    it "should filter out edit and view metadata actions" do
      allActions = Action.all_actions_filtered
      expect(allActions.length).to eq(2)

      allActionsNames = allActions.collect(&:name)

      expect(allActionsNames).not_to include('edit_metadata')
      expect(allActionsNames).not_to include('view_metadata')
    end
  end

  describe "columns" do

    it "should have a columns attribute" do
      expect(@view).to respond_to(:columns)
    end

    it "should return an initial empty array" do
      expect(@view.columns).to be_empty
    end

    it "should save and restore list of columns" do
      columns = ['foo', 'bar']
      @view.columns = columns
      expect(@view.columns).to eq(columns)
      @view.save

      @view = View.find_by_name "view"
      expect(@view.columns).to eq(columns)
    end
  end

  describe "column_types" do

    it "should have a column_types attribute" do
      expect(@view).to respond_to(:column_types)
    end

    it "should return an initial empty array" do
      expect(@view.column_types).to be_empty
    end

    it "should save and restore list of column_types" do
      column_types = ['', 'numeric']
      @view.column_types = column_types
      expect(@view.column_types).to eq(column_types)
      @view.save

      @view = View.find_by_name "view"
      expect(@view.column_types).to eq(column_types)
    end
  end

  describe "data_levels" do

    it "should have a data_levels attribute" do
      expect(@view).to respond_to(:data_levels)
    end

    it "should return an initial array of empty levels" do
      expect(@view.data_levels).to eq(["", ""])
    end

    it "should save and restore list of data_levels" do
      data_levels = ['County', 'TAZ']
      @view.data_levels = data_levels
      expect(@view.data_levels).to eq(data_levels)
      @view.save

      @view = View.find_by_name "view"
      expect(@view.data_levels).to eq(data_levels)
    end
  end

  describe "value_name" do
    it "should have a value_name attribute" do
      expect(@view).to respond_to(:value_name)
    end

    it "should return :value as default" do
      expect(@view.value_name).to eq(:value)
    end

    it "should save and restore :value_name" do
      @view.value_name = :density
      @view.save

      @view = View.find_by_name "view"
      expect(@view.value_name).to eq(:density)
    end
    
  end
  
  describe "data_model" do

    before(:all) do
      Temping.create :testFact do
        with_columns do |t|
          t.string :foo
          t.integer :bar
        end
        attr_accessible :foo, :bar
      end

      TestFact.create([ { foo: 'First', bar: 1 },
                        { foo: 'Second', bar: 2 }
                      ] )
    end
    
    before(:each) do
      @view.data_model = TestFact
      @view.save if @view.changed?
    end
    
    it "should have a data_model attribute" do
      expect(@view).to respond_to(:data_model)
    end

    it "should save and restore a data_model" do
      @view = View.find_by_name "view"
      expect(@view.data_model).to eq(TestFact)
    end

    it "should allow iteration over data in the model" do
      @view = View.find_by_name "view"
      @view.data_model.all.count == 2
      rows = @view.data_model.all
      expect(rows[0][:foo]).to eq('First')
      expect(rows[0][:bar]).to eq(1)
      expect(rows[1][:foo]).to eq('Second')
      expect(rows[1][:bar]).to eq(2)
        
    end
  end
end
