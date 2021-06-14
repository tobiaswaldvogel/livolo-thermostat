#
# Generated Makefile - do not edit!
#
# Edit the Makefile in the project folder instead (../Makefile). Each target
# has a -pre and a -post target defined where you can add customized code.
#
# This makefile implements configuration specific macros and targets.


# Include project Makefile
ifeq "${IGNORE_LOCAL}" "TRUE"
# do not include local makefile. User is passing all local related variables already
else
include Makefile
# Include makefile containing local settings
ifeq "$(wildcard nbproject/Makefile-local-default.mk)" "nbproject/Makefile-local-default.mk"
include nbproject/Makefile-local-default.mk
endif
endif

# Environment
MKDIR=gnumkdir -p
RM=rm -f 
MV=mv 
CP=cp 

# Macros
CND_CONF=default
ifeq ($(TYPE_IMAGE), DEBUG_RUN)
IMAGE_TYPE=debug
OUTPUT_SUFFIX=hex
DEBUGGABLE_SUFFIX=elf
FINAL_IMAGE=dist/${CND_CONF}/${IMAGE_TYPE}/PIC.${IMAGE_TYPE}.${OUTPUT_SUFFIX}
else
IMAGE_TYPE=production
OUTPUT_SUFFIX=hex
DEBUGGABLE_SUFFIX=elf
FINAL_IMAGE=dist/${CND_CONF}/${IMAGE_TYPE}/PIC.${IMAGE_TYPE}.${OUTPUT_SUFFIX}
endif

ifeq ($(COMPARE_BUILD), true)
COMPARISON_BUILD=
else
COMPARISON_BUILD=
endif

ifdef SUB_IMAGE_ADDRESS

else
SUB_IMAGE_ADDRESS_COMMAND=
endif

# Object Directory
OBJECTDIR=build/${CND_CONF}/${IMAGE_TYPE}

# Distribution Directory
DISTDIR=dist/${CND_CONF}/${IMAGE_TYPE}

# Source Files Quoted if spaced
SOURCEFILES_QUOTED_IF_SPACED=Livolo_thermostat/init.asm Livolo_thermostat/isr.asm Livolo_thermostat/main.asm Livolo_thermostat/one_wire.asm Livolo_thermostat/util.asm Livolo_thermostat/global_vars.asm Livolo_thermostat/touch_events.asm Livolo_thermostat/setup.asm Livolo_thermostat/timer_events.asm Livolo_thermostat/display.asm

# Object Files Quoted if spaced
OBJECTFILES_QUOTED_IF_SPACED=${OBJECTDIR}/Livolo_thermostat/init.o ${OBJECTDIR}/Livolo_thermostat/isr.o ${OBJECTDIR}/Livolo_thermostat/main.o ${OBJECTDIR}/Livolo_thermostat/one_wire.o ${OBJECTDIR}/Livolo_thermostat/util.o ${OBJECTDIR}/Livolo_thermostat/global_vars.o ${OBJECTDIR}/Livolo_thermostat/touch_events.o ${OBJECTDIR}/Livolo_thermostat/setup.o ${OBJECTDIR}/Livolo_thermostat/timer_events.o ${OBJECTDIR}/Livolo_thermostat/display.o
POSSIBLE_DEPFILES=${OBJECTDIR}/Livolo_thermostat/init.o.d ${OBJECTDIR}/Livolo_thermostat/isr.o.d ${OBJECTDIR}/Livolo_thermostat/main.o.d ${OBJECTDIR}/Livolo_thermostat/one_wire.o.d ${OBJECTDIR}/Livolo_thermostat/util.o.d ${OBJECTDIR}/Livolo_thermostat/global_vars.o.d ${OBJECTDIR}/Livolo_thermostat/touch_events.o.d ${OBJECTDIR}/Livolo_thermostat/setup.o.d ${OBJECTDIR}/Livolo_thermostat/timer_events.o.d ${OBJECTDIR}/Livolo_thermostat/display.o.d

