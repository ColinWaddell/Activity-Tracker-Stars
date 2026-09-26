SCAD_FILE := ActivityTracker.scad

# OpenSCAD is not on PATH by default on Windows; override with OPENSCAD=... if needed
OPENSCAD ?= C:\Program Files\OpenSCAD\openscad.exe

# Case renders for 1 up to 10 tokens
TOKEN_COUNTS := 1 2 3 4 5 6 7 8 9 10

CASE_STLS := $(foreach n,$(TOKEN_COUNTS),ActivityTracker_Case_$(n)tokens.stl)
TOKEN_STL := ActivityTracker_Token.stl

.PHONY: all clean

all: $(CASE_STLS) $(TOKEN_STL)

ActivityTracker_Case_%tokens.stl: $(SCAD_FILE)
	"$(OPENSCAD)" -D "case_or_token=\"case\"" -D "tokens=$*" -o "$@" "$<"

ActivityTracker_Token.stl: $(SCAD_FILE)
	"$(OPENSCAD)" -D "case_or_token=\"token\"" -o "$@" "$<"

clean:
	-cmd /c del /Q $(CASE_STLS) $(TOKEN_STL)