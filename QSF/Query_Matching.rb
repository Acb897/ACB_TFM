=begin
_:ABC a <subject_type>
_:ABC some:predicate _:123
_:123 a <object_type>
=end

require 'linkeddata'
require 'shacl'

def fake_data_generator(subject_type, predicate, object_type, output_document)
    data = "_:ABC a <#{subject_type}>. \n_:ABC #{predicate} _:123. \n_:123 a <#{object_type}>"
    File.open(output_document, "w") {|file|
        file.write data}
    return data
end

def shacl_validator(rdf_graph, shacl_document)
    graph = RDF::Graph.load(rdf_graph)
    shacl = SHACL.open(shacl_document)
    report = shacl.execute(graph)
    puts report

end