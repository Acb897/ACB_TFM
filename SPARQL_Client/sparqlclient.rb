require 'rdf'
require 'sparql'
require 'sparql/client'
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
require 'digest'
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

get '/checkall/:orc' do |orc|
  checkall(orc)
  haml :checkall, :format => :html5
end

get '/resolve/:orcid/:sessionid' do |orcid, sessionid|
  resolve(orcid, sessionid)
  haml :solutions, :format => :html5
end




# --------------------------- logic here
def resolve(orcid, sessionid)
  myfolder = "/tmp/#{orcid}/#{sessionid}"
  $stderr.puts "osdir dsesion"
  $stderr.puts orcid
  $stderr.puts sessionid
  @query = File.read("#{myfolder}/query")
  $stderr.puts @query
  $stderr.puts  "#{myfolder}/query"
  @result = ""
  c = SPARQL::Client.new("http://fairdata.systems:8890/sparql")
  results = c.query(@query)
  #results.each do |solution|
  #  solution.each_binding do |name, value|
  #    @result += "#{name} = #{value}<br/>"
  #  end
  #end
  @result = results.to_html

end

def checkall(orc)
  @orcid = orc
  
  myfolder = "/tmp/#{@orcid}"
  @results = Hash.new
  sessions = Dir["#{myfolder}/*"] # all named by the hash of the query
  sessions.each do |s|
    s =~ /.*\/(.+)$/
    sessionid = $1
    statuss = Array.new
    query = File.read("#{s}/query")
    status_urls = File.read("#{s}/queue")

    status_urls.split("\n").each do |url|
      poll_status(url)
      statuss << @thisresp
    end
    @results[sessionid] = [query, statuss]
    
  end
    
end

def poll_status(loc)
  resp = RestClient.get(loc)
  resp.to_s =~ /strong\>([^\<]+)\</
  @thisresp = $1
    
end


def submit
  locations = params[:location]
  @origquery = params[:query]
  token = params[:token]
  @orcid = params[:orcid]
  
  trans = SPARQLTransform.new({sparql: @origquery})
  @query = trans.transform
  @loc_responses= Hash.new
  locations.each do |loc|
    data = {"orcid" => @orcid, "token" => token, "query" => @query}.to_json
    res = RestClient::Request.execute(method: :post,
                            url: loc,
                            payload: data,
                            headers: {"Content-Type" => "application/json"}
                           )
    $stderr.puts res  # currently comes back as HTML... I will fix that another day!
    res.to_s =~ /(\/status\/query\d+\.\d+)/
    status = $1
    loc.gsub!('/knockknock', "")  # we know the remote API we are interacting with, so just remove knockknock
    loc += status                 # and replace it with the 'status' API call for that submission
    @loc_responses[loc] = "Click here to monitor status:  <a href='#{loc}'>#{loc}</a><br><br>"
    
    write_to_cache(@origquery, @orcid,loc)
  
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
    @errors = "the input query failed to parse"
  end
end

def search_match(query)
  @discovered['http://ldp.cbgp.upm.es:4567/knockknock'] = "CBGP Endpoint about plant pathogen interactions"
  @discovered['http://fairdata.systems:4567/knockknock'] = "FAIR Data Systems endpoint about pathogen ecology"
end

def write_to_cache(query,orcid,loc)
  foldername = Digest::SHA256.hexdigest query
  myfolder = "/tmp/#{orcid}"
  mysession = "/tmp/#{orcid}/#{foldername}"
  Dir.mkdir myfolder unless File.exists? myfolder
  Dir.mkdir mysession unless File.exists? mysession
  File.open("#{mysession}/query", "w") {|f| f.puts query}
  File.open("#{mysession}/queue", "a") {|f| f.puts loc}  # append!
end

