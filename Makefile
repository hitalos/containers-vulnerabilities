include .env
export

public:
	hugo --minify --cleanDestinationDir

reports:
	./report.sh

clean:
	rm -rf public reports

deploy: public
	hugo deploy

.PHONY: all clean public deploy
