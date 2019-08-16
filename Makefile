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
#       $(C_SOURCE_DIRECTORY)                                                    #
#                                                                                #
#   - generate protocol buffers C/C++ code with nanopb.                          #
#                                                                                #
#   - generate nanopb's repo in a way such that it can be used without actually  #
#       downloading or configuring their source code                             #
#                                                                                #
#   - toggle C/C++ language.                                                     #
#                                                                                #
#   - customize easily.                                                          #
#                                                                                #
#   - and more!                                                                  #
#                                                                                #
##################################################################################
##
## Usage:
##  - BUILDING THE TEMPLATE
##     - do 'make template' to generate the source directory
##
##     - add .proto files into the protocol buffer source directory.
##
##     - do 'make pb-gen' to create the nanopb pb.* files from the protocol
##       buffers in the protocol buffer directory.
##
##     - add source code anywhere in the C source directory. Add an entry point.
##
##     - do 'make' or 'make all' to generate an executable binary. 'make'
##       will run 'make all' which will compile protocol buffers, recompile
##       changed source code, and then relink all object files.
##
##  - MAINTAINING A PROJECT
##     - 'make help': shows this menu.
##
##     - 'make' or 'make all': generates everything.
##
##     - 'make root-symlink': generates a symbolic link from project root to
##       the executable.
##
##     - options can be set within the makefile for customizabilty / ease of
##       access
##
##################################################################################
#                                                                                #
# Key:                                                                           #
#  ALL_CAPS = makefile variable (DIR_ALL_CAPS or FILE_ALL_CAPS)                  #
#  lowercase = literal file/folder name, name independent of variables           #
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
#                                                                                #
#   Dependency tree diagram: (coming soon)                                       #
#                                                                                #
##################################################################################

# -- BOOLEAN OPTIONS (true or false) --

# on 'make clean', deletes nanopb
OPTION_SHOULD_DELETE_NANOPB_ON_CLEAN=true

# clones nanopb with silent output
OPTION_CLONE_SILENT=true

# uses C++ instead of C (enable CXX variables)
OPTION_USE_CPP=false

# creates symlink from project root to executable
OPTION_MAKE_TARGET_SYMLINK=true

# Lmao (for the big brains)
OPTION_USE_ENGLISH_OUTPUT=false

# -- CUSTOMIZABLE DIRECTORY STRUCTURE BASENAMES --

_DIR_SOURCE         =src
_DIR_SOURCE_C       =c
_DIR_SOURCE_C_PBGEN =pb_gen
_DIR_SOURCE_PROTO   =proto
_DIR_BUILD          =build
_DIR_BUILD_DEP      =dep
_DIR_BUILD_OBJ      =obj
_DIR_BUILD_OUT      =out
_FILE_TARGET        =main

# Target symlink basename. Only applicable if OPTION_MAKE_TARGET_SYMLINK is true.
TARGET_SYMLINK_NAME =$(_FILE_TARGET)

# Nanopb github repo
GIT_NANOPB          =https://github.com/nanopb/nanopb

# Nanopb local directory (customizable)
# NOTE: If local directory is outside of project root and is used by other projects,
#       disable OPTION_SHOULD_DELETE_NANOPB_ON_CLEAN
_DIR_NANOPB         =$(CURDIR)

# -- CUSTOMIZABLE COMMANDS / COMPILERS / COMPILER OPTIONS --

# NOTE: If you don't feel safe using rm -rf (even though it should only run
# on generated files), you can change this, but expect some errors
RM                  =rm -rf
MKDIR               =mkdir -p
MKDIR_SILENT        =@$(MKDIR)
ECHO                =@echo
SYMLINK             =ln -s

# IDK why this is here. It might be useful. Everything else is customizable.
CLONE               =git clone

# These are your compilers. If you like gcc/g++, use that. If you're not so classy
# and like clang/clang++, feel free to use those. If your super classy, just use cc.
# Of course, CXX will be used if OPTION_USE_CPP is true.
CC                  =gcc
LD                  =$(CC)
PROTOC              =protoc

CXX                 =g++
LDXX                =$(CXX)

CFLAGS_OPTIONS      =-ggdb -O0 -march=native -ftrapv
LDFLAGS_OPTIONS     =
PROTOCFLAGS_OPTIONS =
CLONEFLAGS_OPTIONS  =

# -- MISCELLANEOUS OPTIONS --

# The following is the search rule for files in the DIR_SOURCE_C directory.
# This should be in 'find command' format. For example:
# " -name '*.cpp' -o -name '*.cc' "
# searches all files that end in '.cpp' or '.c'.
# If you want extensions to be 'hidden', here's where to do it.
# EXTENSIONS_CXX will be used if OPTION_USE_CPP is true.
EXTENSIONS_C        =-name '*.c'
EXTENSIONS_CXX      =-name '*.cpp'

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

