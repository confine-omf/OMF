
OMF::Web::Theme.require 'page'

module OMF::Web::Theme
  
  class MultiCardPage < Page

    
    def initialize(widget, module_name, items_class, opts)
      super opts
      @widget = widget
      @items_class = items_class
      @module_name = module_name
    end
    
    def render_card_nav
      div :id => 'card_nav' do
        ol do
          @items_class.each_with_index do |g, i| 
            klass = (i == @card_id) ? 'selected' : nil
            li :class => klass do
              a g[:name] || 'unknown', :href => "/#{@module_name}/show?tid=#{i}&sid=#{Thread.current["sessionID"]}"
            end
          end
        end
      end            
    end # render_card_nav

    def render_card_body
      render_card_nav
      return unless @widget
      div :id => :card_content do 
        render_widget @widget
      end        
    end
    
  end # SubMenuCard
  
end