.PHONY: efsmanage
efsmanage:
	mkdir -p bin
	go build -o bin/efsmanage ./pkg/efsmanage/...
