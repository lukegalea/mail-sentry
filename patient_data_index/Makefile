.SUFFIXES: .erl .beam .yrl

.erl.beam:
	erlc -W $<

.yrl.beam:
	erlc -W $<

#erlc +native
ERL = erl -smp -boot start_clean

MODS = patient_data_index csv

all: compile

compile: ${MODS:%=%.beam} #subdirs

start: compile
	${ERL} -noshell -s patient_data_index start -s erlang halt

#subdirs:
#	cd dir1; make
#	cd dir2; make

clean:
	rm -rf *.beam erl_crash.dump
#	cd dir1; make clean
#	cd dir2; make clean