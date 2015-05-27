# myapp.rb

require "sinatra"
require "data_mapper"
require "pony"

#This will enable us to have a workaround to make forms
#submit with 'patch' / 'put' / 'delete' by sending a special parameter called _method.
use Rack::MethodOverride

DataMapper.setup(:default, "sqlite3://#{Dir.pwd}/my_database.db")
#This will help DataMapper (ORM) connect to the database.
#In this case the database is SQLite and the location of the file is where the data is stored is in the same folder as this fille (app.rb) so a file will be used (or created) called my_database.db.

#datamapper will create or use a table in the database called 'contacts'
class Contact
  include DataMapper::Resource

  property :id, Serial
  property :first_name, String
  property :last_name, String
  property :email, String
  property :phone_number, String
  property :message, Text
  #Serial datatype will make it PRIMARY KEY AUTOINCREMENT
  # you can use Text for larger text (more than 255 characters)

end

helpers do
  def protected!
    return if authorized?
    headers['WWW-Authenticate'] = 'Basic realm="Restricted Area"'
    halt 401, "Not authorized\n"
  end

  def authorized?
    @auth ||=  Rack::Auth::Basic::Request.new(request.env)
    @auth.provided? and @auth.basic? and @auth.credentials and @auth.credentials == ['admin', 'admin']
  end
end

Contact.auto_upgrade!
#this will create the 'contacts' table if it doesn't already exist. If the table already exists, it will add the columns for the properties that haven't been added already.





get "/" do
  #this will look for a file called "index.erb" inside the "views" folder located inside the same folder as the file 'app.rb'. It must be named 'views' - all lowercase!
  erb :index
  "Hello World"
end


# this means when the sinatra server receives a GET requies with the URL being "/" (which means home page)
#Sinatra will just respond with text that says "Hello World"
# get "/" do, 'Hello World', end.

get "/about" do
  erb :about
end

#executed when the user goes to /contact
#which will display the contact form
get "/contact" do
  erb :contact, layout: :application
end

#executed when the form is submitted
post "/contact" do
  params.to_s
end

post "/contact" do
  Contact.create(params)
  #this will create a record (row) in the database inside contacts table using DataMapper with the parameters given from the user.

  Pony.mail({
    to:"leahhuyghe@gmail.com",
    subject: "#{params[:first_name]} #{params[:last_name]} has contacted you!",
    body: params[:message],
    via: :smtp,
    via_options: {
      address: 'smtp.gmail.com',
      port: '587',
      user_name: 'answerawesome',
      password: 'Sup3r$ecret',
      authentication: :plain, # :plain, :login, :cram_md5, no auth by default
      domain: "localhost.localdomain"
    }
    })

  erb :thank_you, layout: :application
end

post "/note/:id" do |id|
  contact = Contact.get id
  contact.note = params[:note]
  contact.save
  redirect back
end



get "/all_contacts" do
  protected!
  @contacts = Contact.all
  erb :all_contacts, layout: :application
end

#this will accept any url that has /contact/anything
#for instance:
# /contact/1
# /contact/1223
# /contact/hello

get "/contact/:id" do |id|
  protected!
  #the 'get' method of DataMapper will fetch a specific single record using it's id. so we must pass it the id of that record.
  @contact = Contact.get(id)
  erb :contact_details, layout: :application
end

delete "/contact/:id" do |id|
  contact = Contact.get id
  contact.destroy
  redirect.to("/all_contacts")
end
