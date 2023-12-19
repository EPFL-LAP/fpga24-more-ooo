# CMAKE generated file: DO NOT EDIT!
# Generated by "Unix Makefiles" Generator, CMake Version 3.10

# Delete rule output on recipe failure.
.DELETE_ON_ERROR:


#=============================================================================
# Special targets provided by cmake.

# Disable implicit rules so canonical targets will work.
.SUFFIXES:


# Remove some rules from gmake that .SUFFIXES does not remove.
SUFFIXES =

.SUFFIXES: .hpux_make_needs_suffix_list


# Suppress display of executed commands.
$(VERBOSE).SILENT:


# A target that is always out of date.
cmake_force:

.PHONY : cmake_force

#=============================================================================
# Set environment variables for the build.

# The shell in which to execute make rules.
SHELL = /bin/sh

# The CMake executable.
CMAKE_COMMAND = /usr/bin/cmake

# The command to remove a file.
RM = /usr/bin/cmake -E remove -f

# Escaping for special characters.
EQUALS = =

# The top-level source directory on which CMake was run.
CMAKE_SOURCE_DIR = /home/dynamatic/Dynamatic/etc/dynamatic/elastic-circuits

# The top-level build directory on which CMake was run.
CMAKE_BINARY_DIR = /home/dynamatic/Dynamatic/etc/dynamatic/elastic-circuits/_build

# Include any dependencies generated for this target.
include OptimizeBitwidth/CMakeFiles/LLVMOptimizeBitWidth.dir/depend.make

# Include the progress variables for this target.
include OptimizeBitwidth/CMakeFiles/LLVMOptimizeBitWidth.dir/progress.make

# Include the compile flags for this target's objects.
include OptimizeBitwidth/CMakeFiles/LLVMOptimizeBitWidth.dir/flags.make

OptimizeBitwidth/CMakeFiles/LLVMOptimizeBitWidth.dir/OptimizeBitwidth.cpp.o: OptimizeBitwidth/CMakeFiles/LLVMOptimizeBitWidth.dir/flags.make
OptimizeBitwidth/CMakeFiles/LLVMOptimizeBitWidth.dir/OptimizeBitwidth.cpp.o: ../OptimizeBitwidth/OptimizeBitwidth.cpp
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir=/home/dynamatic/Dynamatic/etc/dynamatic/elastic-circuits/_build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_1) "Building CXX object OptimizeBitwidth/CMakeFiles/LLVMOptimizeBitWidth.dir/OptimizeBitwidth.cpp.o"
	cd /home/dynamatic/Dynamatic/etc/dynamatic/elastic-circuits/_build/OptimizeBitwidth && /usr/bin/c++  $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -o CMakeFiles/LLVMOptimizeBitWidth.dir/OptimizeBitwidth.cpp.o -c /home/dynamatic/Dynamatic/etc/dynamatic/elastic-circuits/OptimizeBitwidth/OptimizeBitwidth.cpp

OptimizeBitwidth/CMakeFiles/LLVMOptimizeBitWidth.dir/OptimizeBitwidth.cpp.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing CXX source to CMakeFiles/LLVMOptimizeBitWidth.dir/OptimizeBitwidth.cpp.i"
	cd /home/dynamatic/Dynamatic/etc/dynamatic/elastic-circuits/_build/OptimizeBitwidth && /usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -E /home/dynamatic/Dynamatic/etc/dynamatic/elastic-circuits/OptimizeBitwidth/OptimizeBitwidth.cpp > CMakeFiles/LLVMOptimizeBitWidth.dir/OptimizeBitwidth.cpp.i

OptimizeBitwidth/CMakeFiles/LLVMOptimizeBitWidth.dir/OptimizeBitwidth.cpp.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling CXX source to assembly CMakeFiles/LLVMOptimizeBitWidth.dir/OptimizeBitwidth.cpp.s"
	cd /home/dynamatic/Dynamatic/etc/dynamatic/elastic-circuits/_build/OptimizeBitwidth && /usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -S /home/dynamatic/Dynamatic/etc/dynamatic/elastic-circuits/OptimizeBitwidth/OptimizeBitwidth.cpp -o CMakeFiles/LLVMOptimizeBitWidth.dir/OptimizeBitwidth.cpp.s

