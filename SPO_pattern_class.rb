=begin
Questions:
- I need some help with the query that asks for the object type. Since it is hard to come across an example of a triple whose object doesn't have a rdf:type, but a
    datatype (for example xsd:string), I'm not sure how to make the part of the query that asks for the object type optional and also make it ask for the datatype
    of the object in those cases. My idea on how to handle those cases is to add a new attribute to the SPO class called SPO_ObjDatatype. Then, in the shacl_generator
    function check if the pattern has a value for SPO_ObjDatatype to create the correct shape.
- Please, read the comment that is just above the shacl_generation function.
- Are the SHACL shapes generated in the output_test.txt document correct?
=end


=begin

select ?stype ?p ?otype where {
 ?s a ?stype .
 ?s ?p ?o .
 OPTIONAL{?o a ?otype} .
}

Another thing I think will be useful is to find the URL patterns for each ?s and ?o
(or at least, the most common ones... so maybe grab 10 examples of ?s and ?o and see
what their URLs look like.  e.g.  http://purl.uniprot.org/P344556.)  The reason this may
become useful is that EBI has agreed to resurrect a really useful service they used to have
that finds synonyms for URLs. If we know the pattern, we might be able to do even more
query expansion.

I can't say for sure if the SHACL is correct, however, you can test it by running it through a SHACL validator
(google for an online one) or a SHACL parser.  You can also use SELECT * {.....} LIMIT 10  to collect some RDF that
(in principle) should validate against that SHACL.  That would prove that the SHACL is correct

=end
require "sparql/client"
require "digest"

class SPO
    attr_accessor :SPO_Subject
    attr_accessor :SPO_Predicate
    attr_accessor :SPO_Object

    def initialize(params = {})
        @SPO_Subject = params.fetch(:SPO_Subject, "")
        @SPO_Predicate = params.fetch(:SPO_Predicate, "")
        @SPO_Object = params.fetch(:SPO_Object, "")
    end
end

class Engine
    attr_accessor :hashed_patterns
    attr_accessor :patterns

    def initialize(params = {})
        @hashed_patterns = []
        @patterns = []
    end
    def in_database?(s,p,o)
        pattern_digest = Digest::SHA2.hexdigest s.to_s+p.to_s+o.to_s
        if hashed_patterns.include? pattern_digest
            return true
        else
            hashed_patterns << pattern_digest
            return false
        end
    end
        
    def add_triple_pattern(type, s,p,o)
        if @patterns.include? type
            @patterns[type] << SPO.new(
                :SPO_Subject => s,
                :SPO_Predicate => p,
                :SPO_Object => o
            )
        else
            @patterns[type] = [SPO.new(
                :SPO_Subject => s,
                :SPO_Predicate => p,
                :SPO_Object => o
            )]
        end
    end
    
    def query_endpoint(endpoint_URL, mode = "exploratory", type = "")
        abort "must provide a type in any mode other than exploratory" if mode != "exploratory" and type.to_s.empty?
        sparql = SPARQL::Client.new(endpoint_URL, {method: :get})
        if mode == "exploratory"
            #This first query asks for the types of objects inside the triplestore
            query = <<END
SELECT DISTINCT ?type
WHERE {
    ?subject a ?type .
}
END
            result = sparql.query(query)
        
        elsif mode == "fixed_subject"
            #Recordatorio para poner el OPTIONAL en el ?object_type
            query = <<END
        
            SELECT DISTINCT ?predicate ?object_type
            WHERE {
                ?subject a <#{type}>.
                ?subject ?predicate ?object . 
                ?object a ?object_type.
            } limit 10
END
            $stderr.puts "query is:\n#{query}\n\n"
            result = sparql.query(query)

        elsif mode == "fixed_object"
            query = <<END
        
            SELECT DISTINCT ?predicate ?subject_type 
            WHERE {
                ?object a <#{type}>.
                ?subject ?predicate ?object . 
                ?subject a ?subject_type.
            } limit 10
END
            $stderr.puts "query is:\n#{query}\n\n"
            result = sparql.query(query)
        end
        
        return result        
    end

    def extract_patterns(endpoint_URL)
        @patterns = Hash.new
        
        types_array = Array.new

        exploration_results = query_endpoint(endpoint_URL, "exploratory")
        $stderr.puts exploration_results.length.to_s + " types found"
        #The types are stored in an array so that they can be later explored individually in order
        exploration_results.each do |solution|
            next if solution[:type].to_s =~ /openlink/
            next if solution[:type].to_s =~ /w3\.org/
            
            if types_array.include? solution[:type].to_s  # necessary because the ruby object wont be the same object, even if the content is the same
                next
            else
                types_array << solution[:type].to_s
            end
        end
        
        #puts types_array
        
        types_array.each do |type|
                    
            #This query asks for the types of objects and the predicates that interact with each of the types
            fsubject_results = query_endpoint(endpoint_URL, "fixed_subject", type)
            fsubject_results.each do |solution|
                next if solution[:object_type] =~ /rdf-schema/
                next if solution[:object_type] =~ /owl\#Ontology/
                
                #Recordatorio para poner la comprobacion de si solution tiene un :object o un :object_type, y crear el objeto con lo que tengan
                # do a quick lookup to see if we already know this pattern
                next if in_database?(type,solution[:predicate],solution[:object_type]) # this will add it to teh database if it is not known
                add_triple_pattern(type, type, solution[:predicate], solution[:object_type])
                
            end
            fobject_results = query_endpoint(endpoint_URL, "fixed_object", type)
            fobject_results.each do |solution|
                # do a quick lookup to see if we already know this pattern
                next if in_database?(solution[:subject_type],solution[:predicate],type) # this will add it to teh database if it is not known
                #falta comprobacion de que no tenga ya ese pattern
                add_triple_pattern(type, solution[:subject_type],solution[:predicate], type)
            end
        end
        return @patterns          
    end

    
=begin
The problem here is that because of the way we ask for the patterns for each type, there are cases like the following;

"http://swisslipids.org/rdf#HasSourceComponent"=>[#<SPO:0x00005607262994f0 
@SPO_Subject="http://swisslipids.org/rdf#HasSourceComponent", 
@SPO_Predicate=#<RDF::URI:0x2b039314cec4 URI:http://www.w3.org/1999/02/22-rdf-syntax-ns#type>, 
@SPO_Object=#<RDF::URI:0x2b039314cdfc URI:http://www.w3.org/2002/07/owl#Class>>, 

#<SPO:0x00005607262992c0 
@SPO_Subject="http://swisslipids.org/rdf#HasSourceComponent", 
@SPO_Predicate=#<RDF::URI:0x2b039314cce4 URI:http://swisslipids.org/rdf#metabolite>, 
@SPO_Object=#<RDF::URI:0x2b039314cc08 URI:http://swisslipids.org/rdf#Metabolite>>, 

#<SPO:0x0000560726258f40 
@SPO_Subject=#<RDF::URI:0x2b039312c91c URI:http://swisslipids.org/rdf#Metabolite>, 
@SPO_Predicate=#<RDF::URI:0x2b039312cad4 URI:http://swisslipids.org/rdf#annotation>, 
@SPO_Object="http://swisslipids.org/rdf#HasSourceComponent">]

Where we have, in the same value corresponding to one key of the hash, patterns that start with different predicates (in this case the 3rd SPO object has 
http://swisslipids.org/rdf#Metabolite as subject, and the other two have http://swisslipids.org/rdf#HasSourceComponent). This causes some of those patterns
that don't match the subject of the others to appear multiple times in the SHACL shapes.

I tried to solve this by creating a new patterns hash with all those patterns whose subject doesn't match the others, but I can't get it to work
=end    

=begin

Sorry, I don't understand the question.

=end

    def shacl_generator(patterns_hash, output_file)
        
        new_patterns_hash = Hash.new
        File.open(output_file, "w") {|file|
            patterns_hash.each do |key, value|
                #puts "Processing #{key}'s shape"
                shape_intro = "<#{key}_SHAPE>\n\ta sh:NodeShape ;\n\tsh:targetClass <#{key}> ;\n"
                file.write shape_intro
                value.each do |pattern|
                    
                    if key == pattern.SPO_Subject
                        property_text = "\tsh:property [\n\t\tsh:path <#{pattern.SPO_Predicate}> ;\n\t\tsh:class <#{pattern.SPO_Object}> ;\n\t] ;\n"
                        file.write property_text
                    else
                        #This is the part I can't get to work. 
                        puts pattern.SPO_Subject
                        new_patterns_hash[pattern.SPO_Subject] = pattern
                        print new_patterns_hash
                        puts puts
                    end
                end
            end

            # This repeats the code from the previous part because I was trying to see where the problem could be. Also, wouldn't this be a great opportunity to use
            # recursiveness?

            # new_patterns_hash.each do |key, value|
            #     puts "Processing #{key}'s shape"
            #     shape_intro = "<#{key}_SHAPE>\n\ta sh:NodeShape ;\n\tsh:targetClass <#{key}> ;\n"
            #     file.write shape_intro
            #     value.each do |pattern|
            #         puts "\tProcessing #{pattern.SPO_Subject}, #{pattern.SPO_Predicate}, #{pattern.SPO_Object}"
            #         if key == pattern.SPO_Subject
            #             property_text = "\tsh:property [\n\t\tsh:path <#{pattern.SPO_Predicate}> ;\n\t\tsh:class <#{pattern.SPO_Object}> ;\n\t] ;\n"
            #             file.write property_text
            #         else 
            #             new_patterns_hash[pattern.SPO_Subject] = pattern
            #         end
            #     end
            # end
        }
    end
        
end
