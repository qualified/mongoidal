require 'spec_helper'

class TagExample
  include Mongoid::Document
  include Mongoidal::TagField
  tag_field :tags
  tag_field :skills, downcase: true
  tag_field :syms, type: Mongoid::StringifiedSymbol
end

describe Mongoidal::TagField do
  let(:model) { TagExample.new }
  let(:existing_model) { TagExample.create! tags: 'a,b,c,d', syms: [:a, :b]}

  it "should downcase all values when option is set" do
    text = "A, b, c"
    model.tags = text
    expect(model.tags_text).to eq text

    model.skills = text
    expect(model.skills_text).to eq "a, b, c"
  end


  it "should show as changed when field is modified" do
    expect(model).not_to be_tags_changed
    model.tags = "a,b, c"
    expect(model).to be_tags_changed
  end

  it "should convert string tags into an array when being set" do
    model.tags = "a,b, c"
    expect(model.tags.first).to eq "a"
    expect(model.tags.last).to eq "c"
  end

  it "should remove duplicate values from an array when being set" do
    model.tags = "a,b,c,b,a,a"
    expect(model.tags.size).to eq 3
  end

  it "should implement #add_tags method" do
    existing_model.tags = "a,b,c"
    existing_model.add_tags("c,d")
    expect(existing_model.tags.size).to eq 4
    expect(existing_model.tags.last).to eq 'd'
  end

  it "should implement #tags_added method" do
    existing_model.tags = "a,c,e"
    expect(existing_model.tags_added.first).to eq "e"
  end

  it "should implement #tags_removed method" do
    existing_model.tags = "a,c,e"
    expect(existing_model.tags_removed.first).to eq "b"
  end

  it "should implement tags scope" do
    existing_model
    expect(TagExample.any_in(tags: ['a']).count).to be > 0
    expect(TagExample.any_tags("a, z").count).to be > 0

    expect(TagExample.all_tags("a, z").count).to eq 0
    expect(TagExample.all_tags("a, b").count).to be > 0
    expect(TagExample.all_tags(["a", "b"]).count).to be > 0
  end


  describe "should support special symbol array type" do
    it "should store values as symbols within an array" do
      expect(existing_model.syms.include?(:a)).to eq true
    end

    it "should still support returning the values as a commas separated string" do
      expect(existing_model.syms_text).to eq "a, b"
    end
  end
end

