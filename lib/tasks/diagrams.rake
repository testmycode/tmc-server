namespace :doc do
  # Using http://railroady.prestonlee.com/
  namespace :diagram do
    desc "Genrates doc/diagrams/models.png"
    task :models do
      sh "railroady -l -m -M | dot -Tpng -o doc/diagrams/models.png"
    end
  end

  desc "Generates model diagram into doc/diagrams/"
  task diagrams: %w(diagram:models)
end
