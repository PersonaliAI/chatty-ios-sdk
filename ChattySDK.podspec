Pod::Spec.new do |s|
  s.name             = "ChattySDK"
  s.version          = "1.0.1"
  s.summary          = "Official iOS SDK for Chatty AI chatbots — native SwiftUI, no WebView."
  s.description      = <<-DESC
    Native SwiftUI chat UI for Chatty. Talks directly to the same
    /api/widget/* backend as the Chatty web widget and renders every
    bubble, avatar, and composer with real SwiftUI views — no WebView,
    no JS bridge. Automatically matches whichever of the 10 Chatty
    widget designs is selected for the bot in the dashboard.
  DESC
  s.homepage         = "https://github.com/Damayantha/chatty-ios-sdk"
  s.license          = { :type => "MIT", :file => "LICENSE" }
  s.author           = { "Damayantha" => "damayanthakat@gmail.com" }
  s.source           = { :git => "https://github.com/Damayantha/chatty-ios-sdk.git", :tag => "v#{s.version}" }

  s.ios.deployment_target = "15.0"
  s.osx.deployment_target = "13.0"
  s.swift_version    = "5.7"

  s.source_files     = "Sources/ChattySDK/**/*.swift"
  s.frameworks       = "SwiftUI", "PhotosUI"
end
