Pod::Spec.new do |s|

  s.name                = "SlidableSheet"
  s.version             = "1.1.0"
  s.summary             = "SlidableSheet is a simple and easy-to-use UI component of a slidable sheet interface"
  s.description         = <<-DESC
SlidableSheet is a simple and easy-to-use UI component for a new interface introduced in Apple Maps, Shortcuts and Stocks app.
The new interface displays the related contents and utilities in parallel as a user wants.
                   DESC
  s.homepage            = "https://github.com/tuan23/swift-slideable-sheet"
  # s.screenshots       = ""

  s.platform            = :ios, "10.0"
  s.source              = { :git => "https://github.com/tuan23/swift-slidable-sheet.git", :tag => "v#{s.version}" }
  s.source_files        = "Framework/Sources/*.swift"
  s.swift_version       = "4.2"
  s.pod_target_xcconfig = { 'SWIFT_WHOLE_MODULE_OPTIMIZATION' => 'YES', 'APPLICATION_EXTENSION_API_ONLY' => 'YES' }

  s.framework           = "UIKit"

  s.author              = { "Tuan Hoang" => "h.t.ttuan@gmail.com" }
  s.license             = { :type => "MIT", :file => "LICENSE" }
  s.social_media_url    = "https://twitter.com/tuan23"
end
