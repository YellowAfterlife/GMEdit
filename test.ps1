haxelib run munit gen
haxe ./tests/test.hxml
#Start-Process "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe" -ArgumentList "http://localhost:3000 -incognito -auto-open-devtools-for-tabs"
Start-Process "http://localhost:3000"
Push-Location ./tests/unittest_node/
node ./index.js
Pop-Location