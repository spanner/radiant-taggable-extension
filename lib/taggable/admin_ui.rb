module Taggable
  module AdminUI

   def self.included(base)
     base.class_eval do

        attr_accessor :tag
        alias_method :tags, :tag

        def load_taggable_regions
          @tag = load_default_tag_regions
        end

        protected

          def load_default_tag_regions
            OpenStruct.new.tap do |tag|
              tag.edit = Radiant::AdminUI::RegionSet.new do |edit|
                edit.main.concat %w{edit_header edit_form}
                edit.form.concat %w{edit_name edit_role edit_description}
                edit.form_bottom.concat %w{edit_timestamp edit_buttons}
              end
              tag.show = Radiant::AdminUI::RegionSet.new do |show|
                show.main.concat %w{show_header show_pages show_assets}
              end
              tag.index = Radiant::AdminUI::RegionSet.new do |index|
                index.thead.concat %w{title_header link_header description_header usage_header modify_header}
                index.tbody.concat %w{title_cell link_cell description_cell usage_cell modify_cell}
                #index.bottom.concat %w{new_button}
              end
              #tag.remove = tag.index
              tag.remove = Radiant::AdminUI::RegionSet.new do |remove|
                remove.main.concat %w{remove_header remove_pages remove_assets}
              end
              #tag.new = tag.edit
            end
          end
        
      end
    end
  end
end