Pod::Spec.new do |s|
  s.name             = 'XTIWebView'
  s.version          = '1.0'
  s.summary          = 'XTIWebView'

  s.description      = <<-DESC
  TODO:
                       DESC

  s.homepage         = 'https://github.com/xtinput/XTIWebView'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'xt-input' => 'input@tcoding.cn' }
  s.source           = { :git => 'https://github.com/xtinput/XTIWebView.git', :tag => s.version.to_s }

  s.ios.deployment_target = '10.0'

  s.source_files = 'Source/*.swift'
  s.resources = 'Resources/*'

  s.swift_version = '5'
  s.requires_arc  = true

  s.dependency 'XTILoger'
  
end