# Object Files
OBJECTFILES=${OBJECTDIR}/Livolo_thermostat/init.o ${OBJECTDIR}/Livolo_thermostat/isr.o ${OBJECTDIR}/Livolo_thermostat/main.o ${OBJECTDIR}/Livolo_thermostat/one_wire.o ${OBJECTDIR}/Livolo_thermostat/util.o ${OBJECTDIR}/Livolo_thermostat/global_vars.o ${OBJECTDIR}/Livolo_thermostat/touch_events.o ${OBJECTDIR}/Livolo_thermostat/setup.o ${OBJECTDIR}/Livolo_thermostat/timer_events.o ${OBJECTDIR}/Livolo_thermostat/display.o

# Source Files
SOURCEFILES=Livolo_thermostat/init.asm Livolo_thermostat/isr.asm Livolo_thermostat/main.asm Livolo_thermostat/one_wire.asm Livolo_thermostat/util.asm Livolo_thermostat/global_vars.asm Livolo_thermostat/touch_events.asm Livolo_thermostat/setup.asm Livolo_thermostat/timer_events.asm Livolo_thermostat/display.asm



CFLAGS=
ASFLAGS=
LDLIBSOPTIONS=

############# Tool locations ##########################################
# If you copy a project from one host to another, the path where the  #
# compiler is installed may be different.                             #
# If you open this project with MPLAB X in the new host, this         #
# makefile will be regenerated and the paths will be corrected.       #
#######################################################################
# fixDeps replaces a bunch of sed/cat/printf statements that slow down the build
FIXDEPS=fixDeps

# The following macros may be used in the pre and post step lines
_/_=\\
ShExtension=.bat
Device=PIC16F690
ProjectDir="C:\Users\waldvogt\Documents\PIC"
ProjectName=Livolo_thermostat
ConfName=default
ImagePath="dist\default\${IMAGE_TYPE}\PIC.${IMAGE_TYPE}.${OUTPUT_SUFFIX}"
ImageDir="dist\default\${IMAGE_TYPE}"
ImageName="PIC.${IMAGE_TYPE}.${OUTPUT_SUFFIX}"
ifeq ($(TYPE_IMAGE), DEBUG_RUN)
IsDebug="true"
else
IsDebug="false"
endif

.build-conf:  ${BUILD_SUBPROJECTS}
ifneq ($(INFORMATION_MESSAGE), )
	@echo $(INFORMATION_MESSAGE)
endif
	${MAKE}  -f nbproject/Makefile-default.mk dist/${CND_CONF}/${IMAGE_TYPE}/PIC.${IMAGE_TYPE}.${OUTPUT_SUFFIX}
	@echo "--------------------------------------"
	@echo "User defined post-build step: [copy ${ImagePath} ${ProjectDir}${_/_}Livolo_thermostat.hex]"
	@copy ${ImagePath} ${ProjectDir}${_/_}Livolo_thermostat.hex
	@echo "--------------------------------------"

MP_PROCESSOR_OPTION=PIC16F690
# ------------------------------------------------------------------------------------
# Rules for buildStep: pic-as-assembler
ifeq ($(TYPE_IMAGE), DEBUG_RUN)
${OBJECTDIR}/Livolo_thermostat/init.o: Livolo_thermostat/init.asm  nbproject/Makefile-${CND_CONF}.mk 
	@${MKDIR} "${OBJECTDIR}/Livolo_thermostat" 
	@${RM} ${OBJECTDIR}/Livolo_thermostat/init.o 
	${MP_AS} -mcpu=PIC16F690 -c \
	-o ${OBJECTDIR}/Livolo_thermostat/init.o \
	Livolo_thermostat/init.asm \
	 -msummary=+mem,-psect,-class,-hex,-file,-sha1,-sha256,-xml,-xmlfull -fmax-errors=20 -mwarn=0 -xassembler-with-cpp
	
