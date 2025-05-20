const electron = require('electron')

const electronVersion = (() => {
	let version = process.versions.electron
	let pos = version.indexOf(".")
	if (pos >= 0) version = version.substr(0, pos)
	return parseInt(version)
})()

const remoteAsModule = (electronVersion >= 14)
if (remoteAsModule) {
	require('@electron/remote/main').initialize()
}

const minVersion = 11
const maxVersion = 33
if (electronVersion < minVersion) {
	throw new Error([
		"Hey, this Electron version is too old!",
		`GMEdit needs at least Electron ${minVersion}.x, but you have ${process.versions.electron}.`,
		"If you are downloading GMEdit-App-Only.zip, please download a full release to update Electron.",
		"If you are building GMEdit from source code, grab a newer Electron binary as per README instructions."
	].join("\n"))
}

// Module to control application life.
const app = electron.app
// Module to create native browser window.
const BrowserWindow = electron.BrowserWindow

const path = require('path')
const url = require('url')
const fs = require('fs')

// Keep a global reference of the window object, if you don't, the window will
// be closed automatically when the JavaScript object is garbage collected.
let activeWindows = []
const isWindows = process.platform == "win32"
const isMac = process.platform == "darwin"
app.on("browser-window-created", (e, wnd) => {
	if (!isMac) {
		wnd.removeMenu();
	}
	
	// https://github.com/electron/electron/issues/42055
	wnd.webContents.on('devtools-opened', () => {
		const css = `
			:root {
				--sys-color-base: var(--ref-palette-neutral100);
				--source-code-font-family: consolas !important;
				--source-code-font-size: 12px;
				--monospace-font-family: consolas !important;
				--monospace-font-size: 12px;
				--default-font-family: system-ui, sans-serif;
				--default-font-size: 12px;
				--ref-palette-neutral99: #ffffffff;
			}
			.theme-with-dark-background {
				--sys-color-base: var(--ref-palette-secondary25);
			}
			body {
				--default-font-family: system-ui,sans-serif;
			}
		`;
		wnd.webContents.devToolsWebContents.executeJavaScript(`
			const overriddenStyle = document.createElement('style');
			overriddenStyle.innerHTML = '${css.replaceAll('\n', ' ')}';
			document.body.append(overriddenStyle);
			document.querySelectorAll('.platform-windows').forEach(el => el.classList.remove('platform-windows'));
			addStyleToAutoComplete();
			const observer = new MutationObserver((mutationList, observer) => {
				for (const mutation of mutationList) {
					if (mutation.type === 'childList') {
						for (let i = 0; i < mutation.addedNodes.length; i++) {
							const item = mutation.addedNodes[i];
							if (item.classList.contains('editor-tooltip-host')) {
								addStyleToAutoComplete();
							}
						}
					}
				}
			});
			observer.observe(document.body, {childList: true});
			function addStyleToAutoComplete() {
				document.querySelectorAll('.editor-tooltip-host').forEach(element => {
					if (element.shadowRoot.querySelectorAll('[data-key="overridden-dev-tools-font"]').length === 0) {
						const overriddenStyle = document.createElement('style');
						overriddenStyle.setAttribute('data-key', 'overridden-dev-tools-font');
						overriddenStyle.innerHTML = '.cm-tooltip-autocomplete ul[role=listbox] {font-family: consolas !important;}';
						element.shadowRoot.append(overriddenStyle);
					}
				});
			}
		`);
	});
});