OptimizeBitwidth/CMakeFiles/LLVMOptimizeBitWidth.dir/OptimizeBitwidth.cpp.o.requires:

.PHONY : OptimizeBitwidth/CMakeFiles/LLVMOptimizeBitWidth.dir/OptimizeBitwidth.cpp.o.requires

OptimizeBitwidth/CMakeFiles/LLVMOptimizeBitWidth.dir/OptimizeBitwidth.cpp.o.provides: OptimizeBitwidth/CMakeFiles/LLVMOptimizeBitWidth.dir/OptimizeBitwidth.cpp.o.requires
	$(MAKE) -f OptimizeBitwidth/CMakeFiles/LLVMOptimizeBitWidth.dir/build.make OptimizeBitwidth/CMakeFiles/LLVMOptimizeBitWidth.dir/OptimizeBitwidth.cpp.o.provides.build
.PHONY : OptimizeBitwidth/CMakeFiles/LLVMOptimizeBitWidth.dir/OptimizeBitwidth.cpp.o.provides

OptimizeBitwidth/CMakeFiles/LLVMOptimizeBitWidth.dir/OptimizeBitwidth.cpp.o.provides.build: OptimizeBitwidth/CMakeFiles/LLVMOptimizeBitWidth.dir/OptimizeBitwidth.cpp.o


OptimizeBitwidth/CMakeFiles/LLVMOptimizeBitWidth.dir/info.cpp.o: OptimizeBitwidth/CMakeFiles/LLVMOptimizeBitWidth.dir/flags.make
OptimizeBitwidth/CMakeFiles/LLVMOptimizeBitWidth.dir/info.cpp.o: ../OptimizeBitwidth/info.cpp
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir=/home/dynamatic/Dynamatic/etc/dynamatic/elastic-circuits/_build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_2) "Building CXX object OptimizeBitwidth/CMakeFiles/LLVMOptimizeBitWidth.dir/info.cpp.o"
	cd /home/dynamatic/Dynamatic/etc/dynamatic/elastic-circuits/_build/OptimizeBitwidth && /usr/bin/c++  $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -o CMakeFiles/LLVMOptimizeBitWidth.dir/info.cpp.o -c /home/dynamatic/Dynamatic/etc/dynamatic/elastic-circuits/OptimizeBitwidth/info.cpp

OptimizeBitwidth/CMakeFiles/LLVMOptimizeBitWidth.dir/info.cpp.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing CXX source to CMakeFiles/LLVMOptimizeBitWidth.dir/info.cpp.i"
	cd /home/dynamatic/Dynamatic/etc/dynamatic/elastic-circuits/_build/OptimizeBitwidth && /usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -E /home/dynamatic/Dynamatic/etc/dynamatic/elastic-circuits/OptimizeBitwidth/info.cpp > CMakeFiles/LLVMOptimizeBitWidth.dir/info.cpp.i

OptimizeBitwidth/CMakeFiles/LLVMOptimizeBitWidth.dir/info.cpp.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling CXX source to assembly CMakeFiles/LLVMOptimizeBitWidth.dir/info.cpp.s"
	cd /home/dynamatic/Dynamatic/etc/dynamatic/elastic-circuits/_build/OptimizeBitwidth && /usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -S /home/dynamatic/Dynamatic/etc/dynamatic/elastic-circuits/OptimizeBitwidth/info.cpp -o CMakeFiles/LLVMOptimizeBitWidth.dir/info.cpp.s

OptimizeBitwidth/CMakeFiles/LLVMOptimizeBitWidth.dir/info.cpp.o.requires:

.PHONY : OptimizeBitwidth/CMakeFiles/LLVMOptimizeBitWidth.dir/info.cpp.o.requires

OptimizeBitwidth/CMakeFiles/LLVMOptimizeBitWidth.dir/info.cpp.o.provides: OptimizeBitwidth/CMakeFiles/LLVMOptimizeBitWidth.dir/info.cpp.o.requires
	$(MAKE) -f OptimizeBitwidth/CMakeFiles/LLVMOptimizeBitWidth.dir/build.make OptimizeBitwidth/CMakeFiles/LLVMOptimizeBitWidth.dir/info.cpp.o.provides.build
