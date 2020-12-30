module Mongoidal
  # Same as Revisable, except that the revisions are stored external to the document, within
  # their own root collection
  module ExternalRevisable
    extend ActiveSupport::Concern
    include RevisableBase
    included do
      has_many :revisions, as: :revisable, dependent: :destroy, validate: false, class_name: 'ExternalRevision' do
        def find_by_number(number)
          where(number: number).first
        end

        def users
          to_a.map(&:user).uniq
        end

        def revised_by(user)
          where(user_id: user.is_a?(Mongoid::Document) ? user.id : user)
        end
      end

      accepts_nested_attributes_for :revisions
    end

    protected

    def revision_prepared_for_revise(revision)
      revision&.save!
    end
  end
end