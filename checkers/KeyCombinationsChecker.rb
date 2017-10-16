module SCORM::Checkers
    ORTHODOX = ["Ctrl", "Alt", "Canc"]
    class KeyCombinationsChecker < Checker
        def initialize
            super "Key combinations checker", "Checks that key combinations follow specific guidelines"
        end
        
        def check_manifest(manifest)
            
        end
        
        def check_template(template)
            elements = template.navigate.learningObject.elements
            
            elements.each do |element|
                text = element.to_s
                
                ORTHODOX.each do |orthodox|
                    error! "Unorthodox modifier combination #{orthodox}" if text.match(/\b(?<!\<em\>)#{orthodox}[^A-Za-z]/)
                    numberOfModifiers = text.scan(/([^A-Za-z]|^)#{orthodox}([^A-Za-z]|$)/).size
                    numberOfCorrects  = text.scan(/\<em\>#{orthodox}\<\/em\>(\+\<em\>.{1,10}<\/em\>)*/).size
                    
                    warning! "There are (#{numberOfModifiers - numberOfCorrects}) strange key combination in element #{elements.index(element) + 1} `#{element.path}`"  if numberOfCorrects != numberOfModifiers
                end
            end
        end
    end
end
