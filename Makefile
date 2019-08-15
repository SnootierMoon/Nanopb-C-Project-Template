##################################################################################
#                                                                                #
# Author: Akshay Trivedi                                                         #
#                                                                                #
# Simple-comple C/nanopb Makefile                                                #
# Ability to:                                                                    #
#   - generate dependencies and build all .c files in $(C_SOURCE_DIRECTORY)      #
#   - generate protos with nanopb                                                #
#   - generate nanopb's repo in a way such that it can be used without actually  #
#       downloading or configuring their source code                             #
#                                                                                #
##################################################################################
##
## Usage:
##  - BUILDING THE TEMPLATE
##     - do 'make template' to generate the source directory
##
##     - add .proto files into the proto source directory.
##
##     - do 'make pb-gen' to create the nanopb pb.* files from the proto.
##
##     - add source code anywhere in the C source directory. Add an entry point.
##
##     - do 'make' or 'make all' to generate an executable binary. 'make'
##       will rub 'make all' which will compile protos, recompile changed
##       source code, and then relink all object files.
##
##  - MAINTAINING A PROJECT
##     - 'make help': shows this menu.
##
##     - 'make' or 'make all': generates everything.
##
##     - 'make root-symlink': generates a symbolic link from project root to
##       the executable.
##
##################################################################################
#                                                                                #
# Key:                                                                           #
#  ALL_CAPS = makefile custom variable, defined as DIR_ALL_CAPS or FILE_ALL_CAPS #
#  lowercase = literal file/folder name                                          #
#  [brackets] = description of file/folder contents                              #
#                                                                                #
#                                                                                #
# Directory structure diagram:                                                   #
#                                                                                #
#   NANOPB [folder called nanopb, https://github.com/nanopb/nanopb]              #
#   |__ nanopb                                                                   #
#       |__ generator                                                            #
#       |   |__ protoc-gen-nanopb [protoc plugin]                                #
#       |__ pb_common.h pb_common.c                                              #
#       |__ pb_encode.h pb_encode.c                                              #
#       |__ pb_decode.h pb_decode.c                                              #
#       |__ pb.h                                                                 #
#       |__ * [other (irrelevant) nanopb files]                                  #
#                                                                                #
#   . [project root]                                                             #
#   |__ SOURCE [contains all source code]                                        #
#   |   |__ C [contains ALL C source code]                                       #
#   |   |   |__ *.c *.h [original source code]                                   #
#   |   |   |__ PBGEN                                                            #
#   |   |       |__ *.pb.h *.pb.c [generated protobuf C source]                  #
#   |   |__ PROTO                                                                #
#   |       |__ *.proto [original protobuf source]                               #
#   |__ BUILD [contains all dependent non-source files]                          #
#   |   |__ DEP                                                                  #
#   |   |   |__ *.d [generated dependency files]                                 #
#   |   |__ OBJ                                                                  #
#   |   |   |__ *.o [generated object files]                                     #
#   |   |__ OUT                                                                  #
#   |   |   |__ TARGET [generated exectuable]                                    #
#   |   |__ PROTO                                                                #
#   |       |__ *.pb [generated compiled protobuf]                               #
#   |__ Makefile [you are here]                                                  #
#                                                                                #
#   Dependency tree diagram: (coming soon)                                       #
#                                                                                #
##################################################################################

# Boolean options (set to 0 or 1)

# Delete nanopb directory when 'make clean' is called? (recommended only if nanopb is specific for this project)
OPTION_SHOULD_DELETE_NANOPB_ON_CLEAN=1
# Silently download nanopb directory with clone command? (useful for debugging make output)
OPTION_CLONE_SILENT=1
# Enable C++ mode? (uses CXX instead of CC, LDXX instead of LD, and EXTENSION_CXX instead of EXTENSIONS_C)
OPTION_USE_CPP=0
# Create symlink at root for the executable automatically when 'make all' is called?
OPTION_MAKE_TARGET_SYMLINK=1

# Directory structure options (directory/file basenames)
# For example, if CPP mode is on, you might want to change _DIR_SOURCE_C to 'cpp'

_DIR_SOURCE         =src
_DIR_SOURCE_C       =c
_DIR_SOURCE_C_PBGEN =pb_gen
_DIR_SOURCE_PROTO   =proto
_DIR_BUILD          =build
_DIR_BUILD_DEP      =dep
_DIR_BUILD_OBJ      =obj
_DIR_BUILD_OUT      =out
_FILE_TARGET        =main

# if OPTION_MAKE_TARGET_SYMLINK is true, this is the name of the symlink
TARGET_SYMLINK_NAME =$(_FILE_TARGET)

# GIT_NANOPB is the nanopb git repo that should be downloaded
GIT_NANOPB          =https://github.com/nanopb/nanopb
	# DIR_NANOPB is [parent] directory in which nanopb is or will be installed
