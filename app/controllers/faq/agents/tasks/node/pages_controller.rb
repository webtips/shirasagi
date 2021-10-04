class Faq::Agents::Tasks::Node::PagesController < ApplicationController
  include Cms::PublicFilter::Node
  include Cms::GeneratorFilter::Rss

  def generate
    written = generate_node_with_pagination @node

    # initialize context before generating rss
    init_context
    if generate_node_rss(@node) && @task
      @task.log "#{@node.url}rss.xml"
    end

    written
  end
end
