require 'sparql'


class SPARQLTransform
    attr_accessor :sparql

  
  def initialize(args = {sparql: ""})
    @sparql = args.fetch(:sparql)
    
  end
  
  def transform
    begin
      parsed = SPARQL.parse(@sparql)  # this is a nightmare method, that returns a wide variety of things! LOL!
    rescue => e
      $stderr.puts e.to_s
      return false
    end
    
    select = false
    distinct = false
    vars = ""
    prefixes = Array.new
    rdf_query=''
    
    if parsed.is_a?(RDF::Query)  # we need to get the RDF:Query object out of the list of things returned from the parse
      rdf_query = parsed
    else
      parsed.each do |c|
        rdf_query = c if c.is_a?(RDF::Query)
        select = true if c.is_a? SPARQL::Algebra::Operator::Project
        distinct = true if c.is_a? SPARQL::Algebra::Operator::Project
        vars += " #{c.to_s}" if c.is_a? RDF::Query::Variable
        next if c.is_a? Array and c.first.is_a? RDF::Query::Variable
        prefixes << c if (c.is_a? Array and !(c.first.is_a? Array))
      end
    end
    
    qs = ""
    prefixes.each {|e| qs += "PREFIX #{e[0].to_s} <#{e[1].to_s}>\n"}
    if select
      qs += "SELECT "
    else
      qs += "SELECT *"
    end
    
    qs += "DISTINCT " if distinct
    qs += vars
    qs += " WHERE { \n"
    
    patterns = rdf_query.patterns  # returns the triple patterns in the query
    
    patterns.each do |pattern|
      pat = RDF::Query::Pattern.new(pattern.subject, pattern.predicate, pattern.object, {optional: true}).to_s
      if pat =~ /^OPTIONAL(.*)/
        pat = "OPTIONAL {#{$1}}"
      end
      qs += "#{pat}\n"
    end
    qs += "}"
    
    return qs
    
  end

end
