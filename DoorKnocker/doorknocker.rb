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


SPQL = ENV['SPARQL']
TRIPLE_HARVESTER = "http://triple_harvester:8000/"


get '/' do
     haml :index, :format => :html5
end

get '/status/:id' do |id|
  statuss(id)    
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
  $stderr.puts "pre-knocking and creating data hash"
  orcid = params['orcid']
  query = params['query']
  token = params['token']
  data = {"orcid" => orcid, "token" => token, "query" => query}
  knockknock(data)
end

def review(id)
  @req = Hash.new
  @error = nil
  @error = "Record #{id} doesn't exist" unless File.exists?("/tmp/#{id}/query")
  unless @error
    query = File.read("/tmp/#{id}/query").strip
    orcid = File.read("/tmp/#{id}/orcid").strip
    @req[orcid] = [id, query]    
  end    
end


def statuss(id)
  @status = "default message"
  if !File.exists?("/tmp/#{id}")
    @status = "No query with the identifier #{id} exists"
  elsif File.exists?("/tmp/#{id}/completed")
    @status = "Query #{id} has been completed"
  elsif File.exists?("/tmp/#{id}/query")
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
    next unless f =~ /(query\d+\.\d+)/
    next if File.exists?("/tmp/#{$1}/completed")  # not in queue anymore
    @queue << $1
  end

    
end
def reject(id)
  File.delete("/tmp/#{id}/query") if File.exists?("/tmp/#{id}/query")
  File.delete("/tmp/#{id}/orcid") if File.exists?("/tmp/#{id}/orcid")
  FileUtils.rm_rf("/tmp/#{id}")
  @reject = "All records for #{id} have been removed."

    
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
  @results["query"] = query
  @results["orcid"] = orcid

  @validated = validate(orcid, token)
  if @validated
    id = "query" + Time.new.to_f.to_s
    
    
    FileUtils.mkdir_p "/tmp/#{id}"
    File.open("/tmp/#{id}/query", "w") {|f| f.write(query)}
    File.open("/tmp/#{id}/orcid", "w") {|f| f.write(orcid)}

    @results["valid"] = "VALIDATED: User has been validated.  Query has been queued for review"
    @results["id"] = "query#{id}"
  else
    @results["valid"] = "INVALID: User #{orcid} has not been validated.  Query has been discarded"
    @results["id"] = nil
  end
end

def accept(id)
  $stderr.puts "BEGINNING TE WRITE"
  write_env(id)
  $stderr.puts "BEGINNING THE CDIR"
  Dir.chdir('/tmp') do
    $stderr.puts "BEGINNING THE DCOMP"
    out = RestClient.get(TRIPLE_HARVESTER)
    File.open("/tmp/#{id}/completed", "w") {|f| f.puts "completed"}
    $stderr.puts out
  end
  @accepted = "Query #{id} is now being processed"
    
end

def validate(orcid, token)
    return true
end


def write_env(id)
  $stderr.puts "BEGINNING THE ENV WRITE"
  File.open("/tmp/.env", "w") do |f|
    f.puts "SPARQL=#{SPQL}"
    f.puts "ENDPOINT_SOURCE=http://tpfserver:3000/temp"
    f.puts "ENDPOINT_TARGET=http://fairdata.systems:8890/DAV/home/LDP/Hackathon/"
    f.puts "CREDENTIALS=ldp:ldp"
    f.puts "QUERY_PATH=/tmp/#{id}/"
  end 
end


# DEPRECATED in favour of HTTP call
###############################
#def write_launcher
#  $stderr.puts "BEGINNING THE ENV WRITE"
#  File.open("/tmp/launcher.sh", "w") do |f|
#    f.puts "#!/bin/bash"
#    f.puts "echo $PATH > pathinfo"
#    f.puts "/usr/local/bin/docker-compose up -d"
#  end     
#end
#
#def write_docker_compose
#  compose =<<END
#version: "3"
#services:
#
#  tpf_server:
#    image: markw/tpfserver:latest
#    container_name: tpfserver
#    environment:
#      SPARQL: ${SPARQL}
#
#  triple_harvester:
#    image: markw/triple_harvester:latest
#    container_name: triple_harvester
#    environment:
#      ENDPOINT_SOURCE: ${ENDPOINT_SOURCE}
#      ENDPOINT_TARGET: ${ENDPOINT_TARGET}
#      CREDENTIALS: ${CREDENTIALS}
#      QUERY_FILE_PATH: /app/queries/query
#      QUERY_PATH: ${QUERY_PATH}
#    volumes:
#      - ${QUERY_PATH}:/app/queries/
#    depends_on:
#      - tpf_server
#
#END
#
#  File.open("/tmp/docker-compose.yml", "w") do |f|
#    f.puts compose
#  end
#end