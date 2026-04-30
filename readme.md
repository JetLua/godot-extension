```bash
# for simulator
xcodebuild -scheme one -sdk iphonesimulator -configuration Release archive -archivePath one.xcarchive
xcodebuild -create-xcframework -framework one.framework -framework sim/one.framework -output one.xcframework
```