${OBJECTDIR}/Livolo_thermostat/isr.o: Livolo_thermostat/isr.asm  nbproject/Makefile-${CND_CONF}.mk 
	@${MKDIR} "${OBJECTDIR}/Livolo_thermostat" 
	@${RM} ${OBJECTDIR}/Livolo_thermostat/isr.o 
	${MP_AS} -mcpu=PIC16F690 -c \
	-o ${OBJECTDIR}/Livolo_thermostat/isr.o \
	Livolo_thermostat/isr.asm \
	 -msummary=+mem,-psect,-class,-hex,-file,-sha1,-sha256,-xml,-xmlfull -fmax-errors=20 -mwarn=0 -xassembler-with-cpp
	
${OBJECTDIR}/Livolo_thermostat/main.o: Livolo_thermostat/main.asm  nbproject/Makefile-${CND_CONF}.mk 
	@${MKDIR} "${OBJECTDIR}/Livolo_thermostat" 
	@${RM} ${OBJECTDIR}/Livolo_thermostat/main.o 
	${MP_AS} -mcpu=PIC16F690 -c \
	-o ${OBJECTDIR}/Livolo_thermostat/main.o \
	Livolo_thermostat/main.asm \
	 -msummary=+mem,-psect,-class,-hex,-file,-sha1,-sha256,-xml,-xmlfull -fmax-errors=20 -mwarn=0 -xassembler-with-cpp
	
${OBJECTDIR}/Livolo_thermostat/one_wire.o: Livolo_thermostat/one_wire.asm  nbproject/Makefile-${CND_CONF}.mk 
	@${MKDIR} "${OBJECTDIR}/Livolo_thermostat" 
	@${RM} ${OBJECTDIR}/Livolo_thermostat/one_wire.o 
	${MP_AS} -mcpu=PIC16F690 -c \
	-o ${OBJECTDIR}/Livolo_thermostat/one_wire.o \
	Livolo_thermostat/one_wire.asm \
	 -msummary=+mem,-psect,-class,-hex,-file,-sha1,-sha256,-xml,-xmlfull -fmax-errors=20 -mwarn=0 -xassembler-with-cpp
	
${OBJECTDIR}/Livolo_thermostat/util.o: Livolo_thermostat/util.asm  nbproject/Makefile-${CND_CONF}.mk 
	@${MKDIR} "${OBJECTDIR}/Livolo_thermostat" 
	@${RM} ${OBJECTDIR}/Livolo_thermostat/util.o 
	${MP_AS} -mcpu=PIC16F690 -c \
	-o ${OBJECTDIR}/Livolo_thermostat/util.o \
	Livolo_thermostat/util.asm \
	 -msummary=+mem,-psect,-class,-hex,-file,-sha1,-sha256,-xml,-xmlfull -fmax-errors=20 -mwarn=0 -xassembler-with-cpp
	
${OBJECTDIR}/Livolo_thermostat/global_vars.o: Livolo_thermostat/global_vars.asm  nbproject/Makefile-${CND_CONF}.mk 
	@${MKDIR} "${OBJECTDIR}/Livolo_thermostat" 
	@${RM} ${OBJECTDIR}/Livolo_thermostat/global_vars.o 
	${MP_AS} -mcpu=PIC16F690 -c \
	-o ${OBJECTDIR}/Livolo_thermostat/global_vars.o \
	Livolo_thermostat/global_vars.asm \
	 -msummary=+mem,-psect,-class,-hex,-file,-sha1,-sha256,-xml,-xmlfull -fmax-errors=20 -mwarn=0 -xassembler-with-cpp
	
${OBJECTDIR}/Livolo_thermostat/touch_events.o: Livolo_thermostat/touch_events.asm  nbproject/Makefile-${CND_CONF}.mk 
	@${MKDIR} "${OBJECTDIR}/Livolo_thermostat" 
	@${RM} ${OBJECTDIR}/Livolo_thermostat/touch_events.o 
	${MP_AS} -mcpu=PIC16F690 -c \
	-o ${OBJECTDIR}/Livolo_thermostat/touch_events.o \
	Livolo_thermostat/touch_events.asm \
	 -msummary=+mem,-psect,-class,-hex,-file,-sha1,-sha256,-xml,-xmlfull -fmax-errors=20 -mwarn=0 -xassembler-with-cpp
	
