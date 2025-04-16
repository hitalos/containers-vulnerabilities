SHELL=/bin/bash
-include .env
export

public:
	hugo --quiet --minify --cleanDestinationDir

reports: list
	./report.sh

report-%: clean
	./report.sh $(*) && \
	hugo --minify --cleanDestinationDir

list:
	@bash -c 'read -p "List for podman or kubernetes? (p or k) " -n 1 ; \
	if [[ "$${REPLY}" == "p" ]]; then ./list-pods-podman.sh ; \
	elif [[ "$${REPLY}" == "k" ]]; then ./list-pods-k8s.sh ; \
	fi; echo'

clean:
	rm -rf public reports data

deploy: public
	@[[ -n "$(AWS_ACCESS_KEY_ID)" && -n "$(AWS_SECRET_ACCESS_KEY)" ]] && \
	hugo deploy || \
	echo "Missing AWS_ACCESS_KEY_ID or AWS_SECRET_ACCESS_KEY environment variable"

.PHONY: all clean public deploy
