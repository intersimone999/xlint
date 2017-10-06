require "zip"
require "nokogiri"


module SCORM
    class XMLNavigator
        def initialize(content)
            @doc = Nokogiri::Slop(content).remove_namespaces!
        end
        
        def navigate
            return @doc
        end
    end
    
    class Template < XMLNavigator
    end

    class Manifest < XMLNavigator
    end
    
    class Package
        MANIFEST_PATH = "imsmanifest.xml"
        TEMPLATE_PATH = "template.xml"
        def initialize(path)
            @path = path
        end
        
        def manifest
            Zip::File.open(@path) do |zip_file|
                entry = zip_file.glob(MANIFEST_PATH).first
                return Manifest.new entry.get_input_stream.read
            end
        end
        
        def template
            Zip::File.open(@path) do |zip_file|
                entry = zip_file.glob(TEMPLATE_PATH).first
                return Template.new entry.get_input_stream.read
            end
        end
    end
    
    class LintReport
        def initialize
            reset!
        end
        
        def reset!
            @status = {}
            
            @warnings = {}
            @errors = {}
        end
        
        def notify(checker)
            @status[checker] = :OK
            @warnings[checker] = []
            @errors[checker] = []
        end
        
        def warning(checker, string)
            @warnings[checker].push string
            @status[checker] = :WARNING unless @status[checker] == :ERROR
        end
        
        def error(checker, string)
            @errors[checker].push string
            @status[checker] = :ERROR
        end
        
        def print_report
            @status.each do |checker, final_status|
                puts "#{checker.name} status: #{final_status.to_s}"
                
                @errors[checker].each do |s|
                    puts "\tERROR: #{s}"
                end
                
                @warnings[checker].each do |s|
                    puts "\tWARNING: #{s}"
                end
            end
        end
        
        def status
            result = :OK
            @status.each do |checker, status|
                result = :WARNING if status == :WARNING && result != :ERROR
                result = :ERROR if status == :ERROR
            end
            
            return result
        end
    end
    
    class Lint
        def initialize(package)
            @package = package
            @rule_checkers = []
        end
        
        def add_checker(checker)
            @rule_checkers.push checker
        end
        
        def check
            report = LintReport.new
            @rule_checkers.each do |checker|
                checker._check @package, report
            end
            
            return report
        end
    end
    
    module Checkers
        class Checker
            attr_reader     :name
            attr_reader     :description
            def initialize(name, description)
                @name = name
                @description = description
            end
            
            def _check(package, report)
                @report = report
                @report.notify self
                check_manifest package.manifest
                check_template package.template
            end
            
            def error!(string)
                @report.error self, string
            end
            
            def warning!(string)
                @report.warning self, string
            end
            
            def check_manifest(manifest)
            end
            
            def check_template(template)
            end
            
            def debug o
                puts "DEBUG: #{o.inspect}"
            end
        end
    end
end

class XerteLint
    def initialize(target)
        @package = SCORM::Package.new target
        @lint = SCORM::Lint.new @package
    end
    
    def load_checkers
        enabled = File.read "#{File.dirname(__FILE__)}/checkers/checkers.txt"
        enabled.split("\n").each do |checker_string|
            klass, parameters_array = checker_string.split(":")
            parameters = parameters_array ? parameters_array.split(",") : []
            
            require_relative "checkers/#{klass}.rb"
            checker = eval("SCORM::Checkers::#{klass}.new *parameters")
            @lint.add_checker checker
            
            puts "Loaded \"#{checker.name}\""
        end
    end
    
    def check
        report = @lint.check
        report.print_report
        
        stat = 0
        case report.status
        when :OK
            puts "Check completed (0 errors, 0 warnings)"
        when :WARNING
            puts "Check completed with warnings (0 errors)"
        when :ERROR
            puts "Check completed with errors"
        end
        
        exit stat
    end
end


main = XerteLint.new(ARGV[0])
main.load_checkers
main.check