${OBJECTDIR}/Livolo_thermostat/setup.o: Livolo_thermostat/setup.asm  nbproject/Makefile-${CND_CONF}.mk 
	@${MKDIR} "${OBJECTDIR}/Livolo_thermostat" 
	@${RM} ${OBJECTDIR}/Livolo_thermostat/setup.o 
	${MP_AS} -mcpu=PIC16F690 -c \
	-o ${OBJECTDIR}/Livolo_thermostat/setup.o \
	Livolo_thermostat/setup.asm \
	 -msummary=+mem,-psect,-class,-hex,-file,-sha1,-sha256,-xml,-xmlfull -fmax-errors=20 -mwarn=0 -xassembler-with-cpp
	
${OBJECTDIR}/Livolo_thermostat/timer_events.o: Livolo_thermostat/timer_events.asm  nbproject/Makefile-${CND_CONF}.mk 
	@${MKDIR} "${OBJECTDIR}/Livolo_thermostat" 
	@${RM} ${OBJECTDIR}/Livolo_thermostat/timer_events.o 
	${MP_AS} -mcpu=PIC16F690 -c \
	-o ${OBJECTDIR}/Livolo_thermostat/timer_events.o \
	Livolo_thermostat/timer_events.asm \
	 -msummary=+mem,-psect,-class,-hex,-file,-sha1,-sha256,-xml,-xmlfull -fmax-errors=20 -mwarn=0 -xassembler-with-cpp
	
${OBJECTDIR}/Livolo_thermostat/display.o: Livolo_thermostat/display.asm  nbproject/Makefile-${CND_CONF}.mk 
	@${MKDIR} "${OBJECTDIR}/Livolo_thermostat" 
	@${RM} ${OBJECTDIR}/Livolo_thermostat/display.o 
	${MP_AS} -mcpu=PIC16F690 -c \
	-o ${OBJECTDIR}/Livolo_thermostat/display.o \
	Livolo_thermostat/display.asm \
	 -msummary=+mem,-psect,-class,-hex,-file,-sha1,-sha256,-xml,-xmlfull -fmax-errors=20 -mwarn=0 -xassembler-with-cpp
	
else
${OBJECTDIR}/Livolo_thermostat/init.o: Livolo_thermostat/init.asm  nbproject/Makefile-${CND_CONF}.mk 
	@${MKDIR} "${OBJECTDIR}/Livolo_thermostat" 
	@${RM} ${OBJECTDIR}/Livolo_thermostat/init.o 
	${MP_AS} -mcpu=PIC16F690 -c \
	-o ${OBJECTDIR}/Livolo_thermostat/init.o \
	Livolo_thermostat/init.asm \
	 -msummary=+mem,-psect,-class,-hex,-file,-sha1,-sha256,-xml,-xmlfull -fmax-errors=20 -mwarn=0 -xassembler-with-cpp
	
${OBJECTDIR}/Livolo_thermostat/isr.o: Livolo_thermostat/isr.asm  nbproject/Makefile-${CND_CONF}.mk 
	@${MKDIR} "${OBJECTDIR}/Livolo_thermostat" 
	@${RM} ${OBJECTDIR}/Livolo_thermostat/isr.o 
	${MP_AS} -mcpu=PIC16F690 -c \
	-o ${OBJECTDIR}/Livolo_thermostat/isr.o \
	Livolo_thermostat/isr.asm \
	 -msummary=+mem,-psect,-class,-hex,-file,-sha1,-sha256,-xml,-xmlfull -fmax-errors=20 -mwarn=0 -xassembler-with-cpp
	
