#
# Be sure to run `pod lib lint UPEmbeddedTextViewM2.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "UPEmbeddedTextViewM2"
  s.version          = "0.1.0"
  s.summary          = "Convenience tool for employing UITextView instances embedded in table views."

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!  
  s.description      = <<-DESC
                        Enables scrolling and selection amongst other characteristics, to behave somewhat like the Notes section in the Contacts app (while editing a contact)
                       DESC

  s.homepage         = "https://github.com/mugby99/UPEmbeddedTextView"
  s.license          = 'MIT'
  s.author           = { "Martin Uribe & Adriana Pineda" => "am.pineda206@uniandes.edu.co" }
  s.source           = { :git => "https://github.com/mugby99/UPEmbeddedTextView.git", :tag => s.version.to_s }

  s.platform     = :ios, '8.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes/**/*'
  s.resource_bundles = {
    'UPEmbeddedTextViewM2' => ['Pod/Assets/*.png']
  }

end
