#include <stdio.h>
#include <string>
#include "noise/noiseutils.h"
#include "ptg.h"

using namespace noise;

unsigned char* convertImageToRGBABuffer(utils::Image& image);

#ifdef __cplusplus
extern "C" {
#endif

#define IMG_WIDTH 1024
#define IMG_HEIGHT 512

utils::Image* planetBackground;

unsigned char* generateEarthLikePlanet(struct planet_info* info);
unsigned char* generateMarsLikePlanet(struct planet_info* info);

/*
 * This program generates a planetary texture for Oolite, given the
 * six components of a solar system's Random_Seed value.
 */
unsigned char* generatePlanet(struct planet_info* info) {
	fprintf(stderr, "generatePlanet: seed = %03d, size = %d x %d\r\n", info->seed, info->texture_width, info->texture_height);
	if ((info->seed % 2) == 1)
		return generateMarsLikePlanet(info);

	return generateEarthLikePlanet(info);
}


/*
 * This program generates a planetary texture for Oolite, given the
 * six components of a solar system's Random_Seed value.
 */
unsigned char* generateEarthLikePlanet(struct planet_info* info) {
/*
	if (planetBackground == 0) {
		utils::Color white(255, 255, 255, 255);
		planetBackground = new utils::Image(IMG_WIDTH, IMG_HEIGHT);
		planetBackground->Clear(utils::Color(255, 0, 0, 255));

		for (y = 0; y < 25; y++) {
			for (x = 0; x < 512; x++) {
				planetBackground->SetValue(x, y, white);
				planetBackground->SetValue(x, 255-y, white);
			}
		}

		for (y = 25; y < 50; y++) {
			white.red -= 4; white.green -= 4; white.blue -= 4;
			for (x = 0; x < 512; x++) {
				planetBackground->SetValue(x, y, white);
				planetBackground->SetValue(x, 255-y, white);
			}
		}

	}
*/
	module::Perlin myModule;

	myModule.SetSeed(info->seed);
	myModule.SetOctaveCount(14);

	utils::NoiseMap heightMap;
	utils::NoiseMapBuilderSphere heightMapBuilder;
	heightMapBuilder.SetSourceModule(myModule);
	heightMapBuilder.SetDestNoiseMap(heightMap);
	heightMapBuilder.SetDestSize(info->texture_width, info->texture_height);
	heightMapBuilder.SetBounds(-90.0, 90.0, -180.0, 180.0);
	heightMapBuilder.Build();

	utils::RendererImage renderer;
	utils::Image image;
	renderer.SetSourceNoiseMap(heightMap);
	//renderer.SetBackgroundImage(*planetBackground);
	renderer.SetDestImage(image);

	renderer.ClearGradient ();
	if (info->use_oolite_colours == 0) {
		renderer.AddGradientPoint (-1.00, utils::Color (  0,   0, 128, 255));
		renderer.AddGradientPoint (-0.20, utils::Color ( 32,  64, 128, 255));
		renderer.AddGradientPoint (-0.04, utils::Color ( 64,  96, 192, 255));
		renderer.AddGradientPoint (-0.02, utils::Color (192, 192, 128, 255));
		renderer.AddGradientPoint ( 0.00, utils::Color (  0, 192,   0, 255));
		renderer.AddGradientPoint ( 0.25, utils::Color (192, 192,   0, 255));
		renderer.AddGradientPoint ( 0.75, utils::Color (160,  96,  64, 255));
		renderer.AddGradientPoint ( 0.90, utils::Color (128, 255, 255, 255));
		renderer.AddGradientPoint ( 1.00, utils::Color (255, 255, 255, 255));
	} else {
		int r = (int)(info->sea_colour[0] * 255.0);
		int g = (int)(info->sea_colour[1] * 255.0);
		int b = (int)(info->sea_colour[2] * 255.0);

		//fprintf(stderr, "sea colour (2) r: %f, g: %f, b: %f\r\n", info->sea_colour[0], info->sea_colour[1], info->sea_colour[2]);
		//fprintf(stderr, "sea colour (2) r: %d, g: %d, b: %d\r\n", r, g, b);

		renderer.AddGradientPoint (-1.00, utils::Color (r, g, b, 255));
		//renderer.AddGradientPoint (-0.90, utils::Color (r, g, b, 255));

		r = (int)(info->land_colour[0] * 255.0);
		g = (int)(info->land_colour[1] * 255.0);
		b = (int)(info->land_colour[2] * 255.0);

		//fprintf(stderr, "land colour (2) r: %f, g: %f, b: %f\r\n", info->land_colour[0], info->land_colour[1], info->land_colour[2]);
		//fprintf(stderr, "land colour (2) r: %d, g: %d, b: %d\r\n", r, g, b);

		//renderer.AddGradientPoint ( 0.00, utils::Color (r, g, b, 255));
		renderer.AddGradientPoint ( 1.00, utils::Color (r, g, b, 255));
	}

	renderer.EnableLight();
	renderer.SetLightContrast(2.0);
	renderer.SetLightBrightness(1.5);
	renderer.Render();

	unsigned char* buffer = convertImageToRGBABuffer(image);
	return buffer;
}

unsigned char* generateMarsLikePlanet(struct planet_info* info) {

	module::RidgedMulti myModule;

	myModule.SetSeed(info->seed);
	myModule.SetOctaveCount(8);
	myModule.SetFrequency(0.6);

	module::Terrace terrace;
	terrace.SetSourceModule(0, myModule);
	terrace.MakeControlPoints(7);

	utils::NoiseMap heightMap;
	utils::NoiseMapBuilderSphere heightMapBuilder;
	heightMapBuilder.SetSourceModule(terrace);
	heightMapBuilder.SetDestNoiseMap(heightMap);
	heightMapBuilder.SetDestSize(info->texture_width, info->texture_height);
	heightMapBuilder.SetBounds(-90.0, 90.0, -180.0, 180.0);
	heightMapBuilder.Build ();

	utils::RendererImage renderer;
	utils::Image image;
	renderer.SetSourceNoiseMap(heightMap);
	renderer.SetDestImage(image);

	// The trick with this one will be to use HSL values, keeping the SL constant
	// and just changing the hue to get different planets.
	renderer.ClearGradient ();
	renderer.AddGradientPoint(-1.00, utils::Color (160, 109, 40, 255));
	renderer.AddGradientPoint( 1.00, utils::Color (190, 152, 63, 255));

	renderer.EnableLight();
	renderer.SetLightContrast(1.5);
	renderer.SetLightBrightness(1.5);
	renderer.Render ();

	unsigned char* buffer = convertImageToRGBABuffer(image);
	return buffer;
}

/*
 * This program generates a planetary texture for Oolite, given the
 * six components of a solar system's Random_Seed value.
 */
unsigned char* generateClouds(struct planet_info* info) {
	fprintf(stderr, "generateClouds: seed = %03d, size = %d x %d\r\n", info->seed, info->texture_width, info->texture_height);

	module::Billow myModule;
	myModule.SetSeed(info->seed);
	myModule.SetOctaveCount(8);

	utils::NoiseMap heightMap;
	utils::NoiseMapBuilderSphere heightMapBuilder;
	heightMapBuilder.SetSourceModule(myModule);
	heightMapBuilder.SetDestNoiseMap(heightMap);
	heightMapBuilder.SetDestSize(info->texture_width, info->texture_height);
	heightMapBuilder.SetBounds(-90.0, 90.0, -180.0, 180.0);
	heightMapBuilder.Build();

	utils::RendererImage renderer;
	utils::Image image;

	// It is vital to set a background image to get transparent colours in
	// the output image. For this to happen the background image must have
	// all pixels set to fully transparent.
	//if (cloudBackground == 0) {
		utils::Image cloudBackground = utils::Image(info->texture_width, info->texture_height);
		cloudBackground.Clear(utils::Color(0, 0, 0, 0));
	//}

	renderer.SetSourceNoiseMap(heightMap);
	renderer.SetBackgroundImage(cloudBackground);
	renderer.SetDestImage(image);

	renderer.ClearGradient();

	if (info->use_oolite_colours == 0) {
		renderer.AddGradientPoint (-1.00, utils::Color (255, 255, 255,   0));
		renderer.AddGradientPoint (-0.50, utils::Color (255, 255, 255,   0));
		renderer.AddGradientPoint ( 1.00, utils::Color (255, 255, 255, 255));
	} else {
		int r = (int)(info->sea_colour[0] * 255.0);
		int g = (int)(info->sea_colour[1] * 255.0);
		int b = (int)(info->sea_colour[2] * 255.0);

		renderer.AddGradientPoint (-1.00, utils::Color (r, g, b, 0));

		r = (int)(info->land_colour[0] * 255.0);
		g = (int)(info->land_colour[1] * 255.0);
		b = (int)(info->land_colour[2] * 255.0);

		renderer.AddGradientPoint ( 0.75, utils::Color (r, g, b, 255));
	}

	renderer.EnableLight();
	renderer.SetLightContrast(2.0);
	renderer.SetLightBrightness(1.8);
	renderer.Render();

	unsigned char* buffer = convertImageToRGBABuffer(image);
	return buffer;
}

#ifdef __cplusplus
}
#endif

unsigned char* convertImageToRGBABuffer(utils::Image& image) {
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
			++pSource;
		}
	}

	return buffer;
}
