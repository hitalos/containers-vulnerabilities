SHELL=/bin/bash
-include .env
export

public:
	hugo --quiet --minify --cleanDestinationDir

reports:
	./report.sh

report-%: clean
	./report.sh $(*) && \
	hugo --minify --cleanDestinationDir

clean:
	rm -rf public reports data

deploy: public
	@[[ -n "$(AWS_ACCESS_KEY_ID)" && -n "$(AWS_SECRET_ACCESS_KEY)" ]] && \
	hugo deploy || \
	echo "Missing AWS_ACCESS_KEY_ID or AWS_SECRET_ACCESS_KEY environment variable"

.PHONY: all clean public deploy
