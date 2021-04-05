require "./SPO_pattern_class.rb"


engine = Engine.new()

first_test = engine.extract_patterns("https://rdf.metanetx.org/sparql")
#first_test = engine.extract_patterns("http://sparql.uniprot.org/sparql")
shacl_test = engine.shacl_generator(first_test, "output_test.ttl")

