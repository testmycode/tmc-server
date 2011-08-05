module CoursesHelper
  def github_repo_url_to_project_page_url(url)
    if url =~ /github.com[:\/]([^\/]*)\/([^\/]*)\.git/
      "https://github.com/#{$1}/#{$2}"
    end
  end
end
