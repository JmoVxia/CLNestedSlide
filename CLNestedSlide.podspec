Pod::Spec.new do |s|
  s.name             = 'CLNestedSlide'
  s.version          = '1.0.1'
  s.summary          = '高性能、易用的 iOS 嵌套滑动视图库，支持头部、悬停、分页内容和横竖屏适配。'
  s.description      = <<-DESC
    CLNestedSlide 是一个专为 iOS 设计的嵌套滑动视图库，支持头部视图、悬停视图、横向分页内容，自动协调多手势和横竖屏，适合复杂页面结构的高性能实现。
  DESC
  s.homepage         = 'https://github.com/JmoVxia/CLNestedSlide'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'JmoVxia' => 'JmoVxia@gmail.com' }
  s.source           = { :git => 'https://github.com/JmoVxia/CLNestedSlide.git', :tag => s.version.to_s }
  s.source_files     = 'CLNestedSlide/CLNestedSlideView/**/*.{swift}'
  s.ios.deployment_target = '13.0'
  s.swift_version    = '5.0'
end
