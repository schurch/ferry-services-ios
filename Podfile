platform :ios, '8.0'
use_frameworks!

target 'FerryServices_2' do
	pod 'SwiftyJSON'
    pod 'Parse'
end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['SWIFT_VERSION'] = '3.0'
            config.build_settings['MACOSX_DEPLOYMENT_TARGET'] = '10.10'
        end
    end
end
