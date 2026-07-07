##############################################################################
#
#  Sample Makefile for C++ applications
#    Works for single and multiple file programs.
#    written by Robert Duvall
#    modified by Owen Astrachan
#
##############################################################################

# Make make keep state about file dependencies when compiling.
# This is like 'makedepend', but only works with the Sun version
# of make, typically found in /usr/ccs/bin/make
# if using a non-Sun make, e.g., gmake from GNU, then you must
# use the 'makedepend' line.  To use KEEP_STATE, just uncomment the
# .KEEP_STATE: line below
#
# .KEEP_STATE:
#

.SUFFIXES: .cpp


##############################################################################
# Application specific variables
# EXEC is the name of the executable file
# SRC_FILES is a list of all source code files that must be linked
#           to create the executable
##############################################################################

EXEC   	  = get_open_times
SRC_FILES = Main.cpp Tokenizer.cpp TimeZones.cpp


##############################################################################
# Where to find course related files
# for CS machines
#
#LIB_DIR     = /usr/local/lib

# for acpub machines
#LIB_DIR     = /afs/acpub/project/cps/lib


##############################################################################
# Compiler specifications
# These match the variable names given in /usr/share/lib/make/make.rules
# so that make's generic rules work to compile our files.
# gmake prefers CXX and CXXFLAGS for c++ programs
##############################################################################
# Which compiler should be used
CCC		= g++
CXX		= $(CCC)

# What flags should be passed to the compiler
#
DEBUG_LEVEL	= -g
EXTRA_CCFLAGS   = -Wall 
CCFLAGS		= $(VERBOSE) $(DEBUG_LEVEL) $(EXTRA_CCFLAGS)
CXXFLAGS	= $(CCFLAGS)

# What flags should be passed to the C pre-processor
#   In other words, where should we look for files to include - note,
#   you should never need to include compiler specific directories here
#   because each compiler already knows where to look for its system
#   files (unless you want to override the defaults)
#
CPPFLAGS  	= -I.:/usr/include

# What flags should be passed to the linker
#   In other words, where should we look for libraries to link with - note,
#   you should never need to include compiler specific directories here
#   because each compiler already knows where to look for its system files.
#
LDFLAGS		= -L.

# What libraries should be linked with
LDLIBS		= -lgsl -lgslcblas -lm

# All source files have associated object files
OFILES		= $(SRC_FILES:%.cpp=%.o)


###########################################################################
# Additional rules make should know about in order to compile our files
###########################################################################
# all is the default rule
all	: $(EXEC)


# exec depends on the object files
$(EXEC) : $(OFILES)
	$(LINK.cc) -o $(EXEC) $(OFILES) $(LDLIBS)


# to use 'makedepend', the target is 'depend'
# uncomment the two lines below
depend:
	makedepend -- $(CXXFLAGS) -- -Y $(SRC_FILES)


# clean up after you're done
clean	:
	$(RM) $(OFILES) $(EXEC) core


# clean up after you're done
submit	: clean
	$(SUBMIT) $(EXEC) README Makefile $(SRC_FILES)


# compile a single .cpp file into an object (.o) file
# for later linking with other .o files
.cpp.o:
	$(COMPILE.cc) -c $<

# compile a single .cpp file into an executable file
.cpp:
	$(LINK.cc) $< -o $@ $(LDLIBS)


# DO NOT DELETE THIS LINE -- make depend depends on it.