${OBJECTDIR}/Livolo_thermostat/main.o: Livolo_thermostat/main.asm  nbproject/Makefile-${CND_CONF}.mk 
	@${MKDIR} "${OBJECTDIR}/Livolo_thermostat" 
	@${RM} ${OBJECTDIR}/Livolo_thermostat/main.o 
	${MP_AS} -mcpu=PIC16F690 -c \
	-o ${OBJECTDIR}/Livolo_thermostat/main.o \
	Livolo_thermostat/main.asm \
	 -msummary=+mem,-psect,-class,-hex,-file,-sha1,-sha256,-xml,-xmlfull -fmax-errors=20 -mwarn=0 -xassembler-with-cpp
	
${OBJECTDIR}/Livolo_thermostat/one_wire.o: Livolo_thermostat/one_wire.asm  nbproject/Makefile-${CND_CONF}.mk 
	@${MKDIR} "${OBJECTDIR}/Livolo_thermostat" 
	@${RM} ${OBJECTDIR}/Livolo_thermostat/one_wire.o 
	${MP_AS} -mcpu=PIC16F690 -c \
	-o ${OBJECTDIR}/Livolo_thermostat/one_wire.o \
	Livolo_thermostat/one_wire.asm \
	 -msummary=+mem,-psect,-class,-hex,-file,-sha1,-sha256,-xml,-xmlfull -fmax-errors=20 -mwarn=0 -xassembler-with-cpp
	
${OBJECTDIR}/Livolo_thermostat/util.o: Livolo_thermostat/util.asm  nbproject/Makefile-${CND_CONF}.mk 
	@${MKDIR} "${OBJECTDIR}/Livolo_thermostat" 
	@${RM} ${OBJECTDIR}/Livolo_thermostat/util.o 
	${MP_AS} -mcpu=PIC16F690 -c \
	-o ${OBJECTDIR}/Livolo_thermostat/util.o \
	Livolo_thermostat/util.asm \
	 -msummary=+mem,-psect,-class,-hex,-file,-sha1,-sha256,-xml,-xmlfull -fmax-errors=20 -mwarn=0 -xassembler-with-cpp
	
${OBJECTDIR}/Livolo_thermostat/global_vars.o: Livolo_thermostat/global_vars.asm  nbproject/Makefile-${CND_CONF}.mk 
	@${MKDIR} "${OBJECTDIR}/Livolo_thermostat" 
	@${RM} ${OBJECTDIR}/Livolo_thermostat/global_vars.o 
	${MP_AS} -mcpu=PIC16F690 -c \
	-o ${OBJECTDIR}/Livolo_thermostat/global_vars.o \
	Livolo_thermostat/global_vars.asm \
	 -msummary=+mem,-psect,-class,-hex,-file,-sha1,-sha256,-xml,-xmlfull -fmax-errors=20 -mwarn=0 -xassembler-with-cpp
	
${OBJECTDIR}/Livolo_thermostat/touch_events.o: Livolo_thermostat/touch_events.asm  nbproject/Makefile-${CND_CONF}.mk 
	@${MKDIR} "${OBJECTDIR}/Livolo_thermostat" 
	@${RM} ${OBJECTDIR}/Livolo_thermostat/touch_events.o 
	${MP_AS} -mcpu=PIC16F690 -c \
	-o ${OBJECTDIR}/Livolo_thermostat/touch_events.o \
	Livolo_thermostat/touch_events.asm \
	 -msummary=+mem,-psect,-class,-hex,-file,-sha1,-sha256,-xml,-xmlfull -fmax-errors=20 -mwarn=0 -xassembler-with-cpp
	
${OBJECTDIR}/Livolo_thermostat/setup.o: Livolo_thermostat/setup.asm  nbproject/Makefile-${CND_CONF}.mk 
	@${MKDIR} "${OBJECTDIR}/Livolo_thermostat" 
	@${RM} ${OBJECTDIR}/Livolo_thermostat/setup.o 
	${MP_AS} -mcpu=PIC16F690 -c \
	-o ${OBJECTDIR}/Livolo_thermostat/setup.o \
	Livolo_thermostat/setup.asm \
	 -msummary=+mem,-psect,-class,-hex,-file,-sha1,-sha256,-xml,-xmlfull -fmax-errors=20 -mwarn=0 -xassembler-with-cpp
	
