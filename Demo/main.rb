require "./SPO_pattern_class.rb"
require "./Query_Matching_class.rb"

engine = Engine.new()

endpoint = "https://rdf.metanetx.org/sparql"
#endpoint = "http://sparql.uniprot.org/sparql"
rdf_index = engine.extract_patterns(endpoint)
shacl_index_gen = engine.shacl_generator(rdf_index, "metanetx.ttl")
#shacl_index_gen = engine.shacl_generator(rdf_index, "Uniprot.ttl")

# fake_data_gen = fake_data_generator("https://rdf.metanetx.org/schema/CPLX", "https://rdf.metanetx.org/schema/subu", "https://rdf.metanetx.org/schema/PEPT", "fake_data1.ttl")

# validator = shacl_validator("fake_data1.ttl", "metanetx.ttl")


# print validator.all_results

#if test2.all_results.length > 0 #The length of the all_results attribute is 0 if there is no match and >0 when there is a match