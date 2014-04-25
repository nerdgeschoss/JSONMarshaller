Pod::Spec.new do |s|

  s.name         = "NGBMarshaller"
  s.version      = "0.1.0"
  s.summary      = "Marshalling JSON to NSManagedObject and vice versa."

  s.description  = <<-DESC
                   A simple way to parse JSON to NSManagedObject and observe changes.
                   DESC

  s.homepage     = "http://nerdgeschossberlin.de"

  s.license      = 'MIT'

  s.author             = { "Jens Ravens" => "jens@nerdgeschossberlin.de" }

  s.platform     = :ios, '7.0'

  s.source       = { :git => "git@gitlab.nerdgeschossberlin.de:mylane/jsonmarshaller.git", :tag => "0.1.0" }

  s.source_files  = 'Lib'

  s.requires_arc = true

end
