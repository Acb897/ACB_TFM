=begin
Questions:
    - If I try to set the limit of the queries to more than 10, I get an error that says that there were too many connection resets due to Net::ReadTimeout
    - I'm not sure how to check if the SPO patterns already exist. Is it possible to ask if there is an object with certain concrete attributes (the same Subject,
      predicate and object)?
    - In the way that I'm doing the parsing of the triplestore, I can't think of any scenario where a loop or duplication happens, even with inverse relationships.
      I must be missing something.
    - When the objects of the triples have no type, what should I record in the pattern? The kind of data it is (int, string, float etc)?
    - I get an error saying that there is an Invalid return in line 65: /home/osboxes/Course/ACB_TFM/SPO_pattern_class.rb:65: Invalid return in class/module body (SyntaxError)
        return result   
    - I also get an error saying that there was an unexpected keyword_end in line 116: /home/osboxes/Course/ACB_TFM/SPO_pattern_class.rb:116: syntax error, unexpected keyword_end, expecting end-of-input
=end

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
            #Recordatorio para poner el OPTIONAL en el ?object_type
            query = <<END
        
            SELECT DISTINCT(?predicate ?object_type)
            WHERE {
                ?subject a <#{type}>.
                ?subject ?predicate ?object . 
                ?object a ?object_type.
            } limit 10
END
            result = sparql.query(query)

        elsif mode == "fixed_object"
            query = <<END
        
            SELECT DISTINCT(?predicate ?subject_type)
            WHERE {
                ?object a <#{type}>.
                ?subject ?predicate ?object . 
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
                #Recordatorio para poner la comprobacion de si solution tiene un :object o un :object_type, y crear el objeto con lo que tengan
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