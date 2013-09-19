require 'sinatra'
require 'sinatra/reloader' if development?
require 'data_mapper'
require 'sass'
require 'slim'

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


# Handlers

get( '/styles/main.css' ) { scss :styles }


get '/' do      # Home page
  @notes = Note.all :order => :id.desc   # This will become :due_at.asc
  @title = 'All Shells'
  
  slim :home
end


post '/' do     # Add a shell
  puts "Adding Shell"
  
  n = Note.new
  n.content = params[:content]
  n.created_at = Time.now
  n.updated_at = Time.now
# n.due_at = params[:due_at]
  n.save
  redirect to('/')
end


get '/:id' do
  @note  = Note.get params[:id]
  @title = "Edit Note ##{params[:id]}"
  slim :edit
end


__END__

@@styles
$done: #ddffdd;

form#add {
  margin-bottom: 20px;
  
  textarea {
    width: 850px;
    margin-right: 20px;
  }
}

button {
  a       { color: white; }
  a:hover { color: white; text-decoration: none }
}

article {
  border: 1px solid #e5e5e5;
  padding: 5px;
  margin-bottom: 2px;
}

article.complete {
    background: $done;
}

div#footer {
  margin-top: 20px;
}