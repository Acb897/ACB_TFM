require "./SPO_pattern_class.rb"
require "./Query_Matching_class.rb"

engine = Engine.new()

endpoint = ["https://rdf.metanetx.org/sparql", "http://fairdata.systems:7777/sparql", "http://fairdata.systems:7778/sparql"]

rdf_index = engine.extract_patterns(endpoint)
shacl_index_gen = engine.shacl_generator(rdf_index, "index.txt", "create")


fake_data_gen = fake_data_generator("https://rdf.metanetx.org/schema/CPLX", "https://rdf.metanetx.org/schema/subu", "https://rdf.metanetx.org/schema/PEPT", "fake_data1.ttl")

validator = shacl_validator("fake_data1.ttl", "index.txt")


# print validator.all_results

#if test2.all_results.length > 0 #The length of the all_results attribute is 0 if there is no match and >0 when there is a match