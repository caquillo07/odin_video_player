run: fmt
	@odin run . -extra-linker-flags="$(shell pkg-config --libs libavformat)"

fmt:
	 odinfmt -w
