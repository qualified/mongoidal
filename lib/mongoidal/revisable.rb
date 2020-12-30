module Mongoidal
  module Revisable
    extend ActiveSupport::Concern
    include RevisableBase

    included do
      embeds_many :revisions, as: :revisable, validate: false, class_name: 'Revision' do
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
  end
end