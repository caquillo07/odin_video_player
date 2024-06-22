run:
	odin run . -extra-linker-flags="$(shell pkg-config --libs libavformat libswscale)" -out:bin/odin_video_player

fmt:
	 odinfmt -w
