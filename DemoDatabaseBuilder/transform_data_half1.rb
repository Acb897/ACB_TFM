require './utils.rb'
require 'rdf'
require 'ldp_simple'
require 'rdf/vocab'

rdf =  RDF::Vocabulary.new("http://www.w3.org/1999/02/22-rdf-syntax-ns#")
rdfs = RDF::Vocabulary.new("http://www.w3.org/2000/01/rdf-schema#")
sio = RDF::Vocabulary.new("http://semanticscience.org/resource/")
uo =  RDF::Vocabulary.new("http://purl.obolibrary.org/obo/uo.owl#")
efo = RDF::Vocabulary.new("http://www.ebi.ac.uk/efo/efo.owl#")
geo = RDF::Vocabulary.new("http://www.w3.org/2003/01/geo/wgs84_pos#")
lsid = RDF::Vocabulary.new("http://www.eu-nomen.eu/portal/taxon.php?GUID=")
food = RDF::Vocabulary.new("http://data.food.gov.uk/codes/foodtype/id/")
wiki = RDF::Vocabulary.new("https://en.wikipedia.org/wiki/ISO_3166-2:")


client = LDP::LDPClient.new({
	:endpoint => "http://fairdata.systems:7777/DAV/home/TFM/Half1/",
	:username => "half1",
	:password => "half1"})
top = client.toplevel_container
 
my =   RDF::Vocabulary.new("http://tfm.exampledata.org/TFM/Alberto/")

obs = File.open("SpeciesAbundancePub2015.tsv")
obs.readline # discard header

count = 0

obs.each do |line|
  (id, cropC, cropN, species, countryC, countryN, year, duration, long, lat, comments) = line.split("\t")
  count += 1
  break if count > 700
  g = RDF::Graph.new()

  observation = "obs_#{id}"    # obs_12345657
  species = "species_#{species}"  # species_3456789
  $stderr.puts "#{count} #{observation} #{species}"
  triplify(my["#{observation}#obs"], rdf.type, sio.measuring, g)
  triplify(my["#{observation}#obs"], rdfs.label, comments, g)
  triplify(my["#{observation}#obs"], sio["is-located-in"], wiki[countryC], g)
  triplify(my["#{observation}#obs"], sio["measured-at"], my["#{observation}#time"], g)
  triplify(my["#{observation}#obs"], sio["has-participant"], my["#{observation}#infection"], g)
  
  triplify(my["#{observation}#location"], sio["is-location-of"], my["#{observation}#obs"], g)
  triplify(my["#{observation}#location"], rdf.type, geo.Point, g)
  triplify(my["#{observation}#location"], geo.lat, lat, g)
  triplify(my["#{observation}#location"], geo.long, long, g)

  triplify(wiki[countryC], rdf.type, sio.country, g)
  triplify(wiki[countryC], rdfs.label, countryN, g)

  triplify(my["#{observation}#time"], rdf.type, sio["time-interval"], g)
  triplify(my["#{observation}#time"], sio["has-value"], duration, g)
  triplify(my["#{observation}#time"], sio["has-unit"], uo["UO_0000036"], g)
  triplify(uo["UO_0000036"], rdfs.label, "Year", g)
  
  triplify(my["#{observation}#infection"], rdf.type, efo["EFO_0001067"], g)
  triplify(efo["EFO_0001067"], rdfs.label, "Parasitic Infection", g)
  triplify(my["#{observation}#infection"], sio["has-participant"], my["#{species}#species"], g)
  triplify(my["#{observation}#infection"], sio["has-participant"], food[cropC], g)
  
  triplify(food[cropC], rdfs.label, cropN, g)
  triplify(food[cropC], rdf.type, sio.host, g)

  triplify(my["#{species}#species"], rdf.type, sio.pathogen, g)

  new_observation = top.add_rdf_resource(:slug => observation)  
  new_observation.add_metadata(g.map {|s| [s.subject.to_s, s.predicate.to_s, s.object.to_s]}) 
 
end





