require 'sparql'
require 'uri'


def print_triple(triple)
  puts triple.to_rdf
  puts "\n\n"
end



query = <<END
PREFIX sio: <http://semanticscience.org/resource/>
select distinct ?id ?text ?response where { 
    ?patient sio:has-role ?patientrole .
    ?pseudonym sio:denotes ?patientrole .
    ?pseudonym sio:has-value ?id .
    ?patientrole sio:is-realized-in ?process .
    ?process sio:has-input ?question .
    ?question sio:has-value ?text .
    ?process sio:has-output ?answer .
    ?answer sio:has-value ?response .
	?patient sio:has-attribute ?attr .
    ?question sio:refers-to ?attr .
    ?attr a <http://purl.obolibrary.org/obo/NCIT_C25656>.
}

END

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

# now iterate over the patterns again, and bind them to their new value
patterns.each do |triple|  # we're going to create a random string for every variable
  if triple.subject.variable?
    var_symbol = triple.subject.to_sym # covert the variable into a symbol, since that is our hash key
    triple.subject = variables[var_symbol]  # assign the random URI for that symbol
  end

  if triple.predicate.variable?
    var_symbol = triple.predicate.to_sym # covert the variable into a symbol, since that is our hash key
    triple.predicate = variables[var_symbol]  # assign the random URI for that symbol
  end
  
  # special case for objects, since they can be literals
  if triple.object.variable?
    var_symbol = triple.object.to_sym # covert the variable into a symbol, since that is our hash key
    triple.object = variables[var_symbol]  # assign the random URI for that symbol
    print_triple(triple)
    
    triple.object = "abc"  # assign a nonsense string for that symbol
    print_triple(triple)
    
  end

end