.PHONY : OptimizeBitwidth/CMakeFiles/LLVMOptimizeBitWidth.dir/info.cpp.o.provides

OptimizeBitwidth/CMakeFiles/LLVMOptimizeBitWidth.dir/info.cpp.o.provides.build: OptimizeBitwidth/CMakeFiles/LLVMOptimizeBitWidth.dir/info.cpp.o


OptimizeBitwidth/CMakeFiles/LLVMOptimizeBitWidth.dir/deps.cpp.o: OptimizeBitwidth/CMakeFiles/LLVMOptimizeBitWidth.dir/flags.make
OptimizeBitwidth/CMakeFiles/LLVMOptimizeBitWidth.dir/deps.cpp.o: ../OptimizeBitwidth/deps.cpp
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir=/home/dynamatic/Dynamatic/etc/dynamatic/elastic-circuits/_build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_3) "Building CXX object OptimizeBitwidth/CMakeFiles/LLVMOptimizeBitWidth.dir/deps.cpp.o"
	cd /home/dynamatic/Dynamatic/etc/dynamatic/elastic-circuits/_build/OptimizeBitwidth && /usr/bin/c++  $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -o CMakeFiles/LLVMOptimizeBitWidth.dir/deps.cpp.o -c /home/dynamatic/Dynamatic/etc/dynamatic/elastic-circuits/OptimizeBitwidth/deps.cpp

OptimizeBitwidth/CMakeFiles/LLVMOptimizeBitWidth.dir/deps.cpp.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing CXX source to CMakeFiles/LLVMOptimizeBitWidth.dir/deps.cpp.i"
	cd /home/dynamatic/Dynamatic/etc/dynamatic/elastic-circuits/_build/OptimizeBitwidth && /usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -E /home/dynamatic/Dynamatic/etc/dynamatic/elastic-circuits/OptimizeBitwidth/deps.cpp > CMakeFiles/LLVMOptimizeBitWidth.dir/deps.cpp.i

OptimizeBitwidth/CMakeFiles/LLVMOptimizeBitWidth.dir/deps.cpp.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling CXX source to assembly CMakeFiles/LLVMOptimizeBitWidth.dir/deps.cpp.s"
	cd /home/dynamatic/Dynamatic/etc/dynamatic/elastic-circuits/_build/OptimizeBitwidth && /usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -S /home/dynamatic/Dynamatic/etc/dynamatic/elastic-circuits/OptimizeBitwidth/deps.cpp -o CMakeFiles/LLVMOptimizeBitWidth.dir/deps.cpp.s

OptimizeBitwidth/CMakeFiles/LLVMOptimizeBitWidth.dir/deps.cpp.o.requires:

.PHONY : OptimizeBitwidth/CMakeFiles/LLVMOptimizeBitWidth.dir/deps.cpp.o.requires

OptimizeBitwidth/CMakeFiles/LLVMOptimizeBitWidth.dir/deps.cpp.o.provides: OptimizeBitwidth/CMakeFiles/LLVMOptimizeBitWidth.dir/deps.cpp.o.requires
	$(MAKE) -f OptimizeBitwidth/CMakeFiles/LLVMOptimizeBitWidth.dir/build.make OptimizeBitwidth/CMakeFiles/LLVMOptimizeBitWidth.dir/deps.cpp.o.provides.build
.PHONY : OptimizeBitwidth/CMakeFiles/LLVMOptimizeBitWidth.dir/deps.cpp.o.provides

OptimizeBitwidth/CMakeFiles/LLVMOptimizeBitWidth.dir/deps.cpp.o.provides.build: OptimizeBitwidth/CMakeFiles/LLVMOptimizeBitWidth.dir/deps.cpp.o


# Object files for target LLVMOptimizeBitWidth
LLVMOptimizeBitWidth_OBJECTS = \
"CMakeFiles/LLVMOptimizeBitWidth.dir/OptimizeBitwidth.cpp.o" \
"CMakeFiles/LLVMOptimizeBitWidth.dir/info.cpp.o" \
"CMakeFiles/LLVMOptimizeBitWidth.dir/deps.cpp.o"

