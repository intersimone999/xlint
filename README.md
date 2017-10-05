# xlint
An extendible linter that checks learning objects created with Xerte and exported as SCORM packages.

## Configure and run
If you do not have `bundler`, install it with `gem install bundler`. Then, just run `bundle install` in the folder with xlint.
This will install all the required dependencies. To configure xlint, you can modify the file `checkers/checkers.txt`. This
file contains, in each row, the class of the checker and optional parameters needed. For example:
```
TestChecker1
TestChecker2
TestChecker3:a,b,c
XMLChecker:text.xml
```
This configuration activates the checkers `TestChecker1` and `TestChecker2` with no parameter, 
`TestChecker3` with three parameters and XMLChecker with just a parameter. To separate the checker name and the parameters,
use `:`; to separate the parameters, use `,`. Note that all parameters will be interpreted as strings.

To launch xlint, just run:
```bash
ruby xlint.rb $package_file
```

## Extending xlint
It is possible to design 
rules specific to a course to automate the quality control of learning objects. You can define new rules in two ways:
- Creating a new checker
- Creating a new XML rule

### Checkers
A checker is a class that can check both the manifest and the template of a Xerte SCORM package. Each checker belongs to the
module SCORM::Checkers and it must extend the class Checker. This is an example:

```ruby
module SCORM::Checkers
    class TestChecker < Checker
        def initialize
            super "Checker name", "Checker detailed description"
        end
        
        def check_manifest(manifest)
            # Checks the manifest
        end
        
        def check_template(template)
            # Checks the template
            error! "No editor version" if manifest.navigate.xpath("learningObject/@editorVersion").size == 0
        end
    end
end
```
The methods `check_manifest` and `check_template` allow to check the manifest and the template of the package, respectively.
It is possible to raise warnings or errors calling the methods "warning!" or "error!", with a message.

The checker file must have the same name of the class. For example, the checker `TestChecker` must be contained in a script
named `TestChecker.rb`. All the checkers must be placed in the folder `checkers`. To activate the checker, add a row in
the file `checkers/checkers.txt`. The parameters will be passed to the `initialize` method.

## XML rules
A simpler way check a property of the learning objects is by creating XML rules. An XML rule has the following shape:
```xml
<rule>
    <title>Properties checker</title>
    <descr>Checks the title and other basic properties of the learning objects (like theme and so on)</descr>
    
    <manifest>
        <error>
            <what>manifest//organizations//organization/title</what>
            <match>^[0-9]+\. .*</match>
            <message>The title of the LO must start with the number of the module (e.g., "1. Name")</message>
        </error>
    </manifest>
    
    <template>
        <error>
            <what>learningObject/@name</what>
            <match>^[0-9]+\. .*</match>
            <message>The title of the LO must start with the number of the module (e.g., "1. Name")</message>
        </error>
        
        <warning>
            <what>learningObject/title</what>
            <match>.*[^0-9].*</match>
            <message>The title should not containt numbers.</message>
        </warning>
    </template>
</rule>
```

Besides `title` and `descr`, there are two main nodes in the file, that indicate the scope of the check: `manifest` and
`template`. Each of these can contain an `error` or a `warning` node. Both these nodes have the same structure. They must
have:
- `what`: an xpath query of the element(s) that has/have to be checked;
- `match`: the regular expression that must be matched by the element(s) found with the xpath query;
- `message`: a message to show when the rule is violated.

To activate a new XML rule, add to the file `checkers/checkers.txt` the following line:
```XMLChecker:$rulename.xml```
Where `$rulename` is the name of the rule. All the XML rules must be placed in the folder `rules`.
