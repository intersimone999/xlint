require "nokogiri"
require "pry"

module SCORM::Checkers
    class XMLChecker < Checker
        def initialize(file)
            @rule = Nokogiri::Slop(File.read("rules/"+file)).remove_namespaces!
            
            super @rule.rule.title.content, @rule.rule.descr.content
        end
        
        def check_manifest(manifest)
            @rule.rule.manifest.elements.each do |rule|
                generic_check(rule, manifest, "Manifest")
            end
        rescue NameError
            raise $! unless $!.message.include? "undefined method `manifest'"
        end
        
        def check_template(template)
            @rule.rule.template.elements.each do |rule|
                generic_check(rule, template, "Template")
            end
        rescue NameError
            raise $! unless $!.message.include? "undefined method `template'"
        end
        
        def generic_check(check, src, type)
            element = check.what.content
            regexp = Regexp.new(check.match)
            
            message = check.message.content
            
            src.navigate.xpath(element).each do |spotted|
                next unless spotted
                
                content = spotted.content
                if check.name == "error"
                    error! message + " IN #{type} [#{spotted.path}]." unless content.match(regexp)
                elsif check.name == "warning"
                    warning! message + " IN #{type} [#{spotted.path}]." unless content.match(regexp)
                else
                    raise "Invalid rule: #{check.name}"
                end
            end
        end
    end
end
