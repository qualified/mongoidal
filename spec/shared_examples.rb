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

class ExternalRevisableExample
  include Mongoidal::RootDocument
  include Mongoidal::ExternalRevisable

  embeds_many :revisable_embedded_examples
  embedded_revisable :revisable_embedded_examples, :name

  field :age
  revisable :age

  field :name
  revisable :name
end

class RevisableEmbeddedExample
  include Mongoidal::EmbeddedDocument
  embedded_in :revisable_example, polymorphic: true
  field :name
end

class User
  include Mongoidal::RootDocument

  class << self
    attr_accessor :current
  end

  def make_current
    if block_given?
      orig = User.current
      begin
        User.current = self
        yield
      ensure
        User.current = orig
      end
    else
      User.current = self
    end
  end
end

class Revision
  include Mongoidal::Revision
end

class ExternalRevision
  include Mongoidal::RootDocument
  belongs_to :revisable,     polymorphic: true
  include Mongoidal::Revision
end