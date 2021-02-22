@echo OFF
IF EXIST "./bin/editor.exe" (
  START ./bin/editor.exe --remote-debugging-port=8315
) ELSE (
	IF EXIST "./bin/electron.exe" (
	  START ./bin/electron.exe --remote-debugging-port=8315
	) ELSE (
		echo [31mNo electron executable file with name "editor" or "electron" was found. Make sure you've downloaded an electron binary.[0m
		EXIT /b 1
	)
)