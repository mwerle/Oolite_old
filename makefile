# Use this instead of GNUmakefile to create the textured planets exe.
#
# To run this makefile, create a directory for the object files, cd into it, and issue the command "make -f ../Makefile
#
VPATH = ../src/SDL ../src/Core ../src/libnoise ../src/BSDCompat
COMMON_C_FLAGS = -c -DLINUX -DWIN32 -DXP_WIN -DNO_SHADERS -DNEED_STRLCPY -DLIBNOISE_PLANETS `sdl-config --cflags` -DGNUSTEP -g -I../src/SDL -I../src/Core -I../src/BSDCompat -I../src/libnoise

%.o: %.m
	g++ $(COMMON_C_FLAGS) -DGNUSTEP_BASE_LIBRARY=1 -DGNU_RUNTIME=1 -DGNUSTEP_WITH_DLL -DGSWARN -DGSDIAGNOSE -I/c/GNUstep/System/Library/Headers -fconstant-string-class=NSConstantString $<

%.o: %.c
	g++ $(COMMON_C_FLAGS) $<

%.o: %.cpp
	g++ $(COMMON_C_FLAGS) -I/c/GNUstep/Local/include $<

OBJS = legacy_random.o AI.o CollisionRegion.o DustEntity.o Entity.o GameController.o Geometry.o GuiDisplayGen.o HeadUpDisplay.o LoadSave.o MutableDictionaryExtension.o OOBasicSoundReferencePoint.o OOBasicSoundSource.o OOBrain.o OOCharacter.o OOColor.o OOFileManager.o OOInstinct.o OOMusic.o OOSound.o OOTrumble.o OOXMLExtensions.o Octree.o OpenGLSprite.o ParticleEntity.o PlanetEntity.o PlayerEntity.o PlayerEntity_Additions.o PlayerEntity_Controls.o PlayerEntity_Sound.o PlayerEntity_StickMapper.o PlayerEntity_contracts.o ResourceManager.o RingEntity.o ScannerExtension.o ScriptCompiler.o ShipEntity.o ShipEntity_AI.o SkyEntity.o StationEntity.o StringTokeniser.o TextureStore.o Universe.o WormholeEntity.o vector.o Comparison.o JoystickHandler.o main.o MyOpenGLView.o SDLImage.o ptg.o strlcpy.o

oolite.exe: $(OBJS)
	g++ -o ../oolite.app/oolite.exe $(OBJS) -Lc/GNUstep/Library/Libraries -Lc:/GNUstep/System/Library/Libraries `sdl-config --libs` -lglu32 -lopengl32 -lSDL_mixer -lSDL_image -lgnustep-base -lnoise -lobjc -lws2_32 -ladvapi32 -lcomctl32 -luser32 -lcomdlg32 -lmpr -lnetapi32 -lm
