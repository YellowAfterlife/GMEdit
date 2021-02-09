## How to build

Install node modules by navigating to `bin/resources/app` and then running  
```
npm install
```  
Electron requires native node modules to be rebuilt using electron-rebuild. To install and launch this, run:  
```
npm install -g electron-rebuild
electron-rebuild -v VERSION
```  
where VERSION is the version of Electron you downloaded.

---

Once you are done building, copy
```
bin/resources/app/node_modules/font-scanner/build/Release/fontmanager.node
```
to
```
bin/resources/app/native/font-scanner/fontmanager-<platform>-<architecture>.node
```
(e.g. `fontmanager-win32-x64.node`).

**Note:** `bin/resources/app/native/font-scanner/index.js` uses a single init line in the beginning instead of try-catch-try-catch.