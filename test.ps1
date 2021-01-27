# Generate the TestSuite
haxelib run munit gen

# Compile the haxe code
haxe ./tests/test.hxml

#If compile was unsuccessful exit here
if (-not ($?)) {
	$host.UI.RawUI.ForegroundColor = "Red"
	write-host "Haxe compilation unsuccessful. Press any key to continue..."
	[void][System.Console]::ReadKey($true)
	exit
}

#Start a web browser on the proper web address
Start-Process "http://localhost:3000"

#Move into node folder
Push-Location ./tests/unittest_node/

#If node modules are not present, install them
if (-not (Test-Path "node_modules")) {
	npm install
} 

#Start node
node ./index.js

#If node crashed give a warning
if (-not ($?)) {
	$host.UI.RawUI.ForegroundColor = "Red"
	write-host "Server was not started, is the port busy? Press any key to continue..."
	[void][System.Console]::ReadKey($true)
}

#Exit out of node folder
Pop-Location