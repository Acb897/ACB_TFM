require "./SPO_pattern_class.rb"


engine = Engine.new()

endpoint = "https://rdf.metanetx.org/sparql"
#endpoint = "http://sparql.uniprot.org/sparql"
first_test = engine.extract_patterns(endpoint)
#first_test = engine.extract_patterns("http://sparql.uniprot.org/sparql")
shacl_test = engine.shacl_generator(first_test, "test.ttl")

