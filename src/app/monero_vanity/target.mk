TARGET  = monero_vanity
LIBS    = libc nim-threads
SRC_NIM = monero_vanity.nim

vpath %.nim $(REP_DIR)/monero
vpath %.c $(REP_DIR)/monero

# Make it fast
NIM_OPT += -d:release

# Profile
#NIM_OPT += --profiler:on --stackTrace:on
