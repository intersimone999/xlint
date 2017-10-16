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
            
            after_memory = false
            for i in 0...elements.size
                if after_memory
                    navSetting = elements[i].xpath("@navSetting").first
                    navSetting = navSetting ? navSetting.value : nil
                    error! "The deepening pages should be back only! (#{navSetting} instead)" if !navSetting || navSetting != "backonly"
                end
                
                if elements[i].name == "memory"
                    navSetting = elements[i-1].xpath("@navSetting").first
                    navSetting = navSetting ? navSetting.value : nil
                    error! "The last visitable page (the one before memory) should be back only! (#{navSetting} instead)" if !navSetting || navSetting != "backonly"
                    after_memory = true
                end
            end
            
            for i in 2...elements.size-1
                title = elements[i].xpath("@name").first.content
                error! "Invalid title `#{title}`. Should be in the form #.#." unless title.match(/^[0-9]+\.[0-9]+ .*/) || title.match(/^[0-9]+\.[0-9]\&nbsp\;.*/) || elements[i].name == "memory"
            end
        end
    end
end
