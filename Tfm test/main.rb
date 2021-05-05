#Basically the question here is that I don't understand why some SPOs conform and others don't, and the reason for some of the different outputs I get. I think 
#that the main problem is whatever I did wrong that is causing the "message: "is of class http://www.w3.org/1999/02/22-rdf-syntax-ns#nil" and message: "is not of class http://www.w3.org/1999/02/22-rdf-syntax-ns#nil"
require "./Query_Matching.rb"

#If I do the same I did in the first example, but with a database that only contains the Protein shape from swisslipids, I get different results!
puts
puts "==============================================================="
puts "Validating the reduced SHACL database against Metanetx REAC data"

test = fake_data_generator("https://rdf.metanetx.org/schema/REAC", "https://rdf.metanetx.org/schema/reacXref", "http://swisslipids.org/rdf#DbReference", "fake_data.ttl")

test2 = shacl_validator("fake_data.ttl", "reduced_database.ttl")

puts "Does this data conform to the SHACL shapes?: #{test2.conform?}"
puts puts
puts "Showing all (#{test2.all_results.length}) results (conforming and non-conforming)"
puts
puts test2.all_results

#Now, doing the same as before but changing the subject so it doesn't match. It validates, but there aren't any results.
puts
puts "==============================================================="
puts "Validating the reduced SHACL database against Metanetx REAC data, but with a different subject"

test = fake_data_generator("https://rdf.metanetx.org/schema/REACa", "https://rdf.metanetx.org/schema/reacXref", "http://swisslipids.org/rdf#DbReference", "fake_data.ttl")

test2 = shacl_validator("fake_data.ttl", "reduced_database.ttl")

puts "Does this data conform to the SHACL shapes?: #{test2.conform?}"
puts puts
puts "Showing all (#{test2.all_results.length}) results (conforming and non-conforming)"
puts
puts test2.all_results

#Now changing the predicate so it doesn't match, and the subject and object DO match.
puts
puts "==============================================================="
puts "Validating the reduced SHACL database against Metanetx REAC data, but with a different predicate"

test = fake_data_generator("https://rdf.metanetx.org/schema/REAC", "https://rdf.metanetx.org/schema/reacXrefa", "http://swisslipids.org/rdf#DbReference", "fake_data.ttl")

test2 = shacl_validator("fake_data.ttl", "reduced_database.ttl")

puts "Does this data conform to the SHACL shapes?: #{test2.conform?}"
puts puts
puts "Showing all (#{test2.all_results.length}) results (conforming and non-conforming)"
puts
puts test2.all_results

#Now changing the object so it doesn't match, and the subject and predicate DO match.
puts
puts "==============================================================="
puts "Validating the reduced SHACL database against Metanetx REAC data, but with a different object"

test = fake_data_generator("https://rdf.metanetx.org/schema/REAC", "https://rdf.metanetx.org/schema/reacXref", "http://swisslipids.org/rdf#DbReferencea", "fake_data.ttl")

test2 = shacl_validator("fake_data.ttl", "reduced_database.ttl")

puts "Does this data conform to the SHACL shapes?: #{test2.conform?}"
puts puts
puts "Showing all (#{test2.all_results.length}) results (conforming and non-conforming)"
puts
puts test2.all_results

#Now changing both the S and P so that they don't match.
puts
puts "==============================================================="
puts "Validating the reduced SHACL database against Metanetx REAC data, but with both Subject and Predicate not matching"

test = fake_data_generator("https://rdf.metanetx.org/schema/REACa", "https://rdf.metanetx.org/schema/reacXrefa", "http://swisslipids.org/rdf#DbReference", "fake_data.ttl")

test2 = shacl_validator("fake_data.ttl", "reduced_database.ttl")

puts "Does this data conform to the SHACL shapes?: #{test2.conform?}"
puts puts
puts "Showing all (#{test2.all_results.length}) results (conforming and non-conforming)"
puts
puts test2.all_results

