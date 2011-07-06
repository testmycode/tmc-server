require 'spec_helper'

describe ApplicationHelper do
  describe "#labeled" do
    describe "when given two string parameters" do
      it "should add a label with 1st param as text for the tag given in 2nd param" do
        labeled('Xooxer', '<input type="text" id="foo" name="bar" />').should include('<label for="foo">Xooxer</label><input')
      end
      
      it "and the 2nd param has multiple tags, should add the label for the first tag with and id" do
        labeled('Mooxer', '<div id="moo"><div id="xoo"></div></div>').should include('<label for="moo">Mooxer</label><div')
      end
      
      it "should escape the label text" do
        labeled("Moo & co.", '<div id="moo"></div>').should include('Moo &amp; co.')
      end
      
      it "should raise an error if the 2nd param has no 'id' attribute" do
        expect { labeled("Oopsie", '<div></div>') }.to raise_error
      end
    end
  end
  
  describe "#labeled_field" do
    it "should work like #labeled but wrap the whole thing in a <div class=\"field\">" do
      labeled_field('Xooxer', '<input type="text id="foo" name="foo" />').should ==
        '<div class="field"><label for="foo">Xooxer</label><input type="text id="foo" name="foo" /></div>'
    end
  end
end
