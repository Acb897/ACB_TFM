require 'rdf'
require 'sparql'
require 'rest-client'
require 'json'
require 'time'
require 'sinatra'
require 'haml'
require 'sinatra/partial'
require 'erb'
require "uuidtools"

#set :public_folder, '/front-end/public'

get '/' do
     haml :index, :format => :html5
end

post '/knockknock' do
    knockknock()
    haml :results, :format => :html5
end

get '/knockknock' do
    @results = "no, you need to POST the data, not GET the data :-)"
    haml :results, :format => :html5
end

def knockknock
  # we should look into how ORCIS does OAuth.
  # https://info.orcid.org/documentation/api-tutorials/api-tutorial-get-and-authenticated-orcid-id/#easy-faq-2537
  # we may have time to implement this before the defense.
  json = JSON.parse(request.body.read)
  $stderr.puts "I got some JSON: #{json.inspect}"
  query = json['query']
  orcid = json['orcid']  # possibly real, validated by certificate
  token = json['token'] # fake for the moment
  @validated = validate(orcid, token)
  if @validated
    stamp = Time.new.to_f
    
    File.open("/tmp/query#{stamp}/query", "w") {|f| f.write(query)}
    File.open("/tmp/query#{stamp}/#{orcid}", "w") {|f| f.write(@validated.to_s)}

    @results = "VALIDATED: User #{orcid} has requeted the execution of the query: #{query}.  This may take some time..."
  else
    @results = "User #{orcid} FAILED VALIDATION.  No action will be taken"
  end
end


def validate(orcid, token)
    return true
end            