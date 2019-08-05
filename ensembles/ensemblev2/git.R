try({
	system("git pull")
	system("git add *")
	system("git commit -m 'Ensemble V2'")
	system("git push")
	Sys.sleep(900)
	system("init 0")
})