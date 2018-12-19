require "zlib"

module Mongoidal
  module Revision
    extend ActiveSupport::Concern

    included do
      include Mongoid::Document

      unless relations['revisable']
        embedded_in :revisable,   polymorphic: true
      end

      field :created_at,          type: Time

      field :number,              type: Integer
      validates_presence_of :number
      validates_uniqueness_of :number

      field :tag,                 type: String
      field :type,                type: Symbol, default: :change

      field :message,             type: String

      # compressed version of revised attributes
      field :revised_attributes_c,type: BSON::Binary
      field :revised_embeds,      type: Hash, default: ->{{}}
      field :event_data,          type: Hash

      field :revised_keys,        type: Array

      before_save :set_compressed

      def set_compressed
        self.revised_keys = revised_attributes.keys
        compressed = Zlib::Deflate.deflate(JSON.dump(revised_attributes))
        self.revised_attributes_c = BSON::Binary.new(compressed)
        self[:revised_attributes] = nil if self[:revised_attributes]
      end

      def revised_attributes
        @revised_attributes ||= begin
          attr = self[:revised_attributes_c]
          if attr.present?
            JSON.parse(Zlib::Inflate.inflate(attr.data))
          else
            self[:revised_attributes] || {}
          end
        end
      end

      def revised_attributes=(val)
        @revised_attributes = val || {}
      end
    end

    def base_revision?
      number == 0
    end

    def previous_revision
      if base_revision?
        nil
      else
        revisable.revisions[revisable.revisions.index(self) - 1]
      end
    end

    def next_revision
      if number == revisable.last_revision_number
        nil
      else
        revisable.revisions[revisable.revisions.index(self) + 1]
      end
    end

    def restore!
      if revisable.last_revision_number != number
        revisable.revisions.where(:number.gt => number).destroy

        revised_attributes.each do |key, value|
          revisable.__send__("#{key}=", value)
        end

        revisable.respond_to?(:store!) ? revisable.store! : revisable.save!
      end
    end

    def revised_embeds?
      revised_embeds.any? do |key, value|
        value.any?
      end
    end

    def revised_embeds_info
      @revised_embeds_info ||= revised_embeds.map_as_hash do |collection, items|
        [collection, items.map do |id, data|
          RevisedEmbedInfo.new(self, collection, id, data)
        end]
      end
    end

    def revised_fields_info
      @revised_field_info ||= revised_attributes.map_as_hash do |field, value|
        [field, RevisedFieldInfo.new(self, revisable, field)]
      end
    end

    class RevisedFieldInfo
      attr_reader :revision, :field, :embed_collection, :embed_id, :value

      def initialize(revision, document, field, embed_collection = nil, embed_id = nil)
        @revision = revision
        @document = document
        @field = field

        @embed_collection = embed_collection
        @embed_id = embed_id
      end

      def document
        @document ||= if @embed_id
          revision.revisable.send(@embed_collection).find(@embed_id)
        else
          revision.revisable
        end
      end

      def previous_item
        @field_info ||= begin
          history = @embed_collection ?
              revision.revisable.embedded_field_revision_history(@embed_collection, @embed_id, field) :
              revision.revisable.field_revision_history(field)

          index = history.index {|item| item.revision == revision}
          if index > 0
            history[index-1]
          else
            nil
          end
        end
      end

      def previous_value
        @previous_value ||= begin
          v = revision.number == 0 ? nil : previous_item.try(:value)
          v == value ? nil : v
        end
      end

      def value
        @value ||= if @embed_id
          @value = revision.revised_embeds[embed_collection][embed_id][field]
        else
          @value = revision.revised_attributes[field]
        end
      end

      def diff
        @diff ||= Differ.new(previous_value, value)
      end

      def field_type
        document.class.fields[field].type
      end

    end

    class RevisedEmbedInfo
      attr_reader :revision, :collection, :data, :document_id

      def initialize(revision, collection, id, data)
        @revision = revision
        @collection = collection
        @document_id = id
        @data = data
      end

      def fields
        @fields ||= data.keys
      end

      def document
        @document ||= revision.revisable.__send__(collection).where(id: document_id).first
      end

      def document_name
        @document_name ||= if document
          if document.respond_to? :logger_name
            document.logger_name
          elsif document.respond_to? :name
            document.name
          end
        end
      end

      def fields_info
        @fields_info ||= data.map_as_hash do |field, value|
          [field, RevisedFieldInfo.new(revision, document, field, collection, document_id)]
        end
      end
    end

  end

end