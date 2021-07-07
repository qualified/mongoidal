require 'mongoid'
require "mongoidal/version"
require 'mongoidal/string_extensions'
require 'mongoidal/class_logger'
require "mongoidal/field_callbacks"
require 'mongoidal/instance_callbacks'
require "mongoidal/global_id"
require "mongoidal/helpers"
require "mongoidal/translations"
require "mongoidal/sym_array"
require 'mongoidal/slug_field'
require 'mongoidal/tag_field'
require 'mongoidal/enum_field'
require 'mongoidal/extended_fields'
require 'mongoidal/root_document'
require 'mongoidal/embedded_document'
require 'mongoidal/copyable'
require 'mongoidal/revisable_base'
require 'mongoidal/revisable'
require 'mongoidal/external_revisable'
require 'mongoidal/revision'
require 'mongoidal/bulk_savable'
require 'mongoidal/nesting'
require 'mongoidal/embedded_errors'
# for now we are going to require manually
# require 'mongoidal/identification'

module Mongoidal
  # Your code goes here...
end

# fix mongoid 3 serialization
module BSON
  class ObjectId
    def as_json(*args)
      to_s
    end
  end
end
