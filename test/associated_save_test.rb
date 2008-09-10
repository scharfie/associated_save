require File.dirname(__FILE__) + '/abstract_unit'

class Collection < ActiveRecord::Base
  has_many :items
  associated_save :items
end

class Item < ActiveRecord::Base
  belongs_to :collection
end

class AssociatedSaveTest < Test::Unit::TestCase
  def setup
    @library = Collection.create(:name => 'Book Library')
  end
  
  def test_reflection
    reflection = Collection.reflect_on_associated_save(:items)
    assert_equal '_items', reflection[:from]
    assert_equal 'save_associated_items', reflection[:callback]
  end
end
