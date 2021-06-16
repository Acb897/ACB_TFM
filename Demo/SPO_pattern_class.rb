=begin
Another thing I think will be useful is to find the URL patterns for each ?s and ?o
(or at least, the most common ones... so maybe grab 10 examples of ?s and ?o and see
what their URLs look like.  e.g.  http://purl.uniprot.org/P344556.)  The reason this may
become useful is that EBI has agreed to resurrect a really useful service they used to have
that finds synonyms for URLs. If we know the pattern, we might be able to do even more
query expansion.
=end
require "sparql/client"
require "digest"

# == SPO
#
# This class stores the Subject, Predicate and Object (SPO) of any RDF triple data.
#
# == Summary
# This class stores the components of triples.
#
class SPO

    # Get/Set the Subject of the triple.
    # @!attribute [rw]
    # @return [String] The Subject.
    attr_accessor :SPO_Subject

    # Get/Set the Predicate of the triple.
    # @!attribute [rw]
    # @return [String] The Predicate.
    attr_accessor :SPO_Predicate

    # Get/Set the Object of the triple.
    # @!attribute [rw]
    # @return [String] The Object.
    attr_accessor :SPO_Object

    # Creates a new instance of SPO pattern.
    #
    # @param SPO_Subject [String] the complete URI of the Subject of the SPO pattern.
    # @param SPO_Predicate [String] the complete URI of the Predicate of the SPO pattern.
    # @param SPO_Object [String] the complete URI of the Object of the SPO pattern.
    # @return [SPO] an instance of SPO.
    def initialize(params = {})
        @SPO_Subject = params.fetch(:SPO_Subject, "")
        @SPO_Predicate = params.fetch(:SPO_Predicate, "")
        @SPO_Object = params.fetch(:SPO_Object, "")
    end
end

# == Engine
#
# This class handles all the endpoint indexing operations.
#
# == Summary
#
# Class that handles the indexing.
#
class Engine

    # Get/Set the hash of Subject-Predicate-Object (SPO) patterns.
    # @!attribute [rw]
    # @return [Hash] the patterns hash.
    attr_accessor :hashed_patterns

    # Get/Set the Array of SPO patterns.
    # @!attribute [rw]
    # @return [Array] the patterns array.
    attr_accessor :patterns

    # Creates a new instance of Engine.
    #
    # @param hashed_patterns [Hash] the hash of SPO patterns.
    # @param patterns [Array] the array of SPO patterns.
    # @return [Engine] an instance of Engine.
    def initialize(params = {})
        @hashed_patterns = []
        @patterns = []
    end

    # Checks whether or not a triple has already been added to the SPO patterns hash. 
    #
    # @param s [] the Subject of the triple.
    # @param p [] the Predicate of the triple.
    # @param o [] the Object of the triple.
    # @return [Boolean] True if the pattern already exists in the database and False if it does not.
    def in_database?(s,p,o)
        pattern_digest = Digest::SHA2.hexdigest s.to_s+p.to_s+o.to_s
        if hashed_patterns.include? pattern_digest
            return true
        else
            hashed_patterns << pattern_digest
            return false
        end
    end
    
    # Adds the SPO pattern to the database as an instance of the SPO class.
    #
    # @type [String] the rdf:type of the Subject.
    # @param s [] the Subject of the triple.
    # @param p [] the Predicate of the triple.
    # @param o [] the Object of the triple.
    # @return [SPO] an instance of SPO.
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
    
    # Queries an endpoint to get information for its indexing.
    #
    # @param endpoint_URL [String] the URL of the SPARQL endpoint to be queried. 
    # @param mode [String] There are three modes:
    #
    # * exploratory: queries the endpoint to get the rdf:types of all typed subjects inside of it.
    # * fixed_subject: given a subject type (rdf:type), queries the endpoint to get all the object types linked to it type and their corresponding predicates.
    # * fixed_object: given an object type, queries the endpoint to get all the subject types linked to it and their corresponding predicates.
    # @param type [String] The rdf:type of the subject or object for the fixed_subject and fixed_object modes.
    # @return [result] The result of the query.
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
            query = <<END
        
            SELECT DISTINCT ?predicate ?object_type
            WHERE {
                ?subject a <#{type}>.
                ?subject ?predicate ?object . 
                OPTIONAL{?object a ?object_type}.
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
                OPTIONAL{?subject a ?subject_type}.
            } limit 10
END
            $stderr.puts "query is:\n#{query}\n\n"
            result = sparql.query(query)
        end
        
        return result        
    end


    # Uses the query_endpoint method to get all the SPO patterns present in an endpoint, creating an index.
    #
    # @param endpoint_URL [String] the URL of the SPARQL endpoint to be indexed.
    # @return [patterns] A hash containing all the SPO patterns as SPO instances.
    def extract_patterns(endpoint_URLs_array)
        abort "the input must be an array of endpoint URLs" unless endpoint_URLs_array.is_a?(Array)
        @endpoint_patterns = Hash.new
        endpoint_URLs_array.each do |endpoint_URL|
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
                    
            types_array.each do |type|
                        
                #This query asks for the types of objects and the predicates that interact with each of the types
                fsubject_results = query_endpoint(endpoint_URL, "fixed_subject", type)
                fsubject_results.each do |solution|
                    next if solution[:object_type] =~ /rdf-schema/
                    next if solution[:object_type] =~ /owl\#Ontology/
                    
                    # do a quick lookup to see if we already know this pattern
                    next if in_database?(type,solution[:predicate],solution[:object_type]) # this will add it to teh database if it is not known
                    add_triple_pattern(type, type, solution[:predicate], solution[:object_type])
                    
                end
                fobject_results = query_endpoint(endpoint_URL, "fixed_object", type)
                fobject_results.each do |solution|
                    # do a quick lookup to see if we already know this pattern
                    next if in_database?(solution[:subject_type],solution[:predicate],type) # this will add it to teh database if it is not known
                    add_triple_pattern(type, solution[:subject_type],solution[:predicate], type)
                end
            end
            @endpoint_patterns[endpoint_URL] = @patterns
        end
        return @endpoint_patterns        
    end

    #Generates SHACL shapes corresponding to all the patterns from an endpoint and writes them to a file in turtle format.
    #
    # @param patterns_hash [Hash] The hash containing all the triple patterns from an endpoint as instances of SPO.
    # @param output_file [String] The name of the output file that will contain all the SHACL shapes. It is recommended to use .ttl as its extension.
    # @return [File] A file containing the SHACL shapes corresponding to all the SPO patterns given as input.
    def shacl_generator(patterns_hash, output_file, mode)
        if mode.downcase == "create"
            file_mode = "w"
        elsif mode.downcase == "append"
            file_mode = "a"
        else 
            abort "The mode should be 'create' or 'append'"
        end
        File.open(output_file, file_mode) {|file|
            patterns_hash.each do |url, patterns|
                new_patterns_hash = Hash.new
                file.write "XX\nXX\nEU\t#{url}\nXX\n"
                patterns.each do |key, value|
                    value.each do |pattern|
                        if new_patterns_hash.include? pattern.SPO_Subject.to_s
                            new_patterns_hash[pattern.SPO_Subject.to_s] << pattern
                        else 
                            new_patterns_hash[pattern.SPO_Subject.to_s] = [pattern]
                        end
                    end
                end
                new_patterns_hash.each do |key, value|
                    counter = 0
                    puts "Processing #{key}'s shape"
                    shape_intro = "SH\t<#{key}Shape>\nSH\t\ta sh:NodeShape ;\nSH\t\tsh:targetClass <#{key}> ;\n"
                    file.write shape_intro
                    value.each do |pattern|
                        if key == pattern.SPO_Subject
                            counter += 1
                            numero = value.select{|a| a.SPO_Subject == pattern.SPO_Subject}.length()
                            if counter == value.select{|a| a.SPO_Subject == pattern.SPO_Subject}.length()
                                if pattern.SPO_Object.nil?

                                    final_property_text = "SH\t\tsh:property [\nSH\t\t\tsh:path <#{pattern.SPO_Predicate}> ;\nSH\t\t] .\nXX\n"
                                    file.write final_property_text
                                else
                                    final_property_text = "SH\t\tsh:property [\nSH\t\t\tsh:path <#{pattern.SPO_Predicate}> ;\nSH\t\t\tsh:class <#{pattern.SPO_Object}> ;\nSH\t\t] .\nXX\n"
                                    file.write final_property_text
                                end
                            else
                                if pattern.SPO_Object.nil?

                                    property_text = "SH\t\tsh:property [\nSH\t\t\tsh:path <#{pattern.SPO_Predicate}> ;\nSH\t\t] ;\n"
                                    file.write property_text
                                else
                                    property_text = "SH\t\tsh:property [\nSH\t\t\tsh:path <#{pattern.SPO_Predicate}> ;\nSH\t\t\tsh:class <#{pattern.SPO_Object}> ;\nSH\t\t] ;\n"
                                    file.write property_text
                                end
                            end
                        end
                    end 
                end
            end
        } 
    end
end
