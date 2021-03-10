require "./SPO_pattern_class.rb"


engine = Engine.new()

#first_test = engine.extract_patterns("https://rdf.metanetx.org/sparql")
first_test = engine.extract_patterns("http://sparql.uniprot.org/sparql")

print first_test