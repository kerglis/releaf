require "spec_helper"

describe Node do

  let(:node) { Node.new }

  it { should accept_nested_attributes_for(:content) }
  it { should belong_to(:content) }

  it "includes Releaf::ContentNode module" do
    expect( Node.included_modules ).to include Releaf::ContentNode
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:slug) }
    it { should validate_presence_of(:content_type) }
    it { should validate_uniqueness_of(:slug).scoped_to(:parent_id) }
    it { should ensure_length_of(:name).is_at_most(255) }
    it { should ensure_length_of(:slug).is_at_most(255) }
  end

  describe "after save" do
    it "sets node update to current time" do
      Settings['nodes.updated_at'] = Time.now
      time_now = Time.parse("2009-02-23 21:00:00 UTC")
      Time.stub(:now).and_return(time_now)

      expect{ FactoryGirl.create(:node) }.to change{ Settings['nodes.updated_at'] }.to(time_now)
    end
  end

  describe "#own_fields_to_display" do
    it "returns blank array" do
      expect( node.own_fields_to_display ).to eq []
    end
  end

  describe "#content_fields_to_display" do
    context "when #content_type is name of non ActiveRecord class" do
      it "returns nil" do
        node.content_type = 'TrueClass'
        expect( node.content_fields_to_display('edit') ).to be_nil
      end
    end

    context "when #content_type is name of ActionController class" do
      it "returns nil" do
        node.content_type = 'TextsController'
        expect( node.content_fields_to_display('edit') ).to be_nil
      end
    end

    context "when #content_type is name of ActiveRecord model that acts as node" do
      it "display all but #id, #updated_at and #created_at fields" do
        node.content_type = 'Book'
        expect( node.content_fields_to_display('edit') ).to match_array(Book.column_names - %w[id created_at updated_at])
      end
    end

  end

  describe "#content_class" do
    context 'when #content_type is nil' do
      it 'returns nil' do
        subject.content_type = nil
        expect( subject.content_class ).to be_nil
      end
    end

    context "when #content_type is blank string" do
      it 'returns nil' do
        subject.content_type = ""
        expect( subject.content_class ).to be_nil
      end
    end

    context "when #content_type is not blank" do
      it "constantizes it" do
        subject.content_type = "Node"
        expect( subject.content_class ).to eq Node
      end
    end
  end

  describe "#to_s" do
    it "returns name" do
      expect(node.to_s).to eq(node.name)
    end
  end

  describe "#locale" do
    before do
      root = FactoryGirl.create(:node, locale: "lv")
      parent = FactoryGirl.create(:node, locale: nil, parent_id: root.id)
      @child1 = FactoryGirl.create(:node, locale: nil, parent_id: parent.id)
      @child2 = FactoryGirl.create(:node, locale: nil, parent_id: parent.id, locale: "en")
    end

    context "when node locale is nil" do
      it "uses closest parent locale" do
        expect(@child1.locale).to eq("lv")
      end
    end

    context "when object node have locale" do
      it "uses closest parent locale" do
        expect(@child2.locale).to eq("en")
      end
    end
  end

  describe "#destroy" do
    def stub_content_class &block
      Node.any_instance.stub(:content_class)
      yield
      Node.any_instance.unstub(:content_class)
    end

    context "when content object class exists" do
      let(:text) { FactoryGirl.create(:text) }
      let!(:node) { FactoryGirl.create(:node, content: text) }

      it "deletes record" do
        expect { node.destroy }.to change { Node.count }.by(-1)
      end

      it "deletes associated record" do
        expect { node.destroy }.to change { Text.count }.by(-1)
      end
    end

    context "when content object class doesn't exists" do
      it "deletes record" do
        stub_content_class do
          @node = FactoryGirl.create(:node, content_type: 'NonExistingTestModel', content_id: 1)
        end
        expect { @node.destroy }.to change { Node.count }.by(-1)
      end

      it "retries to delete record only once" do
        stub_content_class do
          @node = FactoryGirl.create(:node, content_type: 'NonExistingTestModel', content_id: 1)
        end
        @node.stub(:content_type=)
        @node.stub(:content_id=)

        expect { @node.destroy }.to raise_error NameError
        expect( Node.count ).to eq 1
      end
    end

    it "sets node update to current time" do
      node = FactoryGirl.create(:node)
      time_now = Time.parse("2009-02-23 21:00:00 UTC")
      Time.stub(:now).and_return(time_now)
      expect{ node.destroy }.to change{ Settings['nodes.updated_at'] }.to(time_now)
    end
  end

  describe "#copy_to_node!" do
    before do
      @text_node = FactoryGirl.create(:text_node)
      @text_node_2 = FactoryGirl.create(:text_node)
      @text_node_3 = FactoryGirl.create(:text_node, parent_id: @text_node.id )
    end

    context "with corect parent_id" do
      it "creates new node" do
        expect{ @text_node_2.copy_to_node!(@text_node.id) }.to change{ Node.count }.by(1)
      end
    end

    context "when node have children" do
      it "creates multiple new nodes" do
        @text_node_2.copy_to_node!(@text_node.id)
        expect{ @text_node.copy_to_node!(@text_node_2.id) }.to change{ Node.count }.by( @text_node.children.size + 1 )
      end
    end

    context "when parent_id is nil" do
      it "creates new node" do
        expect{ @text_node_3.copy_to_node!(nil) }.to change{ Node.count }.by(1)
      end
    end

    context "with nonexistent parent_id" do
      it "raises ActiveRecord::RecordInvalid" do
        expect { @text_node_2.copy_to_node!(99991) }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context "with same parent_id as node.id" do
      it "raises ActiveRecord::RecordInvalid" do
        expect{ @text_node.copy_to_node!(@text_node.id) }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context "when passing string as argument" do
      it "raises ActiveRecord::RecordInvalid" do
        expect{ @text_node.copy_to_node!("some_id") }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end

  describe "#move_to_node!" do
    before do
      @text_node = FactoryGirl.create(:text_node)
      @text_node_2 = FactoryGirl.create(:text_node)
      @text_node_3 = FactoryGirl.create(:text_node, parent_id: @text_node_2.id)
    end

    context "when moving existing node to other nodes child's position" do
      it "changes parent_id" do
        expect{ @text_node_3.move_to_node!(@text_node.id) }.to change{ Node.find_by_id(@text_node_3.id).parent_id }.from(@text_node_2.id).to(@text_node.id)
      end
    end

    context "when moving to self child's position" do
      it "raises ActiveRecord::RecordInvalid" do
        expect{ @text_node_3.move_to_node!(@text_node_3.id) }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context "when passing nil as target node" do
      it "doesn't change parent_id" do
        expect{ @text_node_3.move_to_node!(nil) }.to change{ Node.find_by_id(@text_node_3.id).parent_id }
      end
    end

    context "when passing nonexistent target node's id" do
      it "raises ActiveRecord::RecordInvalid" do
        expect{ @text_node_3.move_to_node!(998123) }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context "when passing string as argument" do
      it "raises ActiveRecord::RecordInvalid" do
        expect{ @text_node_3.move_to_node!("test") }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end

  describe "#maintain_name" do
    let(:root) { FactoryGirl.create(:text_node) }
    let(:node) { FactoryGirl.create(:text_node, parent_id: root.id, name:  "Test node") }
    let(:sibling) { FactoryGirl.create(:text_node, parent_id: root.id, name:  "Test node(1)") }

    context "when node don't have sibling/s with same name" do
      it "does not changes node's name" do
        new_node = Node.new(name:  "another name", parent_id: root.id)
        expect{ new_node.maintain_name }.to_not change{new_node.name}
      end
    end

    context "when node have sibling/s with same name" do
      it "changes node's name" do
        new_node = Node.new(name:  node.name, parent_id: root.id)
        expect{ new_node.maintain_name }.to change{new_node.name}.from(node.name).to("#{node.name}(1)")
      end

      it "increments node's name number" do
        sibling
        new_node = Node.new(name:  node.name, parent_id: root.id)
        expect{ new_node.maintain_name }.to change{new_node.name}.from(node.name).to("#{node.name}(2)")
      end
    end
  end

  describe ".updated_at" do
    it "returns last node update time" do
      expect( Settings ).to receive(:[]).with('nodes.updated_at').and_return('test')
      expect( Node.updated_at ).to eq 'test'
    end
  end

  describe "#available?" do
    let(:root) { FactoryGirl.create(:text_node, active: true) }
    let(:node_ancestor) { FactoryGirl.create(:text_node, parent_id: root.id, active: true) }
    let(:node) { FactoryGirl.create(:text_node, parent_id: node_ancestor.id, active: true) }

    context "when object and all its ancestors are active" do
      it "returns true" do
        expect( node ).to be_available
      end
    end

    context "when object itself is not active" do
      it "returns false" do
        node.update_attribute(:active, false)
        expect( node ).to_not be_available
      end
    end

    context "when any of object ancestors are not active" do
      it "returns false" do
        node_ancestor.update_attribute(:active, false)
        expect( node ).to_not be_available
      end
    end
  end

  describe ".valid_node_content_classes" do
    it "returns array of constantized .valid_node_content_class_names" do
      expect( Node ).to receive(:valid_node_content_class_names).with(42).and_return(['Text', 'HomeController'])
      expect( Node.valid_node_content_classes(42) ).to eq [Text, HomeController]
    end
  end

  describe ".valid_node_content_class_names" do
    it "returns class names for Node#content_type that can be used to create valid node" do
      expect( ActsAsNode ).to receive(:classes).and_return(%w[BadNode GoodNode])

      node1 = double('BadNode')
      node1.stub(:valid?)
      node1.stub_chain(:errors, :[]).with(:content_type).and_return(['some error'])

      node2 = double('GoodNode')
      node2.stub(:valid?)
      node2.stub_chain(:errors, :[]).with(:content_type).and_return(nil)

      expect( Node ).to receive(:new).with(hash_including(parent_id: 52, content_type: 'BadNode')).and_return(node1)
      expect( Node ).to receive(:new).with(hash_including(parent_id: 52, content_type: 'GoodNode')).and_return(node2)

      expect( Node.valid_node_content_class_names(52) ).to eq %w[GoodNode]
    end

  end

end
