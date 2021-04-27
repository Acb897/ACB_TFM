=begin
_:ABC a <subject_type>
_:ABC some:predicate _:123
_:123 a <object_type>
=end

require 'linkeddata'
require 'shacl'

# Generates mock RDF data to be validated against SHACL shapes.
#
# @param subject_type [String] the full URI of the rdf:type of the subject of the triple.
# @param predicate [String] the full URI of the predicate of the triple.
# @param object_type [String] the full URI of the rdf:type of the object of the triple.
# @param output_document [String] the name of the document that will contain the mock data.
# @return [data] the fake data.
def fake_data_generator(subject_type, predicate, object_type, output_document)
    data = "_:ABC a <#{subject_type}> . \n_:ABC <#{predicate}> _:123 . \n_:123 a <#{object_type}> ."
    File.open(output_document, "w") {|file|
        file.write data}
    return data
end

# Uses the SHACL and linkeddata gems to validate the fake data against a database of SHACL shapes.
#
# @param rdf_graph [String] the name of the document that contains the mock RDF data.
# @param shacl_document [String] the name of the document with the SHACL shapes.
# @return [report] the report of the validation. Check SHACL::ValidationReport from the SHACL gem.
def shacl_validator(rdf_graph, shacl_document)
    graph = RDF::Graph.load(rdf_graph)
    shacl = SHACL.open(shacl_document)
    report = shacl.execute(graph)
    return report
end