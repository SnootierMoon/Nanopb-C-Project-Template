##################################################################################
#                                                                                #
# Author: Akshay Trivedi                                                         #
#                                                                                #
# Simple-comple C/nanopb Makefile                                                #
# Ability to:                                                                    #
#   - generate dependencies and build all .c files in $(C_SOURCE_DIRECTORY)      #
#   - generate protos with nanopb                                                #
#   - generate nanopb's reop in a way such that it can be used without actually  #
#       downloading or configuring their source code                             #
#                                                                                #
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

# Boolean options (set to 0 or 1, any other value is 0) (recommended only if nanopb is specific for this project)
OPTION_SHOULD_DELETE_NANOPB_ON_CLEAN=1
OPTION_CLONE_SILENT=0

# Directory structure options (folder names can be modified)

_DIR_SOURCE         =src
_DIR_SOURCE_C       =c
_DIR_SOURCE_C_PBGEN =pb_gen
_DIR_SOURCE_PROTO   =proto
_DIR_BUILD          =build
_DIR_BUILD_DEP      =dep
_DIR_BUILD_OBJ      =obj
_DIR_BUILD_OUT      =out
_FILE_TARGET        =main

# DIR_NANOPB is [parent] directory into which nanopb is or will be installed
GIT_NANOPB          =https://github.com/nanopb/nanopb
_DIR_NANOPB         =$(CURDIR)

# Customizable commands

RM                  =rm -rf
MKDIR               =mkdir -p
MKDIR_SILENT        =@$(MKDIR)
ECHO                =@echo

CLONE               =git clone
CLONEFLAGS_OPTIONS  =-v

# This should be a find pattern for C source code in DIR_SOURCE_C that should be detected. For example: -name "*.c" -o -name "*.h"
EXTENSIONS_C        =-name "*.c" -o -name "*.pb.c"

# Specify preferred compilers & compiler options

CC                  =clang
LD                  =clang
PROTOC              =protoc

CFLAGS_OPTIONS      =-ggdb -O0 -march=native -ftrapv
LDFLAGS_OPTIONS     =
PROTOCFLAGS_OPTIONS =

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

FILE_SOURCE_PROTO   =$(shell find $(DIR_SOURCE_PROTO) -type f -name *.proto  2> /dev/null)
FILE_SOURCE_C       =$(shell find $(DIR_SOURCE_C)     -type f \( $(EXTENSIONS_C) \)  2> /dev/null)
FILE_SOURCE_C_PBGEN =$(patsubst $(DIR_SOURCE_PROTO)/%.proto,$(DIR_SOURCE_C_PBGEN)/%.pb.c,$(FILE_SOURCE_PROTO))
FILE_SOURCE_C_ALL   =$(FILE_SOURCE_C) $(FILE_SOURCE_C_PBGEN)

FILE_OBJ            =$(patsubst $(DIR_SOURCE_C)/%.c,$(DIR_BUILD_OBJ)/%.o,$(FILE_SOURCE_C_ALL))
FILE_DEP            =$(patsubst $(DIR_SOURCE_C)/%.c,$(DIR_BUILD_DEP)/%.d,$(FILE_SOURCE_C_ALL))

RM_FILE_NANOPB_0    =
RM_FILE_NANOPB_1    =$(DIR_NANOPB)
RM_FILE_NANOPB      =$(RM_FILE_NANOPB_$(OPTION_SHOULD_DELETE_NANOPB_ON_CLEAN))

# Command options

CLONEFLAGS_SILENT_0 =
CLONEFLAGS_SILENT_1 =-q
CLONEFLAGS_SILENT   =$(CLONEFLAGS_SILENT_$(OPTION_CLONE_SILENT))
CLONEFLAGS          =$(CLONEFLAGS_SILENT) $(CLONEFLAGS_OPTIONS)

CFLAGS_INCLUDE      =-I$(DIR_NANOPB)
CFLAGS_DEP          =-MMD -MP -MF$(DIR_BUILD_DEP)/$*.d
CFLAGS              =$(CFLAGS_INCLUDE) $(CFLAGS_DEP) $(CFLAGS_OPTIONS)

LDFLAGS             =$(LDFLAGS_OPTIONS)

PROTOCFLAGS_PLUGIN  =--plugin=$(DIR_NANOPB)/generator/protoc-gen-nanopb
PROTOCFLAGS_INCLUDE =-I$(DIR_SOURCE_PROTO)
PROTOCFLAGS_OUT     =--nanopb_out=$(DIR_SOURCE_C_PBGEN)
PROTOCFLAGS         =$(PROTOCFLAGS_PLUGIN) $(PROTOCFLAGS_INCLUDE) $(PROTOCFLAGS_OUT) $(PROTOCFLAGS_OPTIONS)

-include $(FILE_DEP)

.PHONY: clean
.DEFAULT_GOAL=all
.PRECIOUS: $(FILE_SOURCE_C_PBGEN) # prevents make from treating necessary .pb.* files as "intermediate"

all: $(FILE_TARGET)

$(FILE_TARGET): $(FILE_OBJ) | $(DIR_BUILD_OUT)
	$(LD) -o$@ $^ $(LDFLAGS)
	$(ECHO) "-- Built executable $@ --"

$(DIR_BUILD_OBJ)/%.o: $(DIR_SOURCE_C)/%.c | $(DIR_BUILD_OBJ) $(DIR_BUILD_DEP) $(DIR_NANOPB)
	$(MKDIR_SILENT) $(@D)
	$(MKDIR_SILENT) $(DIR_BUILD_DEP)/$(*D)
	$(CC) -o$@ $< -c $(CFLAGS)

$(DIR_SOURCE_C_PBGEN)/%.pb.c $(DIR_SOURCE_C_PBGEN)/%.pb.h: $(DIR_SOURCE_PROTO)/%.proto
	$(PROTOC) $< $(PROTOCFLAGS)

$(DIR_BUILD_DEP) $(DIR_BUILD_OBJ) $(DIR_BUILD_OUT):
	$(MKDIR) $@

$(DIR_NANOPB):
	$(CLONE) $(CLONEFLAGS) $(GIT_NANOPB) $(DIR_NANOPB)

clean:
	$(RM) $(DIR_BUILD) $(DIR_SOURCE_C_PBGEN)/* $(RM_FILE_NANOPB)

template:
	$(MKDIR) $(DIR_SOURCE) $(DIR_SOURCE_C) $(DIR_SOURCE_C_PBGEN) $(DIR_SOURCE_PROTO)
