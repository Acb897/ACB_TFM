#Basically the question here is that I don't understand why some SPOs conform and others don't, and the reason for some of the different outputs I get. I think 
#that the main problem is whatever I did wrong that is causing the "message: "is of class http://www.w3.org/1999/02/22-rdf-syntax-ns#nil" and message: "is not of class http://www.w3.org/1999/02/22-rdf-syntax-ns#nil"
require "./Query_Matching.rb"

#This is the first example I used, which works correctly. It creates fake RDF data, stores it in a document called fake_data.ttl
puts "==============================================================="
puts "Validating the SHACL database against Swisslipids protein data"
test = fake_data_generator("http://swisslipids.org/rdf#Protein", "http://swisslipids.org/rdf#taxon", "http://swisslipids.org/rdf#NCBI_Taxonomy_Term", "fake_data.ttl")

#Then, it validates the fake data against the shacl database. test2 is a ValidationReport instance from the shacl gem, and by using .all_results it returns all results
#, both conforming and non-conforming. As you can see in the output, this example doesn't conform to the RDF data. Do you understand why it says "is not of class http://www.w3.org/1999/02/22-rdf-syntax-ns#nil"
test2 = shacl_validator("fake_data.ttl", "Old_shacl_database.ttl")

puts "Does this data conform to the SHACL shapes?:"
puts test2.conform?
puts puts
puts test2.all_results



#Now, when I try to do the same as above but with the subject, predicate and object having Metanext URIs, it conforms, but because it says that "is of class http://www.w3.org/1999/02/22-rdf-syntax-ns#nil"
puts
puts "==============================================================="
puts "Validating the same SHACL database against metanext reaction data"
test = fake_data_generator("https://rdf.metanetx.org/schema/REAC", "https://rdf.metanetx.org/schema/right", "https://rdf.metanetx.org/schema/PART", "fake_data.ttl")
    
test2 = shacl_validator("fake_data.ttl", "Old_shacl_database.ttl")

puts "Does this data conform to the SHACL shapes?:"
puts test2.conform?
puts puts
puts test2.all_results



#If I use a triple that has swisslipids data mixed with metanetx data, the results are different.
puts 
puts "==============================================================="
puts "Validating the same SHACL database against metanetx and swisslipid data"
test = fake_data_generator("https://rdf.metanetx.org/schema/REAC", "https://rdf.metanetx.org/schema/reacXref", "http://swisslipids.org/rdf#DbReference", "fake_data.ttl")
test2 = shacl_validator("fake_data.ttl", "Old_shacl_database.ttl")

puts "Does this data conform to the SHACL shapes?:"
puts test2.conform?
puts puts
puts test2.all_results



#If I do the same I did in the first example, but with a database that only contains the Protein shape from swisslipids, I get different results!
puts
puts "==============================================================="
puts "Validating the reduced SHACL database against Swisslipids protein data"
test = fake_data_generator("http://swisslipids.org/rdf#Protein", "http://swisslipids.org/rdf#taxon", "http://swisslipids.org/rdf#NCBI_Taxonomy_Term", "fake_data.ttl")

test2 = shacl_validator("fake_data.ttl", "perro2.ttl")

puts "Does this data conform to the SHACL shapes?:"
puts test2.conform?
puts puts
puts test2.all_results

