const electron = require('electron')
// Module to control application life.
const app = electron.app
// Module to create native browser window.
const BrowserWindow = electron.BrowserWindow

const path = require('path')
const url = require('url')

// Keep a global reference of the window object, if you don't, the window will
// be closed automatically when the JavaScript object is garbage collected.
let activeWindows = []

function createWindow(first) {
	// Create the browser window.
	const showOnceReady = false
	let wnd = new BrowserWindow({
		width: 960,
		height: 720,
		frame: false,
		backgroundColor: "#889EC5",
		title: "GMEdit",
		webPreferences: {
			enableRemoteModule: true,
			nodeIntegration: true
		},
		show: !showOnceReady,
		icon: __dirname + '/favicon.' + (process.platform == "win32" ? "ico" : "png")
	})
	activeWindows.push(wnd)
	if (showOnceReady) {
		wnd.once('ready-to-show', () => wnd.show())
	}
	app.allowRendererProcessReuse = false;
	// https://github.com/electron/electron/issues/19789#issuecomment-559825012
	electron.protocol.interceptFileProtocol('file', (request, cb) => {
		//const show = request.url.includes("index")
		//if (show) console.log("in: " + request.url)
		let url = request.url.replace(/file:[/\\]*/, '')
		url = decodeURIComponent(url)
		//
		url = url.replace(/\/index-live\.html(?:\?.*?)?#live-(v[12]-(?:2d|GL)).*$/, '/livejs-$1.html')
		//
		let qmark = url.indexOf("?")
		if (qmark >= 0) url = url.substring(0, qmark)
		//if (show) console.log("out: " + url)
		cb(url)
	})

	// and load the index.html of the app.
	let index_url = url.format({
		pathname: path.join(__dirname, "index.html"),
		protocol: 'file:',
		slashes: true
	})
	
	if (first) {
		let args = process.argv
		let openArg = 1
		
		// https://apple.stackexchange.com/questions/207895/app-gets-in-commandline-parameter-psn-0-nnnnnn-why
		if (process.platform === 'darwin' && openArg < args.length && args[openArg].startsWith("-psn")) openArg += 1
		
		//
		if (args.includes("--liveweb")) {
			index_url = url.format({
				pathname: path.join(__dirname, "index-live.html"),
				protocol: 'file:',
				slashes: true
			})
		}
		let openArgs = args.slice(1).filter((arg) => !arg.startsWith("--"))
		if (openArgs.length > 0) index_url += "?open=" + encodeURIComponent(openArgs[0])
	}
	
	wnd.loadURL(index_url)

	// Open the DevTools.
	//wnd.webContents.openDevTools()

	// Emitted when the window is closed.
	wnd.on('closed', function () {
		// Dereference the window object, usually you would store windows
		// in an array if your app supports multi windows, this is the time
		// when you should delete the corresponding element.
		let i = activeWindows.indexOf(wnd)
		if (i >= 0) activeWindows.splice(i, 1)
		wnd = null
	})
}

app.on('ready', function () {
	// This method will be called when Electron has finished
	// initialization and is ready to create browser windows.
	// Some APIs can only be used after this event occurs.
	createWindow(true)
})

app.on('activate', function () {
	// On OS X it's common to re-create a window in the app when the
	// dock icon is clicked and there are no other windows open.
	if (activeWindows.length == 0) {
		createWindow(true)
	}
})

// https://github.com/electron/electron/issues/4349
electron.ipcMain.on('shell-open', (e, path) => {
	electron.shell.openItem(path)
})

// https://github.com/electron/electron/issues/11617
electron.ipcMain.on('shell-show', (e, path) => {
	if (process.platform.startsWith("win")) path = path.replace(/\//g, "\\")
	electron.shell.showItemInFolder(path)
})

electron.ipcMain.on('new-ide', (e) => {
	createWindow();
})

//
electron.ipcMain.on('set-taskbar-icon', (e, path, text) => {
	let wnd = BrowserWindow.fromWebContents(e.sender)
	wnd.setOverlayIcon(path, text)
})

// Quit when all windows are closed.
app.on('window-all-closed', function () {
	// On OS X it is common for applications and their menu bar
	// to stay active until the user quits explicitly with Cmd + Q
	if (process.platform !== 'darwin') {
		app.quit()
	}
})

// In this file you can include the rest of your app's specific main process
// code. You can also put them in separate files and require them here.