puts
puts "Basically, if all three parts of the triple match the shape, the shacl::ValidationReport .conform? returns true and the amount of results is >0.
If some of the parts doesn't match the shape, this no longer holds true"

puts "=============================================================================================="
puts "                          Testing with the whole shapes database  "
puts "=============================================================================================="
puts
puts "==============================================================="
puts "Validating the complete SHACL database against Metanetx REAC data"

test = fake_data_generator("https://rdf.metanetx.org/schema/REAC", "https://rdf.metanetx.org/schema/reacXref", "http://swisslipids.org/rdf#DbReference", "fake_data.ttl")

test2 = shacl_validator("fake_data.ttl", "Old_shacl_database.ttl")

puts "Does this data conform to the SHACL shapes?: #{test2.conform?}"
puts puts
puts "Showing all (#{test2.all_results.length}) results (conforming and non-conforming)"
puts
puts test2.all_results

#Now, doing the same as before but changing the subject so it doesn't match. It validates, but there aren't any results.
puts
puts "==============================================================="
puts "Validating the complete SHACL database against Metanetx REAC data, but with a different subject"

test = fake_data_generator("https://rdf.metanetx.org/schema/REACa", "https://rdf.metanetx.org/schema/reacXref", "http://swisslipids.org/rdf#DbReference", "fake_data.ttl")

test2 = shacl_validator("fake_data.ttl", "Old_shacl_database.ttl")

puts "Does this data conform to the SHACL shapes?: #{test2.conform?}"
puts puts
puts "Showing all (#{test2.all_results.length}) results (conforming and non-conforming)"
puts
puts test2.all_results

#Now changing the predicate so it doesn't match, and the subject and object DO match.
puts
puts "==============================================================="
puts "Validating the complete SHACL database against Metanetx REAC data, but with a different predicate"

test = fake_data_generator("https://rdf.metanetx.org/schema/REAC", "https://rdf.metanetx.org/schema/reacXrefa", "http://swisslipids.org/rdf#DbReference", "fake_data.ttl")

test2 = shacl_validator("fake_data.ttl", "Old_shacl_database.ttl")

puts "Does this data conform to the SHACL shapes?: #{test2.conform?}"
puts puts
puts "Showing all (#{test2.all_results.length}) results (conforming and non-conforming)"
puts
puts test2.all_results

#Now changing the object so it doesn't match, and the subject and predicate DO match.
puts
puts "==============================================================="
puts "Validating the complete SHACL database against Metanetx REAC data, but with a different object"

test = fake_data_generator("https://rdf.metanetx.org/schema/REAC", "https://rdf.metanetx.org/schema/reacXref", "http://swisslipids.org/rdf#DbReferencea", "fake_data.ttl")

test2 = shacl_validator("fake_data.ttl", "Old_shacl_database.ttl")

puts "Does this data conform to the SHACL shapes?: #{test2.conform?}"
puts puts
puts "Showing all (#{test2.all_results.length}) results (conforming and non-conforming)"
puts
puts test2.all_results

#Now changing both the S and P so that they don't match.
puts
puts "==============================================================="
puts "Validating the complete SHACL database against Metanetx REAC data, but with both Subject and Predicate not matching"

test = fake_data_generator("https://rdf.metanetx.org/schema/REACa", "https://rdf.metanetx.org/schema/reacXrefa", "http://swisslipids.org/rdf#DbReference", "fake_data.ttl")

test2 = shacl_validator("fake_data.ttl", "Old_shacl_database.ttl")

puts "Does this data conform to the SHACL shapes?: #{test2.conform?}"
puts puts
puts "Showing all (#{test2.all_results.length}) results (conforming and non-conforming)"
puts
puts test2.all_results

puts "In this case, the data never conforms to the shapes because of the problem you told me, but only when all parts of the triple match the shape we get 2 results.
These results are much more 'shaky', and I still don't understand them"