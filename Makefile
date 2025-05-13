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
	hugo --minify --cleanDestinationDir --environment production

clean:
	@rm -rf public data resources

deploy: public
	@[[ -n "$(AWS_ACCESS_KEY_ID)" && -n "$(AWS_SECRET_ACCESS_KEY)" ]] && \
	hugo deploy || \
	echo "Missing AWS_ACCESS_KEY_ID or AWS_SECRET_ACCESS_KEY environment variable"

tar:
	hugo --minify --cleanDestinationDir --environment tar
	@cd public && \
	tar --exclude="*.zst" -c . | xz -9 > ../containers-vulnerabilities.tar.xz

sync:
	rsync -a --checksum --verbose --delete ./ $(REMOTE)

.PHONY: all clean public deploy