_DIR_NANOPB         =$(CURDIR)

# Customizable commands

RM                  =rm -rf
MKDIR               =mkdir -p
MKDIR_SILENT        =@$(MKDIR)
ECHO                =@echo
SYMLINK             =ln -s

CLONE               =git clone
CLONEFLAGS_OPTIONS  =

# This should be a find pattern for C source code in DIR_SOURCE_C that should be detected. For example: -name '*.c' -o -name '*.cc'
# For the sake of documentation, these will still be called .c files in comments, even if C++ mode is on.
EXTENSIONS_C        =-name '*.c'
EXTENSIONS_CXX      =-name '*.cpp'

# Specify preferred compilers & compiler options

CC                  =clang
LD                  =$(CC)
PROTOC              =protoc

# for cpp support
CXX                 =clang++
LDXX                =$(CXX)

# these flags are c/c++ independent
CFLAGS_OPTIONS      =-ggdb -O0 -march=native -ftrapv
LDFLAGS_OPTIONS     =
PROTOCFLAGS_OPTIONS =

####################################################################################################################################################
#            /\            #                                                                                            #            /\            #
#           /  \           #             warning       warning        warning        warning       warning              #           /  \           #
#          /    \          #      warning       warning        warning        warning       warning        warning      #          /    \          #
#         /  ##  \         #             warning       warning        warning        warning       warning              #         /  ##  \         #
#        /   ##   \        #                                                                                            #        /   ##   \        #
#       /    ##    \       #  -EDITS BELOW THIS POINT HAVE THE POTENTIAL TO CHANGE / DESTROY THE PROJECT ARCHITECTURE-  #       /    ##    \       #
#      /     ##     \      #      -YOU MUST UNDERSTAND THE FULL PROGRAM BEFORE MAKING ANY EDITS BELOW THIS POINT-       #      /     ##     \      #
#     /      ##      \     #                                                                                            #     /      ##      \     #
#    /       ##       \    #      warning       warning        warning        warning       warning        warning      #    /       ##       \    #
#   /                  \   #             warning       warning        warning        warning       warning              #   /                  \   #
#  /         ##         \  #      warning       warning        warning        warning       warning        warning      #  /         ##         \  #
# /______________________\ #                                                                                            # /______________________\ #
####################################################################################################################################################

# File updating / scanning

DIR_SOURCE          =$(_DIR_SOURCE)
DIR_SOURCE_C        =$(addprefix $(DIR_SOURCE)/,$(_DIR_SOURCE_C))
DIR_SOURCE_C_PBGEN  =$(addprefix $(DIR_SOURCE_C)/,$(_DIR_SOURCE_C_PBGEN))
DIR_SOURCE_PROTO    =$(addprefix $(DIR_SOURCE)/,$(_DIR_SOURCE_PROTO))
DIR_BUILD           =$(_DIR_BUILD)
DIR_BUILD_DEP       =$(addprefix $(DIR_BUILD)/,$(_DIR_BUILD_DEP))
DIR_BUILD_OBJ       =$(addprefix $(DIR_BUILD)/,$(_DIR_BUILD_OBJ))
DIR_BUILD_OUT       =$(addprefix $(DIR_BUILD)/,$(_DIR_BUILD_OUT))
FILE_TARGET         =$(addprefix $(DIR_BUILD_OUT)/,$(_FILE_TARGET))
DIR_NANOPB          =$(addsuffix /nanopb,$(_DIR_NANOPB))

EXTENSIONS_SOURCE_0 =$(EXTENSIONS_C)
EXTENSIONS_SOURCE_1 =$(EXTENSIONS_CXX)
EXTENSIONS_SOURCE   =$(EXTENSIONS_SOURCE_$(OPTION_USE_CPP))

FILE_SOURCE_PROTO   =$(shell find $(DIR_SOURCE_PROTO) -type f -name *.proto  2> /dev/null)
FILE_SOURCE_C       =$(shell find $(DIR_SOURCE_C)     -type f \( $(EXTENSIONS_SOURCE) \)  2> /dev/null)
FILE_SOURCE_C_PBGEN =$(patsubst $(DIR_SOURCE_PROTO)/%.proto,$(DIR_SOURCE_C_PBGEN)/%.pb.c,$(FILE_SOURCE_PROTO))
FILE_SOURCE_C_ALL   =$(sort $(FILE_SOURCE_C) $(FILE_SOURCE_C_PBGEN)) # this treats the .pb.c files as .c even if they don't exist yet (or if cpp mode is on) by using
# the FILE_SOURCE_C_PBGEN scanning for protos directly. If they do exist (and cpp mode is off),
# they would get scanned twice, but 'sort' will delete the duplicates.

