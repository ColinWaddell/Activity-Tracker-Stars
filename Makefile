SCAD_FILE := ActivityTracker.scad

# OpenSCAD is not on PATH by default on Windows; override with OPENSCAD=... if needed
OPENSCAD ?= C:\Program Files\OpenSCAD\openscad.exe

# Case renders for 1 up to 10 tokens
TOKEN_COUNTS := 1 2 3 4 5 6 7 8 9 10

CASE_STLS := $(foreach n,$(TOKEN_COUNTS),ActivityTracker_Case_$(n)tokens.stl)
TOKEN_STL := ActivityTracker_Token.stl

.PHONY: all clean verify verify-save preview

all: $(CASE_STLS) $(TOKEN_STL)

ActivityTracker_Case_%tokens.stl: $(SCAD_FILE)
	"$(OPENSCAD)" -D "case_or_token=\"case\"" -D "tokens=$*" -o "$@" "$<"

ActivityTracker_Token.stl: $(SCAD_FILE)
	"$(OPENSCAD)" -D "case_or_token=\"token\"" -o "$@" "$<"

# Geometry regression check: renders a handful of configurations and compares
# them to the baseline recorded in tests/baseline.json. Run 'make verify-save'
# after intentionally changing the geometry to record a new baseline.
verify:
	python tests/verify.py check

verify-save:
	python tests/verify.py save

preview.png: $(SCAD_FILE)
	"$(OPENSCAD)" --imgsize=900,600 --colorscheme=Tomorrow --projection=ortho \
		--camera=51,60,0,60,0,35,260 -o "$@" "$<"

clean:
	-cmd /c del /Q $(CASE_STLS) $(TOKEN_STL)
	-cmd /c del /Q preview.png tests\case_*.stl tests\token.stl
