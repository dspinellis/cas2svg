PDP7URL=https://raw.githubusercontent.com/DoctorWkt/pdp7-unix/master/src/cmd/
CASFILES=scope.cas cas.cas

all: build/all.svg build/ca.svg

build/all.svg: cas2svg.pl $(CASFILES)
	mkdir -p build
	perl ./cas2svg.pl -m $(CASFILES)

build/ca.svg: cas2svg.pl $(CASFILES)
	mkdir -p build
	perl ./cas2svg.pl $(CASFILES)

scope.cas:
	curl $(PDP7URL)/$@ >$@

cas.cas:
	curl $(PDP7URL)/$@ >$@

clean:
	rm -rf *.cas build
