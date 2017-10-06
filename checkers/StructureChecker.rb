module SCORM::Checkers
    class StructureChecker < Checker
        def initialize
            super "SCORM structure checker", "Checks the structure of the LO (names of the elements)"
        end
        
        def check_manifest(manifest)
            
        end
        
        def check_template(template)
            elements = template.navigate.learningObject.elements
            
            error! "The first element must be a title page!" unless elements[0].name == "title"
            error! "The second element must be a connector menu!" unless elements[1].name == "connectorMenu"
            warning! "The last element should be a glossary" unless elements[-1].name == "accNav"
            
            for i in 2...elements.size-1
                title = elements[i].xpath("@name").first.content
                error! "Invalid title `#{title}`. Should be in the form #.#." unless title.match /^[0-9]+\.[0-9]+ .*/
            end
        end
    end
end
