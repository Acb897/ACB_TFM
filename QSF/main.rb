require "./Query_Matching.rb"

test = fake_data_generator("http://swisslipids.org/rdf#Protein", "http://swisslipids.org/rdf#taxon", "http://swisslipids.org/rdf#NCBI_Taxonomy_Term", "fake_data.ttl")

test2 = shacl_validator("fake_data.ttl", "output_test.ttl")

puts test2

