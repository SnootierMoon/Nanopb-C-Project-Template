##################################################################################
#                                                                                #
# Author: Akshay Trivedi                                                         #
#                                                                                #
#    https://github.com/SnootierMoon/Nanopb-C-Project-Template                   #
#                                                                                #
# Simple-complex C/C++ Nanopb makefile                                           #
#                                                                                #
# Ability to:                                                                    #
#   - generate dependencies and compile only changed C/C++ files in              #
#     $(C_SOURCE_DIRECTORY),                                                     #
#                                                                                #
#   - generate protocol buffers C/C++ code with nanopb,                          #
#                                                                                #
#   - generate nanopb's repo in a way such that it can be used without actually, #
#     downloading or configuring their source code,                              #
#                                                                                #
#   - toggle C/C++ language,                                                     #
#                                                                                #
#   - customize easily,                                                          #
#                                                                                #
#   - and more!                                                                  #
#                                                                                #
##################################################################################
#  THE FOLLOWING IS PRINTED USING 'make help'
##
## Usage:
##  - GETTING STARTED
##     - This project only requires protoc and an understanding of protocol
##       buffers to work.
##
##  - BUILDING THE TEMPLATE
##     - Do 'make template' to generate the source directory.
##
##     - Add protocol buffer files into the protocol buffer source directory.
##
##     - Do 'make pb-gen' to create the nanopb *.pb.c *.pb.h files from the protocol
##       buffers in the protocol buffer directory.
##
##     - Add source code anywhere in the C source directory and add an entry point.
##
##     - Do 'make' or 'make all' to generate an executable binary. 'make'
##       will run 'make all' which will compile protocol buffers, recompile
##       changed source code, and then relink all object files.
##
##  - CUSTOMIZABILITY
##
##     - The makefile is highly customizable. options in the makefile allow for
##       simple frontend modifications to tweak how files are generated.
##       open the makefile for more info.
##
##  - MAINTAINING A PROJECT
##     - The complete executable will be in the build out directory. You can make
##       this makefile automatically create a symlink to it using a makefile option.
##
##     - Switching from C to C++: simply set the option in the makefile.
##
##     - 'make help': shows this menu.
##
##     - 'make' or 'make all': generates everything.
##
##     - 'make clean': deletes all generated files.
##
##     - 'make remake': 'make clean's and then 'make all's.
##
##     - 'make root-symlink': generates a symbolic link from project root to
##       the executable.
##
##     - More options can be set within the makefile for customizabilty / ease of
##       access.
##
##################################################################################
#                                                                                #
# Key:                                                                           #
#  ALL_CAPS   = makefile variable                                                #
#  lowercase  = literal file/folder name, name independent of variables          #
#  [brackets] = description of file/folder contents                              #
#                                                                                #
#                                                                                #
# Directory Structure Diagram:                                                   #
#                                                                                #
#   DIR_NANOPB [nanopb source code]                                              #
#   |__ generator                                                                #
#   |   |__ protoc-gen-nanopb [protoc plugin]                                    #
#   |__ pb_common.h pb_common.c                                                  #
#   |__ pb_encode.h pb_encode.c                                                  #
#   |__ pb_decode.h pb_decode.c                                                  #
#   |__ pb.h                                                                     #
#   |__ * [other (irrelevant) nanopb files]                                      #
#                                                                                #
#   . [project root]                                                             #
#   |__ BUILD [contains all dependent non-source files]                          #
#   |   |__ DEP                                                                  #
#   |   |   |__ NANOPB [generated nanopb dependency files]                       #
#   |   |   |   |__ pb_common.c.d pb_encode.c.d pb_decode.c.d                    #
#   |   |   |__ src/c                                                            #
#   |   |       |__ *.d [generated dependency files]                             #
#   |   |__ OBJ                                                                  #
#   |   |   |__ NANOPB [generated nanopb object files]                           #
#   |   |   |   |__ pb_common.c.d pb_encode.c.d pb_decode.c.d                    #
#   |   |   |__ src/c                                                            #
#   |   |       |__ *.o [generated object files]                                 #
#   |   |__ OUT                                                                  #
#   |       |__ TARGET [generated exectuable]                                    #
#   |__ SOURCE [contains all source code]                                        #
#   |   |__ C [contains ALL C source code]                                       #
#   |   |   |__ *.c *.h [original source code]                                   #
#   |   |   |__ PBGEN                                                            #
#   |   |       |__ *.pb.h *.pb.c [generated protobuf C source]                  #
#   |   |__ PROTO                                                                #
#   |       |__ *.proto [original protobuf source]                               #
#   |__ Makefile [you are here]                                                  #
#                                                                                #
##################################################################################

