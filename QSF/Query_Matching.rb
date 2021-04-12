=begin
_:ABC a <subject_type>
_:ABC some:predicate _:123
_:123 a <object_type>
=end
def fake_data_generator(subject_type, predicate, object_type)
    data = "_:ABC a <#{subject_type}>\n_:ABC #{predicate} _:123\n_:123 a <#{object_type}>"
    return data
end
