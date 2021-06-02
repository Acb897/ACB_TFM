require "./SPO_pattern_class.rb"
require "./Query_Matching_class.rb"

engine = Engine.new()

# endpoint = ["https://rdf.metanetx.org/sparql", "http://fairdata.systems:7777/sparql", "http://fairdata.systems:7778/sparql"]

# rdf_index = engine.extract_patterns(endpoint)
# shacl_index_gen = engine.shacl_generator(rdf_index, "index.txt", "create")


# query = <<END
# PREFIX sio: <http://semanticscience.org/resource/>
# select distinct ?id ?text ?response where { 
#     ?patient sio:has-role ?patientrole .
#     ?pseudonym sio:denotes ?patientrole .
#     ?pseudonym sio:has-value ?id .
#     ?patientrole sio:is-realized-in ?process .
#     ?process sio:has-input ?question .
#     ?question sio:has-value ?text .
#     ?process sio:has-output ?answer .
#     ?answer sio:has-value ?response .
# 	?patient sio:has-attribute ?attr .
#     ?question sio:refers-to ?attr .
#     ?attr a <http://purl.obolibrary.org/obo/NCIT_C25656>.
# }

# END
puts "Generating mock RDF data to validate"
fake_data_gen = fake_data_generator("example.sparql", "RDF_data.ttl")

# validator = shacl_validator("fake_data1.ttl", "index.txt")
# p validator
