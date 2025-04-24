SHELL=/bin/bash
-include .env
export

reports: list
	@./report.sh && \
	$(MAKE) public


report-%: clean
	@$(MAKE) list-$(*) && \
	./report.sh && \
	$(MAKE) public

list:
	@mkdir -p data
	@bash -c 'read -p "List for podman or kubernetes? (p or k) " -n 1 ; \
	if [[ "$${REPLY}" == "p" ]]; then ./list-pods-podman.sh ; \
	elif [[ "$${REPLY}" == "k" ]]; then ./list-pods-k8s.sh ; \
	fi; echo'

list-%:
	@mkdir -p data
	@bash -c 'read -p "List for podman or kubernetes? (p or k) " -n 1 ; \
	if [[ "$${REPLY}" == "p" ]]; then ./list-pods-podman.sh $(*) ; \
	elif [[ "$${REPLY}" == "k" ]]; then ./list-pods-k8s.sh $(*) ; \
	fi; echo'

public:
	hugo --minify --cleanDestinationDir

clean:
	@rm -rf public data

deploy: public
	@[[ -n "$(AWS_ACCESS_KEY_ID)" && -n "$(AWS_SECRET_ACCESS_KEY)" ]] && \
	hugo deploy || \
	echo "Missing AWS_ACCESS_KEY_ID or AWS_SECRET_ACCESS_KEY environment variable"

tar:
	@cd public && \
	tar --exclude="*.zst" -c . | gzip -9 > ../containers-vulnerabilities.tar.gz

sync:
	rsync -a --checksum --verbose --delete ./ nti-045.jfal:Documents/workspace/k8s-vulnerabilities/

.PHONY: all clean public deploy
