require 'test_helper'



# CLASS SETUP

class ListMixin
  include MongoMapper::Document

  plugin MongoMapper::Plugins::ActsAsList

  key :pos, Integer
  key :parent_id, Integer
  key :original_id, Integer

  acts_as_list :column => :pos, :scope => :parent_id
end

class ListMixinSub1 < ListMixin
end

class ListMixinSub2 < ListMixin
end

class ListMixinWithArrayScope
  include MongoMapper::Document

  plugin MongoMapper::Plugins::ActsAsList

  key :pos, Integer
  key :parent_id, Integer

  acts_as_list :column => :pos, :scope => [:parent_id, :original_id]
end



# TESTS

class ScopeTest < ActiveSupport::TestCase

  def setup
    @lm1 = ListMixin.create! :pos => 1, :parent_id => 5, :original_id => 1
    @lm2 = ListMixinWithArrayScope.create! :pos => 1, :parent_id => 5, :original_id => 1
  end

  def test_symbol_scope
    assert_equal @lm1.scope_condition, { :parent_id => 5 }
    assert_equal @lm2.scope_condition, { :parent_id => 5, :original_id => 1 }
  end

end



class ActiveSupport::TestCase
	
	private
	
	def mixins_with_parent_id(parent_id)
		ListMixin.where(:parent_id => parent_id).sort(:pos).all.map(&:original_id)
	end
	
	def mixin_with_original_id(original_id)
		ListMixin.where(:original_id => original_id).first
	end
end



class ListTest < ActiveSupport::TestCase

    def setup
      (1..4).each{ |counter| ListMixin.create! :pos => counter, :parent_id => 5, :original_id => counter }
    end

    def test_reordering
      assert_equal [1, 2, 3, 4], mixins_with_parent_id(5)

      mixin_with_original_id(2).move_lower
      assert_equal [1, 3, 2, 4], mixins_with_parent_id(5)

      mixin_with_original_id(2).move_higher
      assert_equal [1, 2, 3, 4], mixins_with_parent_id(5)

      mixin_with_original_id(1).move_to_bottom
      assert_equal [2, 3, 4, 1], mixins_with_parent_id(5)

      mixin_with_original_id(1).move_to_top
      assert_equal [1, 2, 3, 4], mixins_with_parent_id(5)

      mixin_with_original_id(2).move_to_bottom
      assert_equal [1, 3, 4, 2], mixins_with_parent_id(5)

      mixin_with_original_id(4).move_to_top
      assert_equal [4, 1, 3, 2], mixins_with_parent_id(5)
    end

    def test_move_to_bottom_with_next_to_last_item
      assert_equal [1, 2, 3, 4], mixins_with_parent_id(5)
      mixin_with_original_id(3).move_to_bottom
      assert_equal [1, 2, 4, 3], mixins_with_parent_id(5)
    end

    def test_next_prev
      assert_equal mixin_with_original_id(2), mixin_with_original_id(1).lower_item
      assert_nil mixin_with_original_id(1).higher_item
      assert_equal mixin_with_original_id(3), mixin_with_original_id(4).higher_item
      assert_nil mixin_with_original_id(4).lower_item
    end

    def test_injection
      item = ListMixin.new(:parent_id => 1)
      assert_equal item.scope_condition, {:parent_id => 1}
      assert_equal "pos", item.position_column
    end

    def test_insert
      new = ListMixin.create(:parent_id => 20)
      assert_equal 1, new.pos
      assert new.first?
      assert new.last?

      new = ListMixin.create(:parent_id => 20)
      assert_equal 2, new.pos
      assert !new.first?
      assert new.last?

      new = ListMixin.create(:parent_id => 20)
      assert_equal 3, new.pos
      assert !new.first?
      assert new.last?

      new = ListMixin.create(:parent_id => 0)
      assert_equal 1, new.pos
      assert new.first?
      assert new.last?
    end

    def test_insert_at
      new = ListMixin.create(:parent_id => 20)
      assert_equal 1, new.pos

      new = ListMixin.create(:parent_id => 20)
      assert_equal 2, new.pos

      new = ListMixin.create(:parent_id => 20)
      assert_equal 3, new.pos

      new4 = ListMixin.create(:parent_id => 20)
      assert_equal 4, new4.pos

      new4.insert_at(3)
      assert_equal 3, new4.pos

      new.reload
      assert_equal 4, new.pos

      new.insert_at(2)
      assert_equal 2, new.pos

      new4.reload
      assert_equal 4, new4.pos

      new5 = ListMixin.create(:parent_id => 20)
      assert_equal 5, new5.pos

      new5.insert_at(1)
      assert_equal 1, new5.pos

      new4.reload
      assert_equal 5, new4.pos
    end

    def test_delete_middle
      assert_equal [1, 2, 3, 4], mixins_with_parent_id(5)

      mixin_with_original_id(2).destroy

      assert_equal [1, 3, 4], mixins_with_parent_id(5)

      assert_equal 1, mixin_with_original_id(1).pos
      assert_equal 2, mixin_with_original_id(3).pos
      assert_equal 3, mixin_with_original_id(4).pos

      mixin_with_original_id(1).destroy

      assert_equal [3, 4], mixins_with_parent_id(5)

      assert_equal 1, mixin_with_original_id(3).pos
      assert_equal 2, mixin_with_original_id(4).pos
    end

    def test_nil_scope
      new1, new2, new3 = ListMixin.create, ListMixin.create, ListMixin.create
      new2.move_higher
      assert_equal [new2, new1, new3], ListMixin.where(:parent_id => nil).sort(:pos).all
    end

    def test_remove_from_list_should_then_fail_in_list? 
      assert_equal true, mixin_with_original_id(1).in_list?
      mixin_with_original_id(1).remove_from_list
      assert_equal false, mixin_with_original_id(1).in_list?
    end 

    def test_remove_from_list_should_set_position_to_nil 
      assert_equal [1, 2, 3, 4], mixins_with_parent_id(5)

      mixin_with_original_id(2).remove_from_list 

      assert_equal [2, 1, 3, 4], mixins_with_parent_id(5)

      assert_equal 1,   mixin_with_original_id(1).pos
      assert_equal nil, mixin_with_original_id(2).pos
      assert_equal 2,   mixin_with_original_id(3).pos
      assert_equal 3,   mixin_with_original_id(4).pos
    end 

    def test_remove_before_destroy_does_not_shift_lower_items_twice 
      assert_equal [1, 2, 3, 4], mixins_with_parent_id(5)

      mixin_with_original_id(2).remove_from_list 
      mixin_with_original_id(2).destroy 

      assert_equal [1, 3, 4], mixins_with_parent_id(5)

      assert_equal 1, mixin_with_original_id(1).pos
      assert_equal 2, mixin_with_original_id(3).pos
      assert_equal 3, mixin_with_original_id(4).pos
    end 
  
