require "./Query_Matching.rb"

test = fake_data_generator("http://swisslipids.org/rdf#Protein", "http://swisslipids.org/rdf#taxon", "http://swisslipids.org/rdf#NCBI_Taxonomy_Term", "fake_data.ttl")

test2 = shacl_validator("fake_data.ttl", "output_test.ttl")


print test2.count

#if test2.all_results.length > 0 #The length of the all_results attribute is 0 if there is no match and >0 when there is a match
    