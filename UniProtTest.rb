require 'sparql/client'

endpoint = "http://sparql.uniprot.org/sparql"  # what location are we querying?

query = <<END

SELECT ?type                           # note that ?name and ?image becomes the Ruby symbol :name and :image
WHERE {
       ?subject a ?type .
} limit 10
END



sparql = SPARQL::Client.new(endpoint)  # create a SPARQL client
result = sparql.query(query)  # Execute query
types_array = Array.new
result.each do |solution|
    #puts "Type: #{solution[:type]}"  # call the pairs of variables in our query
    #puts solution[:type]
    if types_array.include? solution[:type]
        next
    else
        types_array << solution[:type]
    end
end

puts types_array

types_array.each do |type|
    query = <<END

    SELECT ?predicate ?subject
    WHERE {
        #{type} ?predicate ?subject . 
    } limit 10
    END



    result = sparql.query(query)  # Execute query
end    