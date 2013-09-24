#coding: utf-8
require 'spec_helper'
require 'tempfile'


describe FilesHelper do
  describe "#valid_encoding!" do
    it "should reencode if non valid encoding is used" do
      text = "\xc3" # ä\x28\xe4
      text.valid_encoding?.should_not be true
      valid_encoding!(text).valid_encoding?.should be true
    end

    it "ISO-8859-1 characters are converted correctly"

  end
end
