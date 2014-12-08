Pod::Spec.new do |s|

  s.name         = "JSONMarshaller"
  s.version      = "0.2.0"
  s.summary      = "Marshalling JSON to NSManagedObject and vice versa."

  s.description  = <<-DESC
                   A simple way to parse JSON to NSManagedObject and observe changes.
                   DESC

  s.homepage     = "http://nerdgeschoss.de"

  s.license      = 'MIT'

  s.author             = { "Jens Ravens" => "jens@nerdgeschoss.de" }

  s.platform     = :ios, '7.0'

  s.source       = { :git => "https://github.com/nerdgeschoss/JSONMarshaller.git", :tag => "v0.2.0" }

  s.source_files  = 'Lib'

  s.requires_arc = true

end
