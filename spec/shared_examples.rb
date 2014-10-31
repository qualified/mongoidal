class RootExample
  include Mongoidal::RootDocument

  field :name
end

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
  include Mongoidal::EmbeddedDocument
  embedded_in :revisable_example
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
      esnure
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