function createWindow(first) {
	//
	let windowWidth = 960, windowHeight = 720, windowFrame = false
	try {
		const configPath = app.getPath("userData") + "/GMEdit/config/user-preferences.json"
		if (fs.existsSync(configPath)) {
			const config = JSON.parse(fs.readFileSync(configPath, 'utf8'))
			windowWidth = config.app?.windowWidth ?? windowWidth
			windowHeight = config.app?.windowHeight ?? windowHeight
			windowFrame = config.app?.windowFrame ?? windowFrame
		}
	} catch (x) {
		console.warn('Error reading preferences:', x)
	}
	// Create the browser window.
	const showOnceReady = false
	let wnd = new BrowserWindow({
		width: windowWidth,
		height: windowHeight,
		frame: windowFrame,
		backgroundColor: "#889EC5",
		title: "GMEdit",
		webPreferences: {
			enableRemoteModule: true,
			nodeIntegration: true,
			contextIsolation: false,
		},
		show: !showOnceReady,
		icon: __dirname + '/favicon.' + (isWindows ? "ico" : "png")
	})

	wnd.webContents.on('did-create-window', (childWnd) => {
		childWnd.once('ready-to-show', () => {
			childWnd.webContents.setZoomLevel(wnd.webContents.getZoomLevel())
		})
	})

	activeWindows.push(wnd)
	if (showOnceReady) {
		wnd.once('ready-to-show', () => wnd.show())
	}
	app.allowRendererProcessReuse = false
	
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
	let index_url = `file:///${__dirname}/index.html`
	
	let params = []
	if (windowFrame) params.push("electron-window-frame")
	if (first) {
		let args = process.argv
		
		//
		if (args.includes("--liveweb")) {
			index_url = `file:///${__dirname}/index-live.html`
		}
		
		let openArgs = args.slice(1).filter(function(arg) {
			// various --flags
			if (arg.startsWith("--")) return false
			
			// https://apple.stackexchange.com/questions/207895/app-gets-in-commandline-parameter-psn-0-nnnnnn-why
			if (isMac && arg.startsWith("-psn")) return false
			
			return true
		})
		if (openArgs.length > 0) params.push("open=" + encodeURIComponent(openArgs[0]))
	}
	if (params.length > 0) index_url += "?" + params.join("&")
	
	wnd.loadURL(index_url)
	if (remoteAsModule) {
		require("@electron/remote/main").enable(wnd.webContents)
	}

	// Open the DevTools.
	try {
		//wnd.webContents.openDevTools()
	} catch (e) {
		console.error("Failed to open devtools: ", e)
	}

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
	if (electronVersion > maxVersion) {
		electron.dialog.showMessageBoxSync({
			message: [
				"Hey, this Electron version is too new!",
				`GMEdit has only been verified to work with Electron versions up to ${maxVersion}.x, but you have ${process.versions.electron}.`,
				"If you are downloading GMEdit-App-Only.zip, please download a full release.",
				"If you are building GMEdit from source code, grab an appropriate Electron binary as per README instructions."
			].join("\n"),
			type: "warning",
			buttons: ["OK"],
		})
	}
	
	createWindow(true)
})

app.on('activate', function () {
	// On OS X it's common to re-create a window in the app when the
	// dock icon is clicked and there are no other windows open.
	if (activeWindows.length == 0) {
		createWindow(true)
	}
})

{
	const ipc = electron.ipcMain
	// https://github.com/electron/electron/issues/4349
	ipc.on('shell-open', (e, path) => {
		if (isWindows) path = path.replace(/\//g, "\\")
		electron.shell.openPath(path)
	})
	
	// https://github.com/electron/electron/issues/11617
	ipc.on('shell-show', (e, path) => {
		if (isWindows) path = path.replace(/\//g, "\\")
		electron.shell.showItemInFolder(path)
	})
	
	ipc.on('new-ide', (e) => {
		createWindow()
	})
	
	ipc.on('set-taskbar-icon', (e, path, text) => {
		let wnd = BrowserWindow.fromWebContents(e.sender)
		wnd.setOverlayIcon(path, text)
	})
	
	ipc.on('resize-window', (e, width, height) => {
		let wnd = BrowserWindow.fromWebContents(e.sender)
		if (width == null || height == null) {
			let size = wnd.getSize()
			width ??= size[0]
			height ??= size[1]
		}
		wnd.setSize(width, height)
	})

	ipc.on('zoom-in', ({ sender }) => sender.setZoomLevel(sender.getZoomLevel() + 1))

	ipc.on('zoom-out', ({ sender }) => sender.setZoomLevel(sender.getZoomLevel() - 1))
	
	ipc.on('add-recent-document', (e, path) => {
		if (isWindows) path = path.replace(/\//g, "\\")
		app.addRecentDocument(path)
	})
	
	ipc.on('clear-recent-documents', (e) => {
		app.clearRecentDocuments()
	})
}

{
	let tasks = []
	let execPath = process.execPath
	tasks.push({
		program: execPath,
		arguments: "",
		iconPath: execPath,
		iconIndex: 0,
		title: "New window",
		description: "",
	})
	try {
		app.setUserTasks(tasks)
	} catch (e) {
		console.error(e)
	}
}

// Quit when all windows are closed.
app.on('window-all-closed', function () {
	// On OS X it is common for applications and their menu bar
	// to stay active until the user quits explicitly with Cmd + Q
	if (process.platform !== 'darwin') {
		app.quit()
	}
})
