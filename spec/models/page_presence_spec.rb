require 'spec_helper'

describe PagePresence do
  let(:user1) { Factory.create(:user) }
  let(:user2) { Factory.create(:user) }

  it "knows the visitors for a page" do
    PagePresence.refresh(user1, '/foo')
    PagePresence.refresh(user1, '/bar')
    PagePresence.refresh(user2, '/bar')
    PagePresence.visitors_of('/foo').should == [user1]
    PagePresence.visitors_of('/bar').sort_by(&:id).should == [user1, user2]
    PagePresence.visitors_of('/baz').should == []
  end

  it "needs to be refreshed" do
    PagePresence.refresh(user1, '/foo')
    PagePresence.update_all(:updated_at => (PagePresence::TIMEOUT * 2).seconds.ago)
    PagePresence.refresh(user2, '/foo')
    PagePresence.delete_older_than_timeout
    PagePresence.visitors_of('/foo').should == [user2]
  end
end