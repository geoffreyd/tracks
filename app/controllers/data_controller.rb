class DataController < ApplicationController
  
  require 'csv'
  
  def index
        @page_title = "TRACKS::Export"
  end

  def import
  end

  def export
    # Show list of formats for export
  end
  
  # Thanks to a tip by Gleb Arshinov
  # <http://lists.rubyonrails.org/pipermail/rails/2004-November/000199.html>
  def yaml_export
    all_tables = {}
    
    all_tables['todos'] = current_user.todos.find(:all)
    all_tables['contexts'] = current_user.contexts.find(:all)
    all_tables['projects'] = current_user.projects.find(:all)
    all_tables['tags'] = current_user.tags.find(:all)
    all_tables['taggings'] = current_user.taggings.find(:all)
    all_tables['notes'] = current_user.notes.find(:all)
    
    result = all_tables.to_yaml
    result.gsub!(/\n/, "\r\n")   # TODO: general functionality for line endings
    send_data(result, :filename => "tracks_backup.yml", :type => 'text/plain')
  end
  
  def csv_actions
    content_type = 'text/csv'
    CSV::Writer.generate(result = "") do |csv|
      csv << ["id", "Context", "Project", "Description", "Notes", "Tags",
              "Created at", "Due", "Completed at", "User ID", "Show from",
              "state"]
      current_user.todos.find(:all, :include => [:context, :project]).each do |todo|
        # Format dates in ISO format for easy sorting in spreadsheet
        # Print context and project names for easy viewing
        csv << [todo.id, todo.context.name, 
                todo.project_id = todo.project_id.nil? ? "" : todo.project.name,
                todo.description, 
                todo.notes, todo.tags.collect{|t| t.name}.join(', '),
                todo.created_at.to_formatted_s(:db),
                todo.due = todo.due? ? todo.due.to_formatted_s(:db) : "",
                todo.completed_at = todo.completed_at? ? todo.completed_at.to_formatted_s(:db) : "", 
                todo.user_id, 
                todo.show_from = todo.show_from? ? todo.show_from.to_formatted_s(:db) : "",
                todo.state] 
      end
    end
    send_data(result, :filename => "todos.csv", :type => content_type)
  end
  
  def csv_notes
    content_type = 'text/csv'
    CSV::Writer.generate(result = "") do |csv|
      csv << ["id", "User ID", "Project", "Note",
              "Created at", "Updated at"]
      # had to remove project include because it's association order is leaking through
      # and causing an ambiguous column ref even with_exclusive_scope didn't seem to help -JamesKebinger 
      current_user.notes.find(:all,:order=>"notes.created_at").each do |note|
        # Format dates in ISO format for easy sorting in spreadsheet
        # Print context and project names for easy viewing
        csv << [note.id, note.user_id, 
                note.project_id = note.project_id.nil? ? "" : note.project.name,
                note.body, note.created_at.to_formatted_s(:db),
                note.updated_at.to_formatted_s(:db)] 
      end
    end
    send_data(result, :filename => "notes.csv", :type => content_type)
  end
  
  def xml_export
    result = ""
    result << current_user.todos.find(:all).to_xml
    result << current_user.contexts.find(:all).to_xml(:skip_instruct => true)
    result << current_user.projects.find(:all).to_xml(:skip_instruct => true)
    result << current_user.tags.find(:all).to_xml(:skip_instruct => true)
    result << current_user.taggings.find(:all).to_xml(:skip_instruct => true)
    result << current_user.notes.find(:all).to_xml(:skip_instruct => true)
    send_data(result, :filename => "tracks_backup.xml", :type => 'text/xml')
  end
  
  def yaml_form
    # Draw the form to input the YAML text data
  end

  # yaml_import in this state, is good if we want to restore backed up objects to how they where,
  # or populating a clean install.
  # But not so good if you want to merge an existing DB with what you have in yaml format.
  # TODO: Make this smart, and if told to, allow merging of data, instead of just overriding.
  def yaml_import
    # Logic to load the YAML text file and create new records from data
    imported_data = YAML.load(params[:import]['yaml'])

    imported_data.each do |k, objs|
      objs.each do |obj|  
        # We don't know what classes we are working with
        klass = Object.const_get(obj.class.to_s) # so lets call upon some of ruby's dark magic.

        if obj.respond_to?(:ivars)
          values = obj.ivars["attributes"]
          obj = klass.new(values)
          obj.id = values["id"]
        end
        # if the object exists, then lets update it.
        if klass.exists?(obj.id)
          updates = klass.partial_updates # store the status of partial_updates
          klass.partial_updates = false   # Force it to be false
          obj.save                        # This should save all attributes.
          klass.partial_updates = updates # Now put it back to what it was.
        else # Otherwise, lets put it in.
          obj.send(:create)
        end
      end
    end
  end
 
end
