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
require 'fileutils'

#set :public_folder, '/front-end/public'
URL = "http://localhost:4567/"

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

get '/status/:id' do |id|
    if File.exists?("/tmp/query#{id}/query")
        @status = "Query #{id} is still queued for processing"
    else
        @status = "Query #{id} has been processed"
    end
    
    haml :status, :format => :html5
end

get '/queue' do
    @queue = Array.new
    files = Dir["/tmp/query*"]
    files.each do |f|
#      abort "format mismatch #{f}" unless f =~ /query(\d+\.\d+)/
      next unless f =~ /query(\d+\.\d+)/
      @queue << $1
      @queue << "blah"
    end
    haml :queue, :format => :html5

end

get '/accept/:id' do |id|
  # deploy docker compose
  # delete query
end

get '/reject/:id' do |id|
  # deploy docker compose
  # delete query
end

get '/review/:id' do |id|
  @req = Hash.new
  query = File.read("/tmp/query#{id}/query").strip
  orcid = File.read("/tmp/query#{id}/orcid").strip
  @req[orcid] = query
  haml :review, format: :html5
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
  @results = Hash.new
  @validated = validate(orcid, token)
  if @validated
    stamp = Time.new.to_f
    
    FileUtils.mkdir_p "/tmp/query#{stamp}"
    File.open("/tmp/query#{stamp}/query", "w") {|f| f.write(query)}
    File.open("/tmp/query#{stamp}/orcid", "w") {|f| f.write(orcid)}

    @results[stamp] = "VALIDATED: User #{orcid} has requested the execution of the query: #{query}.  This may take some time..."
  else
    @results[stamp] = "User #{orcid} FAILED VALIDATION.  No action will be taken"
  end
end


def validate(orcid, token)
    return true
end            