FILE_OBJ            =$(patsubst $(DIR_SOURCE_C)/%,$(DIR_BUILD_OBJ)/%.o,$(FILE_SOURCE_C_ALL))
FILE_DEP            =$(patsubst $(DIR_SOURCE_C)/%,$(DIR_BUILD_DEP)/%.d,$(FILE_SOURCE_C_ALL))

RM_FILE_NANOPB_0    =
RM_FILE_NANOPB_1    =$(DIR_NANOPB)
RM_FILE_NANOPB      =$(RM_FILE_NANOPB_$(OPTION_SHOULD_DELETE_NANOPB_ON_CLEAN))

TARGET_SYMLINK_DEP_0=
TARGET_SYMLINK_DEP_1=root-symlink
TARGET_SYMLINK_DEP  =$(TARGET_SYMLINK_DEP_$(OPTION_MAKE_TARGET_SYMLINK))

# Command options

CLONEFLAGS_SILENT_0 =
CLONEFLAGS_SILENT_1 =-q
CLONEFLAGS_SILENT   =$(CLONEFLAGS_SILENT_$(OPTION_CLONE_SILENT))
CLONEFLAGS          =$(CLONEFLAGS_SILENT) $(CLONEFLAGS_OPTIONS)

SOURCE_COMPILER_0   =$(CC)
SOURCE_COMPILER_1   =$(CXX)
SOURCE_COMPILER     =$(SOURCE_COMPILER_$(OPTION_USE_CPP))

SOURCE_LINKER_0     =$(LD)
SOURCE_LINKER_1     =$(LDXX)
SOURCE_LINKER       =$(SOURCE_LINKER_$(OPTION_USE_CPP))

CFLAGS_INCLUDE      =-I$(DIR_NANOPB)
CFLAGS_DEP          =-MMD -MP -MF$(DIR_BUILD_DEP)/$*.d
CFLAGS              =$(CFLAGS_INCLUDE) $(CFLAGS_DEP) $(CFLAGS_OPTIONS)

LDFLAGS             =$(LDFLAGS_OPTIONS)

PROTOCFLAGS_PLUGIN  =--plugin=$(DIR_NANOPB)/generator/protoc-gen-nanopb
PROTOCFLAGS_INCLUDE =-I$(DIR_SOURCE_PROTO)
PROTOCFLAGS_OUT     =--nanopb_out=$(DIR_SOURCE_C_PBGEN)
PROTOCFLAGS         =$(PROTOCFLAGS_PLUGIN) $(PROTOCFLAGS_INCLUDE) $(PROTOCFLAGS_OUT) $(PROTOCFLAGS_OPTIONS)

-include $(FILE_DEP)

.DEFAULT_GOAL=all
.PHONY: clean
.PRECIOUS: $(FILE_SOURCE_C_PBGEN) # prevents make from treating necessary .pb.* files as "intermediate"

help:
	@sed -ne '/@sed/!s/## //p' $(MAKEFILE_LIST)

template:
	$(MKDIR) $(DIR_SOURCE) $(DIR_SOURCE_C) $(DIR_SOURCE_C_PBGEN) $(DIR_SOURCE_PROTO)

pb-gen: $(SOURCE_C_PBGEN)

all: $(FILE_TARGET) $(TARGET_SYMLINK_DEP)

clean:
	$(RM) $(DIR_BUILD) $(DIR_SOURCE_C_PBGEN)/* $(RM_FILE_NANOPB) $(TARGET_SYMLINK_NAME)

# WARNING: makes symlink regardless of whether or not exe is updated
root-symlink: $(TARGET_SYMLINK_NAME)

$(TARGET_SYMLINK_NAME):
	$(SYMLINK) $(FILE_TARGET) $(TARGET_SYMLINK_NAME)

$(FILE_TARGET): $(FILE_OBJ) | $(DIR_BUILD_OUT)
	$(SOURCE_LINKER) -o$@ $^ $(LDFLAGS)
	$(ECHO) "-- Built executable $@ --"

$(DIR_BUILD_OBJ)/%.o: $(DIR_SOURCE_C)/% | $(DIR_BUILD_OBJ) $(DIR_BUILD_DEP) $(DIR_NANOPB)
	$(MKDIR_SILENT) $(@D)
	$(MKDIR_SILENT) $(DIR_BUILD_DEP)/$(*D)
	$(SOURCE_COMPILER) -o$@ $< -c $(CFLAGS)

$(DIR_SOURCE_C_PBGEN)/%.pb.c $(DIR_SOURCE_C_PBGEN)/%.pb.h: $(DIR_SOURCE_PROTO)/%.proto
	$(PROTOC) $< $(PROTOCFLAGS)

$(DIR_BUILD_DEP) $(DIR_BUILD_OBJ) $(DIR_BUILD_OUT):
	$(MKDIR) $@

$(DIR_NANOPB):
	$(CLONE) $(CLONEFLAGS) $(GIT_NANOPB) $(DIR_NANOPB)

