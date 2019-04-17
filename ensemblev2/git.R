try({
	system("git pull")
	system("git add *")
	system("git commit -m 'Ensemble V2'")
	system("git push")
	system("init 0")
})