# -- BOOLEAN OPTIONS (true / false) --

# When 'make clean' is called, deletes $(NANOPB_DIR).
# NOTE: Recommended if $(NANOPB_DIR) is a subdirectory of project root.
#         This allows your repo to only contain your source code.
#       Not recommended if $(DIR_NANOPB) is being used by another project
#         (if it's outside of project root, and other projects use it).
OPTION_SHOULD_DELETE_NANOPB_ON_CLEAN =true

# When cloning $(NANOPB_DIR), silences git output.
OPTION_CLONE_SILENT                  =true

# Use C++ instead of C.
# if $(OPTION_USE_CPP) is off:
#     $(EXTENSIONS_C) will be used to find source (.c) files,
#     $(CC) will be used to compile source files and
#     $(LD) will be used to link object (.o) files off.
# if $(OPTION_USE_CPP) is on:
#     $(EXTENSIONS_CPP) will be used to find source (.cpp) files,
#     $(CXX) will be used to compile source files and
#     $(LDXX) will be used to link object (.o) files off.
OPTION_USE_CPP                       =false

# Use the -e linker flag for multiple entry points.
# WARNING: Since _start won't be called, you must call exit(0)
#          at the end of the entry point.
OPTION_MULTIPLE_ENTRY_POINTS         =false

# Creates a symlink to the built executable.
# If $(OPTION_MULTIPLE_ENTRY_POINTS) is true, multiple symlinks are
# created.
# The name of the symlink is the name of the executable (see $(_FILE_TARGET)).
OPTION_MAKE_TARGET_SYMLINK           =false

# Lmao (big brains only)
OPTION_USE_ENGLISH_OUTPUT            =false

# -- DIRECTORY STRUCTURE (basenames) --

# LIMITATION: $(_DIR_SOURCE) cannot be $(NANOPB).
# LIMITATION: $(_FILE_TARGET) cannot be the name of a directory in project root
#             if $(OPTION_MAKE_TARGET_SYMLINK) is on.
# NOTE: $(DIR_BUILD_DEP) can be $(DIR_BUILD_OBJ)
#       this will cause dependencies (.d) and object (.o) files to be in the
#       same directory.
_DIR_SOURCE         =src
_DIR_SOURCE_C       =c
_DIR_SOURCE_C_PBGEN =pb_gen
_DIR_SOURCE_PROTO   =proto
_DIR_BUILD          =build
_DIR_BUILD_DEP      =dep
_DIR_BUILD_OBJ      =obj
_DIR_BUILD_OUT      =out
_FILE_TARGET        =main

# $(NANOPB) is the subdirectory in which generated .d and .o files will be stored
#     in the $(DIR_BUILD_DEP) and $(DIR_BUILD_OBJ) folders for .c files in
#     $(DIR_NANOPB).
# $(DIR_NANOPB) is the directory into which the nanopb repo should be or is
# installed.
NANOPB              =nanopb
GIT_NANOPB          =https://github.com/nanopb/nanopb
DIR_NANOPB          =$(CURDIR)/$(NANOPB)

# -- COMMANDS, TOOLS AND FLAGS --

RM                  =rm -rf
MKDIR               =mkdir -p
ECHO                =@echo
SYMLINK             =ln -s
CLONE               =git clone
PROTOC              =protoc

# See $(OPTIONS_USE_CPP).
CC                  =gcc
LD                  =$(CC)
EXTENSIONS_C        =-name '*.c'
CXX                 =g++
LDXX                =$(CXX)
EXTENSIONS_CXX      =-name '*.cpp'

# Extra flags for extra customization

CFLAGS_OPTIONS      =-ggdb -O0 -march=native -ftrapv
LDFLAGS_OPTIONS     =
PROTOCFLAGS_OPTIONS =
CLONEFLAGS_OPTIONS  =

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

# -- OPTION APPLICATION --

