# typed: false
# frozen_string_literal: true

require 'spec_helper'

describe BootstrapFlashHelper, type: :helper do
  it 'escapes plain-text messages' do
    flash[:notice] = 'Teacher <script>alert(1)</script> removed from organization'
    expect(helper.bootstrap_flash).to include('Teacher &lt;script&gt;alert(1)&lt;/script&gt; removed')
  end

  it 'keeps HTML that was built as safe' do
    flash[:notice] = helper.safe_join(['Created. ', helper.link_to('View', '/certificates/1')])
    expect(helper.bootstrap_flash).to include('Created. <a href="/certificates/1">View</a>')
  end
end
