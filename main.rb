require "./SPO_pattern_class.rb"

#first_test = SPO.extract_patterns("http://sparql.uniprot.org/sparql")

engine = Engine.new()

first_test = engine.extract_patterns("https://rdf.metanetx.org/sparql")

print first_test