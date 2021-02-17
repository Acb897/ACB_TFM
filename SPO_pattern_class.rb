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
    
    def SPO.query_endpoint(endpoint_URL)
        @patterns = Hash.new
        endpoint = endpoint_URL
        query = <<END

        SELECT DISTINCT(?type)
        WHERE {
               ?subject a ?type .
        } limit 10
END
        
        
        sparql = SPARQL::Client.new(endpoint)  # create a SPARQL client
        result = sparql.query(query)  # Execute query
        types_array = Array.new
        result.each do |solution|
            if types_array.include? solution[:type]
                next
            else
                types_array << solution[:type]
            end
        end
        
        #puts types_array
        
        types_array.each do |type|
        
            #puts "Type: #{type}"
            query = <<END
        
            SELECT ?predicate ?object_type
            WHERE {
                <#{type}> ?predicate ?object . 
                ?object a ?object_type.
            } limit 10
END
        
            result = sparql.query(query)
            result.each do |solution|
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
        end           
    end
end