end

class ListSubTest < ActiveSupport::TestCase

  def setup
    (1..4).each{ |i| ((i % 2 == 1) ? ListMixinSub1 : ListMixinSub2).create! :pos => i, :parent_id => 5000, :original_id => i }
  end

  def test_reordering
    assert_equal [1, 2, 3, 4], mixins_with_parent_id(5000)

    mixin_with_original_id(2).move_lower
    assert_equal [1, 3, 2, 4], mixins_with_parent_id(5000)
      
    mixin_with_original_id(2).move_higher
    assert_equal [1, 2, 3, 4], mixins_with_parent_id(5000)
      
    mixin_with_original_id(1).move_to_bottom
    assert_equal [2, 3, 4, 1], mixins_with_parent_id(5000)

    mixin_with_original_id(1).move_to_top
    assert_equal [1, 2, 3, 4], mixins_with_parent_id(5000)
      
    mixin_with_original_id(2).move_to_bottom
    assert_equal [1, 3, 4, 2], mixins_with_parent_id(5000)
      
    mixin_with_original_id(4).move_to_top
    assert_equal [4, 1, 3, 2], mixins_with_parent_id(5000)
  end

  def test_move_to_bottom_with_next_to_last_item
    assert_equal [1, 2, 3, 4], mixins_with_parent_id(5000)
    mixin_with_original_id(3).move_to_bottom
    assert_equal [1, 2, 4, 3], mixins_with_parent_id(5000)
  end

  def test_next_prev
    assert_equal mixin_with_original_id(2), mixin_with_original_id(1).lower_item
    assert_nil mixin_with_original_id(1).higher_item
    assert_equal mixin_with_original_id(3), mixin_with_original_id(4).higher_item
    assert_nil mixin_with_original_id(4).lower_item
  end

  def test_injection
    item = ListMixin.new(:parent_id => 1)
    assert_equal item.scope_condition, { :parent_id => 1 }
    assert_equal "pos", item.position_column
  end

  def test_insert_at
    new = ListMixin.create(:parent_id => 20)
    assert_equal 1, new.pos
 
    new = ListMixinSub1.create(:parent_id => 20)
    assert_equal 2, new.pos
 
    new = ListMixinSub2.create(:parent_id => 20)
    assert_equal 3, new.pos
 
    new4 = ListMixin.create(:parent_id => 20)
    assert_equal 4, new4.pos
 
    new4.insert_at(3)
    assert_equal 3, new4.pos
 
    new.reload
    assert_equal 4, new.pos
 
    new.insert_at(2)
    assert_equal 2, new.pos
 
    new4.reload
    assert_equal 4, new4.pos
 
    new5 = ListMixinSub1.create(:parent_id => 20)
    assert_equal 5, new5.pos
 
    new5.insert_at(1)
    assert_equal 1, new5.pos
 
    new4.reload
    assert_equal 5, new4.pos
  end

  def test_delete_middle
    assert_equal [1, 2, 3, 4], mixins_with_parent_id(5000)
 
    mixin_with_original_id(2).destroy
 
    assert_equal [1, 3, 4], mixins_with_parent_id(5000)
 
    assert_equal 1, mixin_with_original_id(1).pos
    assert_equal 2, mixin_with_original_id(3).pos
    assert_equal 3, mixin_with_original_id(4).pos
 
    mixin_with_original_id(1).destroy
 
    assert_equal [3, 4], mixins_with_parent_id(5000)
 
    assert_equal 1, mixin_with_original_id(3).pos
    assert_equal 2, mixin_with_original_id(4).pos
  end

end
