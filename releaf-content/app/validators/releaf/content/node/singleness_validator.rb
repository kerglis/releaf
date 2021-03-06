module Releaf
  module Content::Node
    # Validator to test if node is valid, when created under given parrent node
    #
    # validator needs :for and :under options, both can be either array of classes
    # or single class.
    #
    # :for option specifies for which nodes validation should be applied
    #
    # :under option specifies under which nodes only single node of given type
    # should be valid.
    # If under is unspecified, then only single node with given class can be
    # created under entrie content tree.
    #
    # @example
    #
    #   class Node < ActiveRecord::Base
    #     includes Releaf::Content::Node
    #     validates_with Releaf::Content::Node::ParentValidator, for: [Text, Book], under: Store
    #   end
    #
    # In the example above, Text node or book node can be added in any leve
    # under Store node, but only once.
    # However they can be added to any other node as many times as needed, as
    # long as none of ancestors are Store node.
    class SinglenessValidator < ActiveModel::Validator

      def validate node
        @node = node
        node.errors.add(:content_type, 'node exists') unless node_valid?
        remove_instance_variable(:@node)
      end

      private

      def node_valid?
        return true unless child_class_names.include? @node.content_type

        relation = base_relation_for_validation
        # if relation is nil, then node is under ancestor for which this validation
        # shouldn't be appied
        return true if relation.nil?

        unless @node.new_record?
          relation = relation.where('id <> ?', @node.id)
        end

        relation.any? == false
      end

      def base_relation_for_validation
        if ancestor_classes.blank?
          return base_relation_for_entire_tree
        else
          return base_relation_for_subtree
        end
      end

      def base_relation_for_entire_tree
        @node.class.unscoped.where(content_type: @node.content_type)
      end

      def base_relation_for_subtree
        return nil if @node.parent.nil?

        # need to find parent node again, because Node.roots[n].ancestors can
        # return some other parent, than @node.parent.ancestors, even though
        # both return same node.
        # Seams like a bug in AwesomeNestedSet (in case of @node.parent.ancestors).
        parent_node = Node.find(@node.parent_id)

        ancestor_node = parent_node.self_and_ancestors.where(content_type: ancestor_class_names).reorder(:depth).last
        if ancestor_node.nil?
          return nil
        else
          return ancestor_node.descendants.where(content_type: @node.content_type)
        end
      end

      def child_class_names
        target_class_names :for
      end

      def ancestor_class_names
        target_class_names :under
      end

      def ancestor_classes
        target_classes :under
      end

      def target_classes target_type
        [options.fetch(target_type, [])].flatten
      end

      def target_class_names target_type
        target_classes(target_type).map(&:name)
      end

    end
  end
end
