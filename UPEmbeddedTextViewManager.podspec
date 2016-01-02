#
# Be sure to run `pod lib lint UPEmbeddedTextViewManager.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# Any lines starting with a # are optional, but encouraged
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "UPEmbeddedTextViewManager"
  s.version          = "0.1.1"
  s.summary          = "Convenience tool for employing UITextView instances embedded in table views."
  s.description      = <<-DESC
                       Enables scrolling and selection amongst other characteristics, to behave somewhat like the Notes section in the Contacts app (while editing a contact)

                       * Markdown format.
                       * Don't worry about the indent, we strip it!
                       DESC
  s.homepage         = "https://github.com/AdrianaPineda/UPEmbeddedTextViewManager"
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'MIT'
  s.author           = { "Martin Uribe & Adriana Pineda" => "a@a.com"}
  s.source           = { :git => "https://github.com/AdrianaPineda/UPEmbeddedTextViewManager.git", :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/adrianapinedag'

  s.platform     = :ios, '8.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes/**/*'
  s.resource_bundles = {
    'UPEmbeddedTextViewManager' => ['Pod/Assets/*.png']
  }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
