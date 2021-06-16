require 'linkeddata'
require 'shacl'
require 'sparql'
require 'uri'

# Generates mock RDF data to be validated against SHACL shapes.
#
# @param query [String] the query.
# @param output_document [String] the name of the document that will contain the mock data.
# @return [file] the fake data in turtle format.
def fake_data_generator(query, output_document)
    ############
    #  Removed this, as it is not necessary
    ############
    #uris_hash = Hash.new
    #uris_hash.default_proc = proc {|k| k}
    #File.foreach(query_document_location) {|line|
    #    case line
    #        when /^PREFIX (\w+:) (<.+)>/i #if the line starts with PREFIX, find the prefix and its full URI and store them in a hash
    #            uris_hash[$1] = $2
    #            
    #        when /^SELECT|CONSTRUCT|ASK|DESCRIBE/i #This line corresponds to the first line of the final query
    #            query = line
    #        when /(^\n|})/
    #            query << line
    #        else 
    #            uris_hash.each { |k, v| 
    #            line[k] &&= v } #changes all occurances of a prefix with the full URI
    #            line.match(/(<\S+)/)
    #            line[$1] &&= $1.concat(">")
    #            line.gsub!(/\ba\b/, "<http://www.w3.org/1999/02/22-rdf-syntax-ns#type>") #changes "a" with the whole URI of rdf:type
    #            query << line
    #    end
    #}
    
    $stderr.puts query
    parsed = SPARQL.parse(query)  # this is a nightmare method, that returns a wide variety of things! LOL!
    
    rdf_query=''
    if parsed.is_a?(RDF::Query)  # we need to get the RDF:Query object out of the list of things returned from the parse
        rdf_query = parsed
    else
        parsed.each {|c| rdf_query = c if c.is_a?(RDF::Query)  }
    end

    patterns = rdf_query.patterns  # returns the triple patterns in the query

    variables = Hash.new  # we're going to create a random string for every variable in the query
    patterns.each do |p|  
        vars = p.unbound_variables  # vars contains e.g. [:s, #<RDF::Query::Variable:0x6a400(?s)>] 
        vars.each {|var| variables[var[0]] = RDF::URI("http://fakedata.org/" + (0...10).map { ('a'..'z').to_a[rand(26)] }.join)}
        # now variables[:s] = <http://fakedata.org/adjdsihfrke>
    end

    File.open(output_document, "w") {|file|
        #now iterate over the patterns again, and bind them to their new value
        patterns.each do |triple|  # we're going to create a random string for every variable
            if triple.subject.variable?
                var_symbol = triple.subject.to_sym # covert the variable into a symbol, since that is our hash key
                triple.subject = variables[var_symbol]  # assign the random string for that symbol
            end

            if triple.predicate.variable?
                var_symbol = triple.predicate.to_sym # covert the variable into a symbol, since that is our hash key
                triple.predicate = variables[var_symbol]  # assign the random string for that symbol
            end
            
            # special case for objects, since they can be literals
            if triple.object.variable?
                var_symbol = triple.object.to_sym # covert the variable into a symbol, since that is our hash key
                triple.object = variables[var_symbol]  # assign the random string for that symbol
                file.write triple.to_rdf
                file.write "\n"
                ########
                #  What will you do with triples that have a literal as their value, rather than a <URI>?
                ########
            else  # this ensures that it is written even if the object is not a variable
                file.write triple.to_rdf
                file.write "\n"
            end
        end
    }

end

# Uses the SHACL and linkeddata gems to validate the fake data against a database of SHACL shapes.
#
# @param rdf_graph [String] the name of the document that contains the mock RDF data.
# @param shacl_document [String] the name of the document with the SHACL shapes.
# @return [responsive_endpoints] an array containing the responsive endpoints' URLs.
def shacl_validator(rdf_graph, shacl_document)
    shacl_shapes = Hash.new
    responsive_endpoints = Array.new
    graph = RDF::Graph.load(rdf_graph)
    File.foreach(shacl_document) {|line|
        case line
            when /^EU/
                @endpoint_url = line.match("^EU\t(.+)\n")[1]
            when /^SH/
                content = line.match("^SH\t(.+\n)")[1]
                if shacl_shapes.include? @endpoint_url
                    shacl_shapes[@endpoint_url] << content
                else
                    shacl_shapes[@endpoint_url] = content
                end
            when /^XX/
                next
        end
    }   
    #This splits the value of the hash, which corresponds to all the shapes from an
    # endpoint one after another in a string. The split is made on the ] . that
    # delimits the end of a shape, and with ?<= it is kept in the shapes.
    shacl_shapes.update(shacl_shapes) {|key, value| value.split(/(?<=\] \.)\n/)}
    shacl_shapes.each do |key, value|
        value.each do |shape|
            File.open("tmp.ttl", "w") {|file|
            file.write "@prefix sh: <http://www.w3.org/ns/shacl#> .\n\n"
            file.write shape
            }
            shacl = SHACL.open("tmp.ttl")
            report = shacl.execute(graph)
            
            puts "SHAPE:\n\n#{shape}\n\nConforms?: #{report.conform?}\n\nLength: #{report.all_results.length}"
            puts puts
            puts report
            puts puts
            if report.conform? && report.all_results.length > 0
                responsive_endpoints << key
                break
            else 
                next
            end
        end
    end
    return responsive_endpoints
end