# plebeian lesson no. 1: Conditionals in makefile are majestic.
#                        Other forms exist.
#                        Only one is superior.

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

TARGET_SYMLINK_DEP_false     =
TARGET_SYMLINK_DEP_true      =$(TARGET_SYMLINK_NAME)
TARGET_SYMLINK_DEP           =$(TARGET_SYMLINK_DEP_$(OPTION_MAKE_TARGET_SYMLINK))

SOURCE_COMPILER_eng_false    =$(SOURCE_COMPILER_lang)
SOURCE_COMPILER_eng_true     =$(ECHO) "Compiling a source file"; $(SOURCE_COMPILER_lang)
SOURCE_COMPILER              =$(SOURCE_COMPILER_eng_$(OPTION_USE_ENGLISH_OUTPUT))

SOURCE_LINKER_eng_false      =$(SOURCE_LINKER_lang)
SOURCE_LINKER_eng_true       =$(ECHO) "Linking objects"; $(SOURCE_LINKER_lang)
SOURCE_LINKER                =$(SOURCE_LINKER_eng_$(OPTION_USE_ENGLISH_OUTPUT))

PROTO_COMPILER_eng_false     =$(PROTOC)
PROTO_COMPILER_eng_true      =$(ECHO) "Compiling proto"; $(PROTOC)
PROTO_COMPILER               =$(PROTO_COMPILER_eng_$(OPTION_USE_ENGLISH_OUTPUT))

REPO_CLONER_eng_false        =$(CLONE)
REPO_CLONER_eng_true         =$(ECHO) "Cloning a repo"; $(CLONE)
REPO_CLONER                  =$(REPO_CLONER_eng_$(OPTION_USE_ENGLISH_OUTPUT))

DIRECTORY_MAKER_eng_false    =$(MKDIR)
DIRECTORY_MAKER_eng_true     =$(ECHO) "Creating a directory"; $(MKDIR)
DIRECTORY_MAKER              =$(DIRECTORY_MAKER_eng_$(OPTION_USE_ENGLISH_OUTPUT))

FILE_DELETER_eng_false       =$(RM)
FILE_DELETER_eng_true        =$(ECHO) "Deleting some files"; $(RM)
FILE_DELETER                 =$(FILE_DELETER_eng_$(OPTION_USE_ENGLISH_OUTPUT))

SYMBOLIC_LINKER_eng_false    =$(SYMLINK)
SYMBOLIC_LINKER_eng_true     =$(ECHO) "Creating a symbolic link"; $(SYMLINK)
SYMBOLIC_LINKER              =$(SYMBOLIC_LINKER_eng_$(OPTION_USE_ENGLISH_OUTPUT))

# -- ADVANCED DIRECTORY STRUCTURE BASE/FILENAMES --

# Since of course we can't just use the directory structure basenames,
# this is where their full relative path is created. The basenames are for
# convenience. For example, if you're doing C++ and you feel offended by the
# presence of the 'c' folder, you only have to change it once. However, there
# is unfortunately nothing you can do about the makefile variables. They can
# be quite discriminatory at times.

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

# These variables store all source files of a specific type.
# PBGEN files are those that are created by nanopb using the protos.

FILE_SOURCE_PROTO   =$(shell find $(DIR_SOURCE_PROTO) -type f -name *.proto  2> /dev/null)
FILE_SOURCE_C       =$(shell find $(DIR_SOURCE_C)     -type f \( $(EXTENSIONS_SOURCE) \)  2> /dev/null)
FILE_SOURCE_C_PBGEN =$(patsubst $(DIR_SOURCE_PROTO)/%.proto,$(DIR_SOURCE_C_PBGEN)/%.pb.c,$(FILE_SOURCE_PROTO))

# If OPTION_USE_CPP is off or EXTENSIONS_C doesn't include "*.pb.c" or "*.c",
#     FILE_SOURCE_C will contain PBGEN files
# If OPTION_USE_CPP is on and EXTENSIONS_C includes "*.pb.c" or "*.c"
#     FILE_SOURCE_C won't contain PBGEN files
# Since PBGEN files also need to be treated like source code (compiled into objects and linked)
# FILE_SOURCE_C_ALL is a concatenation of both lists (in case FILE_SOURCE_C doesn't contain PBGEN)
# But if FILE_SOURCE_C does contain PBGEN, there will be duplicates
# Therefore, FILE_SOURCE_C_ALL is sorted to remove those duplicates.

FILE_SOURCE_C_ALL   =$(sort $(FILE_SOURCE_C) $(FILE_SOURCE_C_PBGEN))

