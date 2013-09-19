require 'sinatra'
require 'sinatra/reloader' if development?
require 'data_mapper'
require 'sass'
require 'slim'
require 'builder'
require 'sinatra/flash'
require 'sinatra/redirect_with_flash'


SITE_TITLE       = "Turtle Recall2"
SITE_DESCRIPTION = "'cause you need to remember when you're that old"

# enable :sessions

use Rack::Session::Cookie, 
  :expire_after => 60,     # One minute should cover it.
  :secret => 'JGNTR2'      # Finally, an actual secret
    

DataMapper::setup( :default, "sqlite3://#{Dir.pwd}/recall.db" )

class Note
  include DataMapper::Resource
  
  property :id,       Serial
  property :content,  Text,     :required => true
  property :complete, Boolean,  :required => true, :default => false
  property :due_at,   DateTime
  property :done_at,  DateTime
  
  property :created_at, DateTime
  property :updated_at, DateTime
end

DataMapper.finalize.auto_upgrade!


helpers do
  include Rack::Utils
  alias_method :h, :escape_html
end


# Handlers

get '/' do      # Home page
  @notes = Note.all :order => :id.desc   # This will become :due_at.asc
  @title = 'All Shells'
  
  if @notes.empty?
    flash[:error] = "No shells found. Add the first one below."
    redirect '/none'
  end
  
  slim :home
end

get '/none' do  # Special place for an empty list because flash[...] only works before a redirect
  @notes = []
  @title = 'No Shells'

  slim :home
end

get '/rss.xml' do   # Give an RSS feed
  @notes = Note.all :order => :id.desc   # This will become :due_at.asc
  builder :rss
end

  
post '/' do     # Add a shell
  n = Note.new
  n.content = params[:content]
  n.created_at = Time.now
  n.updated_at = Time.now
#  n.due_at = params[:due_at]

  if n.save
    redirect '/', :notice => "Shell Added."
  else
    redirect '/', :error => "Saving Shell failed."
  end
end


get '/:id' do   # Start edit
  @note  = Note.get params[:id]
  @title = "Edit Shell ##{params[:id]}"
  
  if @note
    slim :edit
  else
    redirect '/', :error => "That Shell can't be found."
  end
end


put '/:id' do   # Update
  n = Note.get params[:id]
  n.content  = params[:content]
  n.complete = params[:complete] ? 1 : 0
  n.updated_at = Time.now
#  n.due_at = params[:due_at]

  if n.save
    redirect '/', :notice => "Shell Updated."
  else
    redirect '/', :error => "Saving Shell failed."
  end
end


get '/:id/delete' do  # Start delete
  @note = Note.get params[:id]
  @title = "Confirm deletion of Shell ##{params[:id]}"
  
  if @note
    slim :delete
  else
    redirect '/', :error => "That Shell can't be found."
  end
end


delete '/:id' do      # Delete
  n = Note.get params[:id]
  
  if n.destroy
    redirect '/', :notice => "Shell Deleted."
  else
    redirect '/', :error => "Deleting Shell failed."
  end
end


get '/:id/complete' do  # Mark complete
  n = Note.get params[:id]
  n.complete   = n.complete ? 0 : 1 # Flip it
  n.done_at    = n.complete ? Time.now : nil
  n.updated_at = Time.now

  if n.save
    redirect '/', :notice => "Shell Updated."
  else
    redirect '/', :error => "Saving Shell failed."
  end
end

