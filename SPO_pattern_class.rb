require "sparql/client"

class SPO
    attr_accessor :SPO_Subject
    attr_accessor :SPO_Predicate
    attr_accessor :SPO_Object

    def initialize (params = {})
        @SPO_Subject = params.fetch(:SPO_Subject, "")
        @SPO_Predicate = params.fetch(:SPO_Predicate, "")
        @SPO_Object = params.fetch(:SPO_Object, "")
    end
    
        sparql = SPARQL::Client.new(endpoint_URL)
        if mode == "exploratory"
            #This first query asks for the types of objects inside the triplestore
            query = <<END

            SELECT DISTINCT(?type)
            WHERE {
                   ?subject a ?type .
            } limit 10
END
            result = sparql.query(query)
        
        elsif mode == "fixed_subject"
            query = <<END
        
            SELECT ?predicate ?object_type
            WHERE {
                <#{type}> ?predicate ?object . 
                ?object a ?object_type.
            } limit 10
END
            result = sparql.query(query)

        elsif mode == "fixed_object"
            query = <<END
        
            SELECT ?predicate ?subject_type
            WHERE {
                ?subject ?predicate <#{type}> . 
                ?subject a ?subject_type.
            } limit 10
END
            result = sparql.query(query)
        end
        return result        
    end

    def SPO.extract_patterns(endpoint_URL)
        @patterns = Hash.new
        
        types_array = Array.new

        exploration_results = SPO.query_endpoint(endpoint_URL, "exploratory")
        
        #The types are stored in an array so that they can be later explored individually in order
        exploration_results.each do |solution|
            if types_array.include? solution[:type]
                next
            else
                types_array << solution[:type]
            end
        end
        
        #puts types_array
        
        types_array.each do |type|
        
            #This query asks for the types of objects and the predicates that interact with each of the types
            fsubject_results = SPO.query_endpoint(endpoint_URL, "fixed_subject")
            fsubject_results.each do |solution|
                if @patterns.include? type
                    @patterns[type] << SPO.new(
                        :SPO_Subject => type,
                        :SPO_Predicate => solution[:predicate],
                        :SPO_Object => solution[:object_type]
                    )
                else
                    @patterns[type] = [SPO.new(
                        :SPO_Subject => type,
                        :SPO_Predicate => solution[:predicate],
                        :SPO_Object => solution[:object_type]
                    )]
                end
            end
            fobject_results = SPO.query_endpoint(endpoint_URL, "fixed_object")
            fobject_results.each do |solution|
                #falta comprobacion de que no tenga ya ese pattern
                @patterns[type] << SPO.new(
                    :SPO_Subject => solution[:subject_type],
                    :SPO_Predicate => solution[:predicate],
                    :SPO_Object => type
                )
            end
        end
        return @patterns          
    end
end