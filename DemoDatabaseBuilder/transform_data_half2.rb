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
	:endpoint => "http://fairdata.systems:7778/DAV/home/TFM/Half2/",
	:username => "half2",
	:password => "half2"})
top = client.toplevel_container
 
my =   RDF::Vocabulary.new("http://tfm.exampledata.org/TFM/Alberto/")

spe = File.open("SpeciesInfoPub2015.tsv")
spe.readline # discard header

count = 0
spe.each do |line|
  (species, gbif, name) = line.split("\t")
  next if gbif.empty? or name.empty? or species.empty?
  species = "species_#{species}"  # species_3456789
  count += 1
  break if count > 700
  $stderr.puts "#{count} #{species} SPECIES TABLE"

  g = RDF::Graph.new()
  triplify(my["#{species}#species"], rdf.type, sio.pathogen, g)
  triplify(my["#{species}#species"], rdfs.label, name, g)
  triplify(my["#{species}#species"], sio["has-identifier"], lsid[gbif], g)
  triplify(my["#{species}#species"], rdf.type, sio.pathogen, g)
  triplify(lsid["#{gbif}"], rdfs.label, name, g)
  triplify(lsid["#{gbif}"], rdf.type, sio.identifier, g)

  new_species = top.add_rdf_resource(:slug => species)
  new_species.add_metadata(g.map {|s| [s.subject.to_s, s.predicate.to_s, s.object.to_s]}) 
 

end