RM_FILE_NANOPB_false         =
RM_FILE_NANOPB_true          =$(DIR_NANOPB)
RM_FILE_NANOPB               =$(RM_FILE_NANOPB_$(OPTION_SHOULD_DELETE_NANOPB_ON_CLEAN))

CLONEFLAGS_SILENT_false      =
CLONEFLAGS_SILENT_true       =-q
CLONEFLAGS_SILENT            =$(CLONEFLAGS_SILENT_$(OPTION_CLONE_SILENT))

SOURCE_COMPILER_lang_false   =$(CC)
SOURCE_COMPILER_lang_true    =$(CXX)
SOURCE_COMPILER_lang         =$(SOURCE_COMPILER_lang_$(OPTION_USE_CPP))

SOURCE_LINKER_lang_false     =$(LD)
SOURCE_LINKER_lang_true      =$(LDXX)
SOURCE_LINKER_lang           =$(SOURCE_LINKER_lang_$(OPTION_USE_CPP))

EXTENSIONS_SOURCE_lang_false =$(EXTENSIONS_C)
EXTENSIONS_SOURCE_lang_true  =$(EXTENSIONS_CXX)
EXTENSIONS_SOURCE            =$(EXTENSIONS_SOURCE_lang_$(OPTION_USE_CPP))

LDFLAGS_ENTRY_POINT_false     =
LDFLAGS_ENTRY_POINT_true      =-e$(notdir $@)
LDFLAGS_ENTRY_POINT           =$(LDFLAGS_ENTRY_POINT_$(OPTION_MULTIPLE_ENTRY_POINTS))

TARGET_SYMLINK_DEP_false     =
TARGET_SYMLINK_DEP_true      =$(_FILE_TARGET)
TARGET_SYMLINK_DEP           =$(TARGET_SYMLINK_DEP_$(OPTION_MAKE_TARGET_SYMLINK))

SOURCE_COMPILER_eng_false    =$(SOURCE_COMPILER_lang)
SOURCE_COMPILER_eng_true     =$(ECHO) 'Compiling a source file'; $(SOURCE_COMPILER_lang)
SOURCE_COMPILER              =$(SOURCE_COMPILER_eng_$(OPTION_USE_ENGLISH_OUTPUT))

SOURCE_LINKER_eng_false      =$(SOURCE_LINKER_lang)
SOURCE_LINKER_eng_true       =$(ECHO) 'Linking objects'; $(SOURCE_LINKER_lang)
SOURCE_LINKER                =$(SOURCE_LINKER_eng_$(OPTION_USE_ENGLISH_OUTPUT))

PROTO_COMPILER_eng_false     =$(PROTOC)
PROTO_COMPILER_eng_true      =$(ECHO) 'Compiling proto'; $(PROTOC)
PROTO_COMPILER               =$(PROTO_COMPILER_eng_$(OPTION_USE_ENGLISH_OUTPUT))

REPO_CLONER_eng_false        =$(CLONE)
REPO_CLONER_eng_true         =$(ECHO) 'Cloning a repo'; $(CLONE)
REPO_CLONER                  =$(REPO_CLONER_eng_$(OPTION_USE_ENGLISH_OUTPUT))

DIRECTORY_MAKER_eng_false    =$(MKDIR)
DIRECTORY_MAKER_eng_true     =$(ECHO) 'Creating a directory'; $(MKDIR)
DIRECTORY_MAKER              =$(DIRECTORY_MAKER_eng_$(OPTION_USE_ENGLISH_OUTPUT))

FILE_DELETER_eng_false       =$(RM)
FILE_DELETER_eng_true        =$(ECHO) 'Deleting some files'; $(RM)
FILE_DELETER                 =$(FILE_DELETER_eng_$(OPTION_USE_ENGLISH_OUTPUT))

SYMBOLIC_LINKER_eng_false    =$(SYMLINK)
SYMBOLIC_LINKER_eng_true     =$(ECHO) 'Creating a symbolic link'; $(SYMLINK)
SYMBOLIC_LINKER              =$(SYMBOLIC_LINKER_eng_$(OPTION_USE_ENGLISH_OUTPUT))

# -- DIRECTORY STRUCTURE (full paths) --

