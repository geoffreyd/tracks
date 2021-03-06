ActionController::Routing::Routes.draw do |map|
  UJS::routes
  
  map.with_options :controller => 'login' do |login|
    login.login 'login', :action => 'login'
    login.formatted_login 'login.:format', :action => 'login'
    login.logout 'logout', :action => 'logout'
    login.formatted_logout 'logout.:format', :action => 'logout'
    login.open_id_begin 'begin', :action => 'begin'
    login.formatted_open_id_begin 'begin.:format', :action => 'begin'
    login.open_id_complete 'complete', :action => 'complete'
    login.formatted_open_id_complete 'complete.:format', :action => 'complete'
  end

  map.resources :users,
                :member => {:change_password => :get, :update_password => :post,
                             :change_auth_type => :get, :update_auth_type => :post, :complete => :get,
                             :refresh_token => :post }
  map.with_options :controller => "users" do |users|
    users.signup 'signup', :action => "new"
  end

  map.resources :contexts, :collection => {:order => :post} do |contexts|
    contexts.resources :todos, :name_prefix => "context_"
  end

  map.resources :projects, :collection => {:order => :post, :alphabetize => :post} do |projects|
    projects.resources :todos, :name_prefix => "project_"
  end

  map.resources :todos,
                :member => {:toggle_check => :put, :toggle_star => :put},
                :collection => {:check_deferred => :post, :filter_to_context => :post, :filter_to_project => :post}
  map.with_options :controller => "todos" do |todos|
    todos.home '', :action => "index"
    todos.tickler 'tickler', :action => "list_deferred"
    todos.mobile_tickler 'tickler.m', :action => "list_deferred", :format => 'm'
    todos.done 'done', :action => "completed"
    todos.done_archive 'done/archive', :action => "completed_archive"
    
    # This route works for tags with dots like /todos/tag/version1.5
    # please note that this pattern consumes everything after /todos/tag
    # so /todos/tag/version1.5.xml will result in :name => 'version1.5.xml'
    # UPDATE: added support for mobile view. All tags ending on .m will be
    # routed to mobile view of tags.
    todos.tag 'todos/tag/:name', :action => "tag", :format => 'm', :name => /.*\.m/
    todos.tag 'todos/tag/:name', :action => "tag", :name => /.*/
    
    todos.mobile 'mobile', :action => "index", :format => 'm'
    todos.mobile_abbrev 'm', :action => "index", :format => 'm'
    todos.mobile_abbrev_new 'm/new', :action => "new", :format => 'm'
  end
  
  map.resources :notes
  map.feeds 'feeds', :controller => 'feedlist', :action => 'index'
  map.feeds 'feeds.m', :controller => 'feedlist', :action => 'index', :format => 'm'
  
  map.preferences 'preferences', :controller => 'preferences', :action => 'index'
  map.integrations 'integrations', :controller => 'integrations', :action => 'index'

  # Install the default route as the lowest priority.
  map.connect ':controller/:action/:id'

end
