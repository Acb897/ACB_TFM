require "./SPO_pattern_class.rb"
require "./Query_Matching_class.rb"

# ======================================================
#                 First section: Indexing              #
# ======================================================
engine = Engine.new()

# Array of endpoints to be indexed
endpoints = ["https://rdf.metanetx.org/sparql", "http://fairdata.systems:7777/sparql", "http://fairdata.systems:7778/sparql"]

# The following lines perform the indexing and transformation to SHACL
rdf_index = engine.extract_patterns(endpoints)
shacl_index_gen = engine.shacl_generator(rdf_index, "index.txt", "create")


# ======================================================
#                 Second section: Querying             #
# ======================================================
query = <<END
PREFIX so: <http://purl.org/ontology/symbolic-music/>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX sio: <http://semanticscience.org/resource/>
select ?host ?patho ?name ?lsid where {
    ?s a sio:measuring .
    ?s sio:has-participant ?part .
    ?part a <http://www.ebi.ac.uk/efo/efo.owl#EFO_0001067> .
    ?part sio:has-participant ?patho .
    ?part sio:has-participant ?host .
    ?host a sio:host .
    ?patho a sio:pathogen .
    ?patho rdfs:label ?name .
    ?patho sio:has-identifier ?lsid .
    ?lsid a sio:identifier .
}

END

# ======================================================
#             Third section: Source Selection          #
# ======================================================

# The following lines create fake RDF data matching the query
puts "Generating mock RDF data to validate"
fake_data_gen = fake_data_generator(query, "RDF_data.ttl")

# The following lines use SHACL validation to find endpoints that are responsive to the query
responsive_endpoints = shacl_validator("RDF_data.ttl", "index.txt")
p responsive_endpoints
