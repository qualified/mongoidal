class RevisableExample
  include Mongoidal::RootDocument
  include Mongoidal::Revisable

  embeds_many :revisable_embedded_examples
  embedded_revisable :revisable_embedded_examples, :name

  field :age
  revisable :age

  field :name
  revisable :name
end

class RevisableEmbeddedExample
  include Mongoid::Document
  field :name
end

class User
  include Mongoid::Document

  def self.current
    User.first
  end
end

class Revision
  include Mongoidal::Revision
end