DIR_SOURCE                =$(_DIR_SOURCE)
DIR_SOURCE_C              =$(addprefix $(DIR_SOURCE)/,$(_DIR_SOURCE_C))
DIR_SOURCE_C_PBGEN        =$(addprefix $(DIR_SOURCE_C)/,$(_DIR_SOURCE_C_PBGEN))
DIR_SOURCE_PROTO          =$(addprefix $(DIR_SOURCE)/,$(_DIR_SOURCE_PROTO))
DIR_BUILD                 =$(_DIR_BUILD)
DIR_BUILD_DEP             =$(addprefix $(DIR_BUILD)/,$(_DIR_BUILD_DEP))
DIR_BUILD_OBJ             =$(addprefix $(DIR_BUILD)/,$(_DIR_BUILD_OBJ))
DIR_BUILD_OUT             =$(addprefix $(DIR_BUILD)/,$(_DIR_BUILD_OUT))
FILE_TARGET               =$(addprefix $(DIR_BUILD_OUT)/,$(_FILE_TARGET))

# See $(NANOPB).
DIR_BUILD_DEP_NANOPB      =$(addsuffix /$(NANOPB),$(DIR_BUILD_DEP))
DIR_BUILD_OBJ_NANOPB      =$(addsuffix /$(NANOPB),$(DIR_BUILD_OBJ))

# Scans source files.
FILE_SOURCE_PROTO         =$(shell find $(DIR_SOURCE_PROTO) -type f -name *.proto  2> /dev/null)
FILE_SOURCE_C             =$(shell find $(DIR_SOURCE_C)     -type f \( $(EXTENSIONS_SOURCE) \)  2> /dev/null)
FILE_SOURCE_C_PBGEN       =$(patsubst $(DIR_SOURCE_PROTO)/%.proto,$(DIR_SOURCE_C_PBGEN)/%.pb.c,$(FILE_SOURCE_PROTO))

# Differentiate between source files in $(DIR_NANOPB) and in $(DIR_SOURCE_C).
# $(FILE_SOURCE_C_NANOPB_REAL) has $(DIR_NANOPB) as a suffix (so it's the real .c files).
# $(FILE_SOURCE_C_NANOPB) has $(NANOPB) as a suffix (so it's suffix is what get's put in $(DIR_BUILD_DEP)
#     and $(DIR_BUILD_OBJ)).
FILE_SOURCE_C_NOT_NANOPB  =$(sort $(FILE_SOURCE_C) $(FILE_SOURCE_C_PBGEN))
FILE_SOURCE_C_NANOPB_REAL =$(patsubst %,$(DIR_NANOPB)/%.c,pb_common pb_encode pb_decode)
FILE_SOURCE_C_NANOPB      =$(patsubst %,$(NANOPB)/%.c,pb_common pb_encode pb_decode)

# These are all source files, and for it's purpose (to be patsubst'd into $(FILE_OBJ) and $(FILE_DEP)),
#     it needs to use $(FILE_SOURCE_C_NANOPB) instead of $(FILE_SOURCE_C_NANOPB_REAL).
FILE_SOURCE_C_ALL         =$(FILE_SOURCE_C_NOT_NANOPB) $(FILE_SOURCE_C_NANOPB)

# $(FILE_DEP) is simply the list of dependencies for all source files
FILE_DEP                  =$(patsubst %,$(DIR_BUILD_DEP)/%.d,$(FILE_SOURCE_C_ALL))

# Differentiates between nanopb source and not-nanopb source, because nanopb source needs
#     to be compiled into $(DIR_OBJ_NANOPB) instead of $(DIR_OBJ)/$(DIR_NANOPB).
FILE_OBJ_NOT_NANOPB       =$(patsubst %,$(DIR_BUILD_OBJ)/%.o,$(FILE_SOURCE_C_NOT_NANOPB))
FILE_OBJ_NANOPB           =$(patsubst %,$(DIR_BUILD_OBJ)/%.o,$(FILE_SOURCE_C_NANOPB))

# $(FILE_OBJ) is simply the list of objects for all source files.
FILE_OBJ                  =$(FILE_OBJ_NOT_NANOPB) $(FILE_OBJ_NANOPB)

# Directories needed to create dependencies and objects.
FILE_DEP_DIRS             =$(sort $(dir $(FILE_DEP)))
FILE_OBJ_DIRS             =$(sort $(dir $(FILE_OBJ)))

# -- FINAL FLAGS --

CLONEFLAGS          =$(CLONEFLAGS_SILENT) $(CLONEFLAGS_OPTIONS)

CFLAGS_INCLUDE      =-I$(DIR_NANOPB)
CFLAGS              =$(CFLAGS_INCLUDE) $(CFLAGS_OPTIONS)

LDFLAGS             =$(LDFLAGS_ENTRY_POINT) $(LDFLAGS_OPTIONS)

PROTOCFLAGS_PLUGIN  =--plugin=$(DIR_NANOPB)/generator/protoc-gen-nanopb
PROTOCFLAGS_INCLUDE =-I$(DIR_SOURCE_PROTO)
PROTOCFLAGS_OUT     =--nanopb_out=$(DIR_SOURCE_C_PBGEN)
PROTOCFLAGS         =$(PROTOCFLAGS_PLUGIN) $(PROTOCFLAGS_INCLUDE) $(PROTOCFLAGS_OUT) $(PROTOCFLAGS_OPTIONS)

# -- FRONTEND MAKE RULES --

.DEFAULT_GOAL=all
.PHONY: clean
.PRECIOUS: $(FILE_SOURCE_C_PBGEN) $(FILE_SOURCE_C_NANOPB_REAL)

help:
	@sed -ne '/@sed/!s/## //p' $(MAKEFILE_LIST)

template:
	$(MKDIR) $(DIR_SOURCE) $(DIR_SOURCE_C) $(DIR_SOURCE_PROTO)
	$(ECHO) 'int main() {\n}\n' > $(DIR_SOURCE_C)/main.c
	$(ECHO) "do 'make' to compile"

pb-gen: $(SOURCE_C_PBGEN)

all: $(FILE_TARGET) $(TARGET_SYMLINK_DEP)

clean:
	$(FILE_DELETER) $(DIR_BUILD) $(DIR_SOURCE_C_PBGEN) $(RM_FILE_NANOPB) $(TARGET_SYMLINK_DEP)

remake: clean all

root-symlink: $(_FILE_TARGET)

# -- FILE GENERATION MAKE RULES --

# Includes all dependencies.
-include $(FILE_DEP)

$(FILE_TARGET): $(FILE_OBJ) | $(DIR_BUILD_OUT)
	$(SOURCE_LINKER) -o$@ $^ $(LDFLAGS)
	$(ECHO) '-- Built executable $@ --'

$(FILE_OBJ_NOT_NANOPB): $(DIR_BUILD_OBJ)/%.o: % $(FILE_SOURCE_C_PBGEN) | $(FILE_DEP_DIRS) $(FILE_OBJ_DIRS)
	$(SOURCE_COMPILER) -o$@ $< -c $(CFLAGS) -MMD -MP -MF$(DIR_BUILD_DEP)/$*.d

$(FILE_OBJ_NANOPB): $(DIR_BUILD_OBJ_NANOPB)/%.o: $(DIR_NANOPB)/% | $(DIR_NANOPB) $(DIR_BUILD_DEP_NANOPB) $(DIR_BUILD_OBJ_NANOPB)
	$(SOURCE_COMPILER) -o$@ $< -c $(CFLAGS) -MMD -MP -MF$(DIR_BUILD_DEP_NANOPB)/$*.d

$(DIR_NANOPB)/%.c: | $(DIR_NANOPB)
	@echo

$(DIR_SOURCE_C_PBGEN)/%.pb.c $(DIR_SOURCE_C_PBGEN)/%.pb.h: $(DIR_SOURCE_PROTO)/%.proto | $(DIR_SOURCE_C_PBGEN) $(DIR_NANOPB)
	$(PROTO_COMPILER) $< $(PROTOCFLAGS)

$(DIR_SOURCE_C_PBGEN) $(DIR_BUILD_DEP) $(DIR_BUILD_OBJ) $(DIR_BUILD_OUT) $(FILE_DEP_DIRS) $(FILE_OBJ_DIRS) $(DIR_BUILD_DEP_NANOPB) $(DIR_BUILD_OBJ_NANOPB):
	$(DIRECTORY_MAKER) $@

$(DIR_NANOPB):
	$(REPO_CLONER) $(CLONEFLAGS) $(GIT_NANOPB) $(DIR_NANOPB)

$(TARGET_SYMLINK_NAME):
	$(SYMBOLIC_LINKER) $(DIR_BUILD_OUT)/$@ $@
