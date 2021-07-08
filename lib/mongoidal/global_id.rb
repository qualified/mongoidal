require 'globalid'

module Mongoidal
  module Identification
    extend ActiveSupport::Concern
    include GlobalID::Identification

    included do
      def to_global_id(options = {})
        parents = Identification.find_global_id_parents(self)
        root = parents.pop
        if root
          # use the root to call the initial find
          options[:root] = "#{root.class.name}/#{root.id}"
          # the paths are used to traverse n number of child relations before reaching the final nest level
          if parents.any?
            options[:paths] = parents.reverse!.map do |value|
              "#{value.class.name}/#{value.id.to_s}"
            end
          end
        end

        # if the document is destroyed then save the attributes so that we can reconstruct the object later
        options[:attributes] = self.attributes.to_json if self.destroyed?
        GlobalID.create(self, options)
      end
    end

    protected

    def self.find_global_id_parents(child, result = [])
      relation = child.class.relations.find {|k, r| r.is_a?(Mongoid::Association::Referenced::EmbeddedIn)}

      if relation
        relation = relation.last
        value = child.send(relation.name)
        result << value
        find_global_id_parents(value, result)
      else
        result
      end
    end
  end

  class Locator
    def initialize(gid)
      @gid = gid
    end

    def locate
      if root
        target = root_class.find(root_parts.last)
        paths << "#{@gid.model_name}/#{@gid.model_id}" unless attributes
        paths.each do |path|
          parts = path.split('/')
          target = find_child(target, parts.first, parts.last)
          return target if target.nil?
        end

        if target and attributes
          build_destroyed(target)
        else
          target
        end
      elsif attributes
        build_destroyed
      else
        @gid.model_class.find(@gid.model_id)
      end
    end

    def find_child(parent, class_name, id)
      parent.relations.each do |k, relation|
        if relation.class_name == class_name
          found = parent.send(relation.name).where(id: id).first
          return found if found
        end
      end
    end

    def attributes
      @attributes ||= @gid.params['attributes'] if @gid.params
    end

    def root
      @root ||= @gid.params['root'] if @gid.params
    end

    def root_parts
      @root_parts ||= root.split('/') if root
    end

    def root_class
      @root_class ||= Object.const_get(root_parts.first) if root_parts
    end

    def paths
      # returns the paths, with the target model added, unless there are attributes provided, in which
      # case we need to build the final model from scratch
      @paths ||= [*@gid.params['paths']]
    end

    def build_destroyed(parent = nil)
      @gid.model_class.new.tap do |doc|
        doc.attributes = JSON.load(attributes)

        # rebuild the parent relationship if one is available
        if parent
          doc.class.relations.each do |k, relation|
            if relation.is_a?(Mongoid::Association::Referenced::EmbeddedIn)
              doc.send("#{relation.name}=", parent)
              break
            end
          end
        end

        # mark the doc as being destroyed
        def doc.destroyed?
          true
        end
      end
    end
  end
end