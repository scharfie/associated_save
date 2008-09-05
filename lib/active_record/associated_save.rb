module ActiveRecord
  module AssociatedSave
    module ClassMethods
      # Creates a callback which saves associated records
      # when passed in from a form.  An example will be much easier
      # to explain this :-)
      # 
      # Example:
      #   class Collection < ActiveRecord::Base
      #     has_many :items
      #     associated_save :items
      #   end
      #       
      #   class Item < ActiveRecord::Base
      #     belongs_to :collection
      #   end
      # 
      #   # some form:
      #   <% @collection.items.each do |item| %>
      #     <% fields_for 'collection[_items][]', item do |form| %>
      #       <%= form.text_field :name %>
      #       <%= form.hidden_field :id %>
      #     <% end %>
      #   <% end %>
      # 
      # When the collection is saved, the associated :items are
      # updated based on the data in params[:collection][:_items]
      # 
      # By default, the parameter key name is the association name
      # with a prefix of _, but this can be set to anything you want
      # by setting the :from option.
      # 
      # In the example, an after_save callback named "save_associated_items"
      # would be created.  When the callback is invoked, all associated 
      # objects defined will be updated, and anything not updated is deleted,
      # unless the :delete option is set to false (defaults to true).  This is
      # useful if you use JS to remove a set of form fields from the DOM, for
      # example.
      #
      # Note: this plugin is designed for has_many relationships,
      # since that is the most likely candidate for this type of functionality.
      def associated_save(name, options={})
        options.reverse_merge! :from => "_#{name}", :delete => true
        from        = options[:from]
        method_name = "save_associated_#{name}"
        reflection  = reflect_on_association(name)
        
        # Create the callback method
        define_method method_name do
          return unless from = instance_variable_get("@#{from}")
          foreign_key = reflection.options[:foreign_key]
          association = send(name)
          ids_to_delete = association.map { |e| e.id }
          
          # Update associated objects
          from.each do |attributes|
            next if attributes.blank?
            attributes.merge! foreign_key => self.id
            record = (id = attributes[:id]).blank? ? association.build : association.find_by_id(id)
            record.update_attributes(attributes)
            ids_to_delete.delete(id.to_i)
          end
          
          # Delete unreferenced associated objects
          reflection.options[:class_name].constantize.delete(ids_to_delete) if options[:delete]
        end
          
        # Create accessor for the variable  
        attr_accessor from  
        
        # Create the callback
        after_save method_name
      end
    end
    
    module InstanceMethods
      # Nothing for now
    end
    
    def self.included(receiver)
      receiver.extend         ClassMethods
      receiver.send :include, InstanceMethods
    end
  end
end