# External object files for target LLVMOptimizeBitWidth
LLVMOptimizeBitWidth_EXTERNAL_OBJECTS =

OptimizeBitwidth/libLLVMOptimizeBitWidth.so: OptimizeBitwidth/CMakeFiles/LLVMOptimizeBitWidth.dir/OptimizeBitwidth.cpp.o
OptimizeBitwidth/libLLVMOptimizeBitWidth.so: OptimizeBitwidth/CMakeFiles/LLVMOptimizeBitWidth.dir/info.cpp.o
OptimizeBitwidth/libLLVMOptimizeBitWidth.so: OptimizeBitwidth/CMakeFiles/LLVMOptimizeBitWidth.dir/deps.cpp.o
OptimizeBitwidth/libLLVMOptimizeBitWidth.so: OptimizeBitwidth/CMakeFiles/LLVMOptimizeBitWidth.dir/build.make
OptimizeBitwidth/libLLVMOptimizeBitWidth.so: OptimizeBitwidth/CMakeFiles/LLVMOptimizeBitWidth.dir/link.txt
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --bold --progress-dir=/home/dynamatic/Dynamatic/etc/dynamatic/elastic-circuits/_build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_4) "Linking CXX shared module libLLVMOptimizeBitWidth.so"
	cd /home/dynamatic/Dynamatic/etc/dynamatic/elastic-circuits/_build/OptimizeBitwidth && $(CMAKE_COMMAND) -E cmake_link_script CMakeFiles/LLVMOptimizeBitWidth.dir/link.txt --verbose=$(VERBOSE)

# Rule to build all files generated by this target.
OptimizeBitwidth/CMakeFiles/LLVMOptimizeBitWidth.dir/build: OptimizeBitwidth/libLLVMOptimizeBitWidth.so

.PHONY : OptimizeBitwidth/CMakeFiles/LLVMOptimizeBitWidth.dir/build

OptimizeBitwidth/CMakeFiles/LLVMOptimizeBitWidth.dir/requires: OptimizeBitwidth/CMakeFiles/LLVMOptimizeBitWidth.dir/OptimizeBitwidth.cpp.o.requires
OptimizeBitwidth/CMakeFiles/LLVMOptimizeBitWidth.dir/requires: OptimizeBitwidth/CMakeFiles/LLVMOptimizeBitWidth.dir/info.cpp.o.requires
OptimizeBitwidth/CMakeFiles/LLVMOptimizeBitWidth.dir/requires: OptimizeBitwidth/CMakeFiles/LLVMOptimizeBitWidth.dir/deps.cpp.o.requires

.PHONY : OptimizeBitwidth/CMakeFiles/LLVMOptimizeBitWidth.dir/requires

OptimizeBitwidth/CMakeFiles/LLVMOptimizeBitWidth.dir/clean:
	cd /home/dynamatic/Dynamatic/etc/dynamatic/elastic-circuits/_build/OptimizeBitwidth && $(CMAKE_COMMAND) -P CMakeFiles/LLVMOptimizeBitWidth.dir/cmake_clean.cmake
.PHONY : OptimizeBitwidth/CMakeFiles/LLVMOptimizeBitWidth.dir/clean

OptimizeBitwidth/CMakeFiles/LLVMOptimizeBitWidth.dir/depend:
	cd /home/dynamatic/Dynamatic/etc/dynamatic/elastic-circuits/_build && $(CMAKE_COMMAND) -E cmake_depends "Unix Makefiles" /home/dynamatic/Dynamatic/etc/dynamatic/elastic-circuits /home/dynamatic/Dynamatic/etc/dynamatic/elastic-circuits/OptimizeBitwidth /home/dynamatic/Dynamatic/etc/dynamatic/elastic-circuits/_build /home/dynamatic/Dynamatic/etc/dynamatic/elastic-circuits/_build/OptimizeBitwidth /home/dynamatic/Dynamatic/etc/dynamatic/elastic-circuits/_build/OptimizeBitwidth/CMakeFiles/LLVMOptimizeBitWidth.dir/DependInfo.cmake --color=$(COLOR)
.PHONY : OptimizeBitwidth/CMakeFiles/LLVMOptimizeBitWidth.dir/depend
