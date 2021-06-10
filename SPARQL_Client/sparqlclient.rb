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
require './transform.rb'

#set :public_folder, '/front-end/public'
get '/' do
     haml :interface, :format => :html5
end

get '/sparql' do
  haml :interface, :format => :html5
end

post '/search' do
  search()
  haml :search, :format => :html5
end

post '/submit' do
  submit()
  haml :submitted, :format => :html5
end

# --------------------------- logic here
def submit
  
  $stderr.puts params
  locations = params[:location]
  @query = params[:query]
  token = params[:token]
  orcid = params[:orcid]
  
  trans = SPARQLTransform.new({sparql: @query})
  @query = trans.transform
  @loc_responses= Hash.new
  locations.each do |loc|
    data = {"orcid" => orcid, "token" => token, "query" => @query}.to_json
    res = RestClient::Request.execute(method: :post,
                            url: loc,
                            payload: data,
                            headers: {"Content-Type" => "application/json"}
                           )
    $stderr.puts res
    res.to_s =~ /(\/status\/query\d+\.\d+)/
    status = $1
    loc.gsub!('/knockknock', "")
    loc += status
    @loc_responses[loc] = "Click here to monitor status:  <a href='#{loc}'>#{loc}</a><br><br>"
  end 
end

def search
  @orcid = params[:orcid]
  @query = params[:query]
  @token = params[:token]

  @errors = nil
  @discovered = Hash.new

  q = SPARQLTransform.new({sparql: @query})
  if q
    search_match(q)
  else
    @errors = "failed parse"
  end
end

def search_match(query)
  @discovered['http://ldp.cbgp.upm.es:4567/knockknock'] = "CBGP private data endpoint"
  @discovered['http://fairdata.systems:4567/knockknock'] = "FAIR Data Systems private data endpoint"
  $stderr.puts @discovered.class
end

def transform
  
end

