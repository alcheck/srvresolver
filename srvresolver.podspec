
Pod::Spec.new do |spec|

  spec.name         = "srvresolver"
  spec.version      = "1.0.0"
  spec.summary      = "DNS SRV query resolver"

  spec.description  = <<-DESC
  The pod helps you to query DNS service for SRV records and get all the SRV records.
                   DESC

  spec.homepage     = "https://github.com/alcheck/srvresolver"

  spec.license      = "MIT"

  spec.author             = { "Alexey Chechetkin" => "alexey@talkme.im" }

  #spec.platform     = :ios
  #spec.platform     = :ios, "12.1"

  #  When using multiple platforms
  spec.ios.deployment_target = "12.1"
  spec.osx.deployment_target = "10.15"
  # spec.watchos.deployment_target = "2.0"
  # spec.tvos.deployment_target = "9.0"

  spec.source       = { :git => "https://github.com/alcheck/srvresolver.git", :tag => "#{spec.version}" }

  spec.source_files  = "sources/**/*.{h,m}"
  spec.private_header_files = "sources/*Private.h"
  
  spec.exclude_files = ["sources/*.modulemap", "sources/srvresolver.h"]
 
  # spec.framework  = "SomeFramework"
  # spec.frameworks = "SomeFramework", "AnotherFramework"

  #spec.module_map = "sources/module.modulemap"
  #spec.module_name = "srvresolver"
  #spec.preserve_path = "sources/module.modulemap"
  
  spec.static_framework = true
  spec.library   = "resolv"
  # spec.libraries = "iconv", "xml2"

  # ――― Project Settings ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  If your library depends on compiler flags you can set them in the xcconfig hash
  #  where they will only apply to your library. If you depend on other Podspecs
  #  you can include multiple dependencies to ensure it works.

  # spec.requires_arc = true

  # spec.xcconfig = { "HEADER_SEARCH_PATHS" => "$(SDKROOT)/usr/include/libxml2" }
  # spec.dependency "JSONKit", "~> 1.4"

end
