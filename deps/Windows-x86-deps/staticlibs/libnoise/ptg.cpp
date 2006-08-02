#include <stdio.h>
#include <string>
#include <noise/noiseutils.h>
#include "ptg.h"

using namespace noise;

#ifdef TEST_MAIN
int main(int argc, char** argv) {
	return ptg(1,2,3,4,5,6);
}
#endif

unsigned char* convertImageToRGBABuffer(utils::Image& image);

#ifdef __cplusplus
extern "C" {
#endif

/*
 * This program generates a planetary texture for Oolite, given the
 * six components of a solar system's Random_Seed value.
 */
unsigned char* generatePlanet(struct planet_info* info)
{
	int seed;

	seed = 0;
	seed ^= info->seed.a;
	seed ^= info->seed.b;
	seed ^= info->seed.c;
	seed ^= info->seed.d;
	seed ^= info->seed.e;
	seed ^= info->seed.f;

	module::Perlin myModule;

	myModule.SetSeed(seed);
	myModule.SetOctaveCount(8);

	utils::NoiseMap heightMap;
	utils::NoiseMapBuilderSphere heightMapBuilder;
	heightMapBuilder.SetSourceModule(myModule);
	heightMapBuilder.SetDestNoiseMap(heightMap);
	heightMapBuilder.SetDestSize(512, 256);
	heightMapBuilder.SetBounds(-90.0, 90.0, -180.0, 180.0);
	heightMapBuilder.Build();

	utils::RendererImage renderer;
	utils::Image image;
	renderer.SetSourceNoiseMap(heightMap);
	renderer.SetDestImage(image);
	//renderer.BuildTerrainGradient();

	renderer.ClearGradient ();

	int r = (int)(info->sea_colour[0] * 255.0);
	int g = (int)(info->sea_colour[1] * 255.0);
	int b = (int)(info->sea_colour[2] * 255.0);

	fprintf(stderr, "sea colour (2) r: %f, g: %f, b: %f\r\n", info->sea_colour[0], info->sea_colour[1], info->sea_colour[2]);
	fprintf(stderr, "sea colour (2) r: %d, g: %d, b: %d\r\n", r, g, b);

	renderer.AddGradientPoint (-1.00, utils::Color (r, g, b, 255));
	//renderer.AddGradientPoint (-0.90, utils::Color (r, g, b, 255));

	r = (int)(info->land_colour[0] * 255.0);
	g = (int)(info->land_colour[1] * 255.0);
	b = (int)(info->land_colour[2] * 255.0);

	fprintf(stderr, "land colour (2) r: %f, g: %f, b: %f\r\n", info->land_colour[0], info->land_colour[1], info->land_colour[2]);
	fprintf(stderr, "land colour (2) r: %d, g: %d, b: %d\r\n", r, g, b);

	//renderer.AddGradientPoint ( 0.00, utils::Color (r, g, b, 255));
	renderer.AddGradientPoint ( 1.00, utils::Color (r, g, b, 255));

	renderer.EnableLight();
	renderer.SetLightContrast(3.0);
	renderer.SetLightBrightness(2.0);
	renderer.Render();

	unsigned char* buffer = convertImageToRGBABuffer(image);
	return buffer;
}

/*
 * This program generates a planetary texture for Oolite, given the
 * six components of a solar system's Random_Seed value.
 */
unsigned char* generateClouds(struct planet_info* info)
{
	int seed;

	seed ^= info->seed.a;
	seed ^= info->seed.b;
	seed ^= info->seed.c;
	seed ^= info->seed.d;
	seed ^= info->seed.e;
	seed ^= info->seed.f;

/*
	// Base of the cloud texture.  The billowy noise produces the basic shape
	// of soft, fluffy clouds.
	module::Billow cloudBase;
	cloudBase.SetSeed (seed);
	cloudBase.SetFrequency (2.0);
	cloudBase.SetPersistence (0.375);
	cloudBase.SetLacunarity (2.12109375);
	cloudBase.SetOctaveCount (4);
	//cloudBase.SetNoiseQuality (QUALITY_BEST);

	// Perturb the cloud texture for more realism.
	module::Turbulence finalClouds;
	finalClouds.SetSourceModule (0, cloudBase);
	finalClouds.SetSeed (seed);
	finalClouds.SetFrequency (16.0);
	finalClouds.SetPower (1.0 / 64.0);
	finalClouds.SetRoughness (2);

	utils::NoiseMapBuilderSphere sphere;
	utils::NoiseMap upperNoiseMap;
	sphere.SetBounds (-90.0, 90.0, -180.0, 180.0); // degrees
	sphere.SetDestSize (512, 256);

	// Generate the upper noise map.
	sphere.SetSourceModule (finalClouds);
	sphere.SetDestNoiseMap (upperNoiseMap);
	sphere.Build ();

	utils::RendererImage renderer;
	utils::Image image;

	renderer.ClearGradient ();
	renderer.AddGradientPoint (-1.00, utils::Color (255, 255, 255,   0));
	renderer.AddGradientPoint (-0.50, utils::Color (255, 255, 255,   0));
	//renderer.AddGradientPoint ( 0.75, utils::Color (255, 255, 255, 128));
	renderer.AddGradientPoint ( 1.00, utils::Color (255, 255, 255, 255));
	renderer.SetSourceNoiseMap (upperNoiseMap);
	renderer.SetDestImage (image);
	renderer.EnableLight (false);
	renderer.Render ();

	unsigned char* buffer = convertImageToRGBABuffer(image);
	return buffer;
*/
  module::Billow myModule;

  myModule.SetSeed(seed);
  myModule.SetOctaveCount (8);

  utils::NoiseMap heightMap;
  utils::NoiseMapBuilderSphere heightMapBuilder;
  heightMapBuilder.SetSourceModule (myModule);
  heightMapBuilder.SetDestNoiseMap (heightMap);
  heightMapBuilder.SetDestSize (512, 256);
  heightMapBuilder.SetBounds (-90.0, 90.0, -180.0, 180.0);
  heightMapBuilder.Build ();

  utils::RendererImage renderer;
  utils::Image image;

  // It is vital to set a background image to get transparent colours in
  // the output image. For this to happen the background image must have
  // all pixels set to fully transparent.
  utils::Image background;
  background.SetSize(512, 256);
  background.Clear(utils::Color(0, 0, 0, 0));

  renderer.SetSourceNoiseMap (heightMap);
  renderer.SetBackgroundImage(background);
  renderer.SetDestImage (image);

	renderer.ClearGradient ();
/*
	renderer.AddGradientPoint (-1.00, utils::Color (255, 255, 255,   0));
	renderer.AddGradientPoint (-0.50, utils::Color (255, 255, 255,   0));
	renderer.AddGradientPoint ( 1.00, utils::Color (255, 255, 255, 255));
*/
	int r = (int)(info->sea_colour[0] * 255.0);
	int g = (int)(info->sea_colour[1] * 255.0);
	int b = (int)(info->sea_colour[2] * 255.0);

	renderer.AddGradientPoint (-1.00, utils::Color (r, g, b, 0));

	r = (int)(info->land_colour[0] * 255.0);
	g = (int)(info->land_colour[1] * 255.0);
	b = (int)(info->land_colour[2] * 255.0);

	renderer.AddGradientPoint ( 0.75, utils::Color (r, g, b, 255));

  renderer.EnableLight ();
  renderer.SetLightContrast (3.0);
  renderer.SetLightBrightness (2.0);
  renderer.Render ();

  unsigned char* buffer = convertImageToRGBABuffer(image);
  return buffer;

}


#ifdef __cplusplus
}
#endif

unsigned char* convertImageToRGBABuffer(utils::Image& image)
{
  unsigned char* buffer;
  int width = image.GetWidth();
  int height = image.GetHeight();
  int offset = 0;
  int bufferSize = width * 4 * height;
  buffer = (unsigned char*)malloc(bufferSize); // must be freed by the caller
  if (buffer == 0)
    return 0; // return a null pointer for failure

  utils::Color* pSource;
  for (int y = 0; y < height; y++) {
    pSource = image.GetSlabPtr (y);
    for (int x = 0; x < width; x++) {
      buffer[offset++] = (unsigned char)pSource->red;
      buffer[offset++] = (unsigned char)pSource->green;
      buffer[offset++] = (unsigned char)pSource->blue;
      buffer[offset++] = (unsigned char)pSource->alpha;
//      fprintf(stdout, "alpha = %d ", (unsigned char)pSource->alpha);
      ++pSource;
    }
  }

  FILE * pFile;
  pFile = fopen("texture.raw", "wb");
  fwrite(buffer, 1, bufferSize, pFile);
  fflush(pFile);
  fclose(pFile);

  return buffer;
}