FILE_OBJ            =$(patsubst $(DIR_SOURCE_C)/%,$(DIR_BUILD_OBJ)/%.o,$(FILE_SOURCE_C_ALL))
FILE_DEP            =$(patsubst $(DIR_SOURCE_C)/%,$(DIR_BUILD_DEP)/%.d,$(FILE_SOURCE_C_ALL))

# -- ADVANCED COMMANDS / COMPILERS / COMPILER OPTIONS --

# All git clone flags
CLONEFLAGS          =$(CLONEFLAGS_SILENT) $(CLONEFLAGS_OPTIONS)

# All C/C++ flags
CFLAGS_INCLUDE      =-I$(DIR_NANOPB)
CFLAGS_DEP          =-MMD -MP -MF$(DIR_BUILD_DEP)/$*.d# plebeian lesson no. 2: Search up the 'gcc' '-M' family of flags
CFLAGS              =$(CFLAGS_INCLUDE) $(CFLAGS_DEP) $(CFLAGS_OPTIONS)

# All linker flags
LDFLAGS             =$(LDFLAGS_OPTIONS)

# All protoc flags
PROTOCFLAGS_PLUGIN  =--plugin=$(DIR_NANOPB)/generator/protoc-gen-nanopb
PROTOCFLAGS_INCLUDE =-I$(DIR_SOURCE_PROTO)
PROTOCFLAGS_OUT     =--nanopb_out=$(DIR_SOURCE_C_PBGEN)
PROTOCFLAGS         =$(PROTOCFLAGS_PLUGIN) $(PROTOCFLAGS_INCLUDE) $(PROTOCFLAGS_OUT) $(PROTOCFLAGS_OPTIONS)

# -- MISCELLANEOUS --

# Include generated dependencies
-include $(FILE_DEP)

.DEFAULT_GOAL=all
.PHONY: clean
.PRECIOUS: $(FILE_SOURCE_C_PBGEN) # FILE_SOURCE_C_PBGEN is PRECIOUS because it can be treated as an intermediate file.

# -- FRONTEND RULES --

# Prints the '##' documentation lines at the beginning of the makefile if 'make help' is run
help:
	@sed -ne '/@sed/!s/## //p' $(MAKEFILE_LIST)

# Generates DIR_SOURCE and subdirectories
template:
	$(MKDIR) $(DIR_SOURCE) $(DIR_SOURCE_C) $(DIR_SOURCE_PROTO)

# Generates .pb.* files
pb-gen: $(SOURCE_C_PBGEN)

# Generate EVERYTHING
all: $(FILE_TARGET) $(TARGET_SYMLINK_DEP)

# Clean all generated files
clean:
	$(FILE_DELETER) $(DIR_BUILD) $(DIR_SOURCE_C_PBGEN) $(RM_FILE_NANOPB) $(TARGET_SYMLINK_NAME)

# Generate the symlink at root, regardless of OPTION_MAKE_TARGET_SYMLINK
# NOTE: OPTION_MAKE_TARGET_SYMLINK is only for making symlink when 'make all' is run
root-symlink: $(TARGET_SYMLINK_NAME)

# -- BACKEND / CREATION RULES AND DEPENDENCIES --

# Generate executable (links object files)
$(FILE_TARGET): $(FILE_OBJ) | $(DIR_BUILD_OUT)
	$(SOURCE_LINKER) -o$@ $^ $(LDFLAGS)
	$(ECHO) "-- Built executable $@ --"

# Generates compiled object files and dependency makefile rules
$(DIR_BUILD_OBJ)/%.o: $(DIR_SOURCE_C)/% | $(DIR_BUILD_OBJ) $(DIR_BUILD_DEP) $(DIR_NANOPB)
	$(DIRECTORY_MAKER) $(@D)
	$(DIRECTORY_MAKER) $(DIR_BUILD_DEP)/$(*D)
	$(SOURCE_COMPILER) -o$@ $< -c $(CFLAGS)

# Generate protocol buffers C code with nanopb
$(DIR_SOURCE_C_PBGEN)/%.pb.c $(DIR_SOURCE_C_PBGEN)/%.pb.h: $(DIR_SOURCE_PROTO)/%.proto | $(DIR_SOURCE_C_PBGEN)
	$(PROTO_COMPILER) $< $(PROTOCFLAGS)

# Generates missing directories
$(DIR_SOURCE_C_PBGEN) $(DIR_BUILD_DEP) $(DIR_BUILD_OBJ) $(DIR_BUILD_OUT):
	$(DIRECTORY_MAKER) $@

# Generates missing nanopb directory
$(DIR_NANOPB):
	$(REPO_CLONER) $(CLONEFLAGS) $(GIT_NANOPB) $(DIR_NANOPB)

# Generate the symlink
$(TARGET_SYMLINK_NAME):
	$(SYMBOLIC_LINKER) $(FILE_TARGET) $(TARGET_SYMLINK_NAME)

