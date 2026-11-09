# typed: false
# frozen_string_literal: true

require 'spec_helper'

describe 'files/_files', type: :view do
  def render_prelude(html)
    file = SourceFileList::FileRecord.new('src/Main.java', 'class Main {}')
    file.html_prelude = html
    render partial: 'files/files', locals: { files: [file] }
    rendered
  end

  it 'strips scripts and event handlers from the HTML prelude' do
    html = render_prelude(<<~HTML)
      <script>alert(1)</script>
      <img src="x.png" onerror="alert(2)">
      <a href="javascript:alert(3)">link</a>
    HTML
    expect(html).not_to include('<script')
    expect(html).not_to include('onerror')
    expect(html).not_to include('javascript:')
    expect(html).to include('<img src="x.png">')
  end

  it 'keeps formatting in the HTML prelude' do
    html = render_prelude(<<~HTML)
      <h2>Task</h2>
      <ul><li><a href="https://example.com/doc">Docs</a></li></ul>
      <pre><code>int x = 1;</code></pre>
      <table><tr><th>In</th><td>Out</td></tr></table>
      <p style="color: red;"><strong>Note</strong></p>
    HTML
    expect(html).to include('<h2>Task</h2>')
    expect(html).to include('<li><a href="https://example.com/doc">Docs</a></li>')
    expect(html).to include('<pre><code>int x = 1;</code></pre>')
    expect(html).to include('<th>In</th><td>Out</td>')
    expect(html).to include('<p style="color:red;"><strong>Note</strong></p>')
  end
end
