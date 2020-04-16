
Pod::Spec.new do |s|
  s.name             = 'Peasy'
  s.version          = '1.1.0'
  s.summary          = 'Easy peasy Swift mock server for embedding directly into UI tests.'

  s.description      = <<-DESC
Easy peasy Swift mock server for embedding directly into UI tests.
                       DESC

  s.homepage         = 'https://github.com/kanecheshire/Peasy'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'kanecheshire' => '@kanecheshire' }
  s.source           = { :git => 'https://github.com/kanecheshire/Peasy.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/kanecheshire'

  s.ios.deployment_target = '8.0'
  s.watchos.deployment_target = '2.0'
  s.macos.deployment_target = '10.10'
  s.tvos.deployment_target = '9.0'
  s.swift_version = '5.0'

  s.source_files = 'Sources/Peasy/**/*'
end
