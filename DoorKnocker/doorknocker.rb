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
require 'open3'

#set :public_folder, '/front-end/public'
URL = "http://localhost:4567/"
SPQL = "http://fairdata.systems:7777/sparql"


get '/' do
     haml :index, :format => :html5
end

get '/status/:id' do |id|
  status(id)    
  haml :status, :format => :html5
end

get '/queue' do
  queue()
  haml :queue, :format => :html5
end

get '/accept/:id' do |id|
  accept(id)
  haml :accept, :format => :html5
end

get '/reject/:id' do |id|
  reject(id)
  haml :reject, :format => :html5
end

get '/review/:id' do |id|
  review(id)
  haml :review, format: :html5
end

get '/submit' do
  haml :submit, :format => :html5
end

post '/submit' do
  preknock()
  haml :submitted, :format => :html5
end

post '/knockknock' do
    knockknock()
    haml :submitted, :format => :html5
end

get '/knockknock' do
    @results = "no, you need to POST the data, not GET the data :-)"
    haml :submit, :format => :html5
end

# --------------------------- logic here

def preknock
  orcid = params['orcid']
  query = params['query']
  token = params['token']
  json = {"orcid" => orcid, "token" => token, "query" => query}
  knockknock(json)
end

def review(id)
  @req = Hash.new
  @error = nil
  @error = "Record #{id} doesn't exist" unless File.exists?("/tmp/query#{id}/query")
  unless @error
    query = File.read("/tmp/query#{id}/query").strip
    orcid = File.read("/tmp/query#{id}/orcid").strip
    @req[orcid] = [id, query]    
  end    
end


def status(id)
  unless File.exists("/tmp/query#{id}")
    @status = "No query with that identifier exists"
    return
  end
  
  if File.exists?("/tmp/query#{id}/complete")
      @status = "Query #{id} has been completed"
  elsif File.exists?("/tmp/query#{id}/query")
      @status = "Query #{id} is still queued for processing"
  else
      @status = "Query #{id} has encountered problems... not sure what is wrong"
  end
end

def queue
  @queue = Array.new
  files = Dir["/tmp/query*"]
  files.each do |f|
#      abort "format mismatch #{f}" unless f =~ /query(\d+\.\d+)/
    next unless f =~ /query(\d+\.\d+)/
    next if File.exists?("/tmp/query#{$1}/complete")  # not in queue anymore
    @queue << $1
  end

    
end
def reject(id)
  File.delete("/tmp/query#{id}/query") if File.exists?("/tmp/query#{id}/query")
  File.delete("/tmp/query#{id}/orcid") if File.exists?("/tmp/query#{id}/orcid")
  FileUtils.rm_rf("/tmp/query#{id}")
  @reject = "All records for query ${id} have been removed."

    
end
def knockknock(json = nil)
  # we should look into how ORCIS does OAuth.
  # https://info.orcid.org/documentation/api-tutorials/api-tutorial-get-and-authenticated-orcid-id/#easy-faq-2537
  # we may have time to implement this before the defense.
  unless json
    json = JSON.parse(request.body.read)
  end
  
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

def accept(id)
  $stderr.puts "BEGINNING TE WRITE"
  write_docker_compose()
  $stderr.puts "BEGINNING THE ENV WRITE"
  File.open("/tmp/.env", "w") do |f|
    f.puts "SPARQL=#{SPQL}"
    f.puts "ENDPOINT_SOURCE=http://tpfserver:3000/temp"
    f.puts "ENDPOINT_TARGET=http://fairdata.systems:8890/DAV/home/LDP/Hackathon/"
    f.puts "CREDENTIALS=ldp:ldp"
    f.puts "QUERY_PATH=/tmp/query#{id}/"
  end
  $stderr.puts "BEGINNING THE CDIR"
  Dir.chdir('/tmp') do
#    $stderr.puts RestClient.get("http://localhost:#{@port}/temp")
    $stderr.puts "BEGINNING THE DCOMP"
    stdout, stderr, status = Open3.capture3("docker-compose up -d")
    @errors = stderr
    $stderr.puts stdout
    $stderr.puts stderr
    $stderr.puts status
  end
  @accepted = "Query #{id} is now being processed"
    
end

def validate(orcid, token)
    return true
end

def write_docker_compose
  compose =<<END
version: "3"
services:

  tpf_server:
    image: markw/tpfserver:latest
    container_name: tpfserver
    environment:
      SPARQL: ${SPARQL}

  triple_harvester:
    image: markw/triple_harvester:latest
    container_name: triple_harvester
    environment:
      ENDPOINT_SOURCE: ${ENDPOINT_SOURCE}
      ENDPOINT_TARGET: ${ENDPOINT_TARGET}
      CREDENTIALS: ${CREDENTIALS}
      QUERY_FILE_PATH: /app/queries/query
      QUERY_PATH: ${QUERY_PATH}
    volumes:
      - ${QUERY_PATH}:/app/queries/
    depends_on:
      - tpf_server

END

  File.open("/tmp/docker-compose.yml", "w") do |f|
    f.puts compose
  end
    
end