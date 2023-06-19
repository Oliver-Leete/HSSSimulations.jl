struct TFields <: DocStringExtensions.Abbreviation
    types::Bool
end

const TFIELDS = TFields(true)

function DocStringExtensions.format(abbrv::TFields, buf, doc)
    local docs = get(doc.data, :fields, Dict())
    local binding = doc.data[:binding]
    local object = Docs.resolve(binding)
    local fields = isabstracttype(object) ? Symbol[] : fieldnames(object)
    if !isempty(fields)
        println(buf)
        for field in fields
            print(buf, "  - `", field)
            abbrv.types && print(buf, "::", fieldtype(object, field))
            print(buf, "`")
            # Print the field docs if they exist and aren't a `doc"..."` docstring.
            if haskey(docs, field) && isa(docs[field], AbstractString)
                print(buf, ": ")
                indented = true
                for line in split(docs[field], "\n")
                    print(buf, indented || isempty(line) ? "" : "    ", rstrip(line))
                    indented = false
                end
            else
                println(buf)
            end
            println(buf)
        end
        println(buf)
    end
    return nothing
end
