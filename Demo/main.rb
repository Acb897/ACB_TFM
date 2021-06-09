require "./SPO_pattern_class.rb"
require "./Query_Matching_class.rb"

engine = Engine.new()

endpoint = ["https://rdf.metanetx.org/sparql", "http://fairdata.systems:7777/sparql", "http://fairdata.systems:7778/sparql"]

rdf_index = engine.extract_patterns(endpoint)
shacl_index_gen = engine.shacl_generator(rdf_index, "index.txt", "create")


query = <<END
PREFIX so: <http://purl.org/ontology/symbolic-music/>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX sio: <http://semanticscience.org/resource/>
select ?host ?patho ?name ?lsid where {
    ?s a sio:measuring .
    ?s sio:has-participant ?part .
    ?part a <http://www.ebi.ac.uk/efo/efo.owl#EFO_0001067> .
    ?part sio:has-participant ?patho .
    ?part sio:has-participant ?host .
    ?host a sio:host .
    ?patho a sio:pathogen .
    ?patho rdfs:label ?name .
    ?patho sio:has-identifier ?lsid .
    ?lsid a sio:identifier .
}

END

puts "Generating mock RDF data to validate"
fake_data_gen = fake_data_generator(query, "RDF_data.ttl")
# fake_data_gen = fake_data_generator("example.sparql", "RDF_data.ttl")

validator = shacl_validator("RDF_data.ttl", "index.txt")
p validator