${OBJECTDIR}/Livolo_thermostat/timer_events.o: Livolo_thermostat/timer_events.asm  nbproject/Makefile-${CND_CONF}.mk 
	@${MKDIR} "${OBJECTDIR}/Livolo_thermostat" 
	@${RM} ${OBJECTDIR}/Livolo_thermostat/timer_events.o 
	${MP_AS} -mcpu=PIC16F690 -c \
	-o ${OBJECTDIR}/Livolo_thermostat/timer_events.o \
	Livolo_thermostat/timer_events.asm \
	 -msummary=+mem,-psect,-class,-hex,-file,-sha1,-sha256,-xml,-xmlfull -fmax-errors=20 -mwarn=0 -xassembler-with-cpp
	
${OBJECTDIR}/Livolo_thermostat/display.o: Livolo_thermostat/display.asm  nbproject/Makefile-${CND_CONF}.mk 
	@${MKDIR} "${OBJECTDIR}/Livolo_thermostat" 
	@${RM} ${OBJECTDIR}/Livolo_thermostat/display.o 
	${MP_AS} -mcpu=PIC16F690 -c \
	-o ${OBJECTDIR}/Livolo_thermostat/display.o \
	Livolo_thermostat/display.asm \
	 -msummary=+mem,-psect,-class,-hex,-file,-sha1,-sha256,-xml,-xmlfull -fmax-errors=20 -mwarn=0 -xassembler-with-cpp
	
endif

# ------------------------------------------------------------------------------------
# Rules for buildStep: pic-as-linker
ifeq ($(TYPE_IMAGE), DEBUG_RUN)
dist/${CND_CONF}/${IMAGE_TYPE}/PIC.${IMAGE_TYPE}.${OUTPUT_SUFFIX}: ${OBJECTFILES}  nbproject/Makefile-${CND_CONF}.mk    
	@${MKDIR} dist/${CND_CONF}/${IMAGE_TYPE} 
	${MP_LD} -mcpu=PIC16F690 ${OBJECTFILES_QUOTED_IF_SPACED} \
	-o dist/${CND_CONF}/${IMAGE_TYPE}/PIC.${IMAGE_TYPE}.${OUTPUT_SUFFIX} \
	 -msummary=+mem,-psect,-class,-hex,-file,-sha1,-sha256,-xml,-xmlfull -mcallgraph=std -mno-download-hex
else
dist/${CND_CONF}/${IMAGE_TYPE}/PIC.${IMAGE_TYPE}.${OUTPUT_SUFFIX}: ${OBJECTFILES}  nbproject/Makefile-${CND_CONF}.mk   
	@${MKDIR} dist/${CND_CONF}/${IMAGE_TYPE} 
	${MP_LD} -mcpu=PIC16F690 ${OBJECTFILES_QUOTED_IF_SPACED} \
	-o dist/${CND_CONF}/${IMAGE_TYPE}/PIC.${IMAGE_TYPE}.${OUTPUT_SUFFIX} \
	 -msummary=+mem,-psect,-class,-hex,-file,-sha1,-sha256,-xml,-xmlfull -mcallgraph=std -mno-download-hex
endif


# Subprojects
.build-subprojects:


# Subprojects
.clean-subprojects:

# Clean Targets
.clean-conf: ${CLEAN_SUBPROJECTS}
	${RM} -r build/default
	${RM} -r dist/default

# Enable dependency checking
.dep.inc: .depcheck-impl

DEPFILES=$(shell mplabwildcard ${POSSIBLE_DEPFILES})
ifneq (${DEPFILES},)
include ${DEPFILES}
endif
