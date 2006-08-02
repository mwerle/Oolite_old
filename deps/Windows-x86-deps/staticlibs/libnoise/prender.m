#import <SDL.h>
#import <SDL_image.h>
#import <GL/gl.h>
#import <GL/glu.h>
#import <math.h>

#import <noise/ptg.h>

#import <Foundation/NSGeometry.h>
SDL_Surface* surface;

void initSDL(void);
GLuint getCloudTexture(void);
GLuint getPlanetTexture(void);
GLuint loadTexture(const char* filename);

int ptg(int a, int b, int c, int d, int e, int f);

int main(int argc, char** argv) {
	initSDL();

	SDL_Event event;
	SDL_KeyboardEvent* kbd_event;

	//GLuint tex = loadTexture("tex.png");
	GLuint earth = getPlanetTexture();
	GLuint clouds = getCloudTexture();
	GLfloat yrot = 0.0f;

	BOOL keepGoing = YES;
//	if (tex < 1)
//		keepGoing = NO;
//	else

	GLUquadricObj* gluQuad = gluNewQuadric();
	gluQuadricOrientation(gluQuad, GLU_OUTSIDE);
	gluQuadricNormals(gluQuad, GLU_SMOOTH);
	gluQuadricTexture(gluQuad, GL_TRUE);

	glColor4f(0.0f, 0.0f, 0.0f, 1.0f);

	while (YES) {
		while (SDL_PollEvent(&event)) {
		switch (event.type) {
			case SDL_KEYDOWN:
				kbd_event = (SDL_KeyboardEvent*)&event;
					if (kbd_event->keysym.sym == SDLK_ESCAPE) {
						keepGoing = NO;
					}
				break;
			}
		}
		if (keepGoing == NO)
			break;

		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
/*
		glLoadIdentity();
		glDisable( GL_TEXTURE_2D );
		glTranslatef(0.0f, 0.0f, -200.0f);
		glColor4f(1.0, 0.0, 0.0, 1.0);
		glBegin(GL_QUADS);
			glVertex3f(-300, -30, 0); //glTexCoord2d(0, 0); glNormal3f(0.0, 0.0, 1.0);
			glVertex3f( 30, -30, 0); //glTexCoord2d(1, 0); glNormal3f(0.0, 0.0, 1.0);
			glVertex3f( 30,  30, 0); //glTexCoord2d(1, 1); glNormal3f(0.0, 0.0, 1.0);
			glVertex3f(-300,  30, 0); //glTexCoord2d(0, 1); glNormal3f(0.0, 0.0, 1.0);
		glEnd();
*/
		glLoadIdentity();
		glTranslatef(0.0f, 00.0f, -50.0f);

		glEnable( GL_TEXTURE_2D );
		glColor4f(1.0, 1.0, 1.0, 1.0);

		glBindTexture(GL_TEXTURE_2D, earth);
		gluSphere(gluQuad, 30.0, 90, 90);

		glRotatef(yrot, 0.0, 1.0, 0.0);
		//glRotatef(180.0, 0.0, 0.0, 1.0);
		yrot += 0.001;
		if (yrot > 360.0f)
			yrot = 0.0f;

		glBindTexture(GL_TEXTURE_2D, clouds);
		gluSphere(gluQuad, 30.2, 90, 90);

		SDL_GL_SwapBuffers();
	}

	gluDeleteQuadric(gluQuad);

	glDeleteTextures(1, &clouds);
	SDL_FreeSurface(surface);
}

void initSDL(void) {
	if (SDL_Init(SDL_INIT_VIDEO) < 0) {
		//NSLog(@"Unable to init SDL: %s\n", SDL_GetError());
		return;
	}

	SDL_GL_SetAttribute(SDL_GL_RED_SIZE, 5);
	SDL_GL_SetAttribute(SDL_GL_GREEN_SIZE, 5);
	SDL_GL_SetAttribute(SDL_GL_BLUE_SIZE, 5);
	SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, 16);
	SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);

	int videoModeFlags = SDL_HWSURFACE | SDL_OPENGL;
	videoModeFlags |= SDL_RESIZABLE;
	surface = SDL_SetVideoMode(800, 600, 32, videoModeFlags);

	glShadeModel(GL_FLAT);
	glClearColor(0.0, 0.0, 0.0, 0.0);
    glClear(GL_COLOR_BUFFER_BIT);

	glClearDepth(200000);
	glViewport( 0, 0, 800, 600);

	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	glFrustum(-1, 1, -1, 1, 1.0, 200000000);

	glMatrixMode( GL_MODELVIEW);

	glEnable( GL_TEXTURE_2D );
	glEnable( GL_DEPTH_TEST);		// depth buffer
	glDepthFunc( GL_LESS);			// depth buffer

	glFrontFace( GL_CCW);			// face culling - front faces are AntiClockwise!
	glCullFace( GL_BACK);			// face culling
	glEnable( GL_CULL_FACE);		// face culling

	glEnable(GL_ALPHA_TEST);
	glEnable( GL_BLEND);								// alpha blending
	glBlendFunc( GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);	// alpha blending
/*
	GLfloat	sun_ambient[] =	{0.0, 0.0, 0.0, 1.0};
	GLfloat	sun_diffuse[] =	{1.0, 1.0, 1.0, 1.0};
	GLfloat	sun_specular[] = 	{1.0, 1.0, 1.0, 1.0};
	GLfloat	sun_center_position[] = {400.0, 400.0, 0.0, 1.0};

	glLightfv(GL_LIGHT1, GL_AMBIENT, sun_ambient);
	glLightfv(GL_LIGHT1, GL_SPECULAR, sun_specular);
	glLightfv(GL_LIGHT1, GL_DIFFUSE, sun_diffuse);
	glLightfv(GL_LIGHT1, GL_POSITION, sun_center_position);

	GLfloat	white[] = { 1.0, 1.0, 1.0, 1.0};	// white light
	glLightfv(GL_LIGHT0, GL_AMBIENT, white);
	glLightfv(GL_LIGHT0, GL_DIFFUSE, white);
	glLightfv(GL_LIGHT0, GL_SPECULAR, white);

   	glEnable(GL_LIGHT1);
	//glEnable(GL_LIGHT0);
	glEnable(GL_LIGHTING);
*/
	glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
}

GLuint getCloudTexture(void) {
	GLuint texName;
	int	texture_w = 512;
	int	texture_h = 256;

	unsigned char* texBytes = (unsigned char*)generateClouds(1,2,3,4,5,6);
	if (texBytes == 0)
	{
		return 0;
	}

	glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
	glGenTextures(1, &texName);			// get a new unique texture name
	glBindTexture(GL_TEXTURE_2D, texName);

	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);	// adjust this
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);	// adjust this

	glTexImage2D(GL_TEXTURE_2D, 0, 4, texture_w, texture_h, 0, GL_RGBA, GL_UNSIGNED_BYTE, texBytes);
	free(texBytes);
	return texName;
}

GLuint getPlanetTexture(void) {
	GLuint texName;
	int	texture_w = 512;
	int	texture_h = 256;

	unsigned char* texBytes = (unsigned char*)generatePlanet(1,2,3,4,5,6);
	if (texBytes == 0)
	{
		return 0;
	}

	glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
	glGenTextures(1, &texName);			// get a new unique texture name
	glBindTexture(GL_TEXTURE_2D, texName);

	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);	// adjust this
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);	// adjust this

	glTexImage2D(GL_TEXTURE_2D, 0, 4, texture_w, texture_h, 0, GL_RGBA, GL_UNSIGNED_BYTE, texBytes);
	free(texBytes);
	return texName;
}

GLuint loadTexture(const char* filename) {
	SDL_Surface* textureSurface;
	NSSize imageSize;
	GLuint texName;
	unsigned char* texBytes;
	BOOL freeTexBytes;
	int texture_h = 4;
	int texture_w = 4;
	int image_h, image_w;
	int n_planes, im_bytes, tex_bytes;
	int im_bytesPerRow;
	int texi = 0;

	textureSurface = IMG_Load(filename);
	imageSize = NSMakeSize(textureSurface->w, textureSurface->h);
	image_w = imageSize.width;
	image_h = imageSize.height;

	while (texture_w < image_w)
		texture_w *= 2;
	while (texture_h < image_h)
		texture_h *= 2;

	n_planes = textureSurface->format->BytesPerPixel;
	im_bytesPerRow = textureSurface->pitch;
	unsigned char* imageBuffer = textureSurface->pixels;
	im_bytes = image_w * image_h * n_planes;
	tex_bytes = texture_w * texture_h * n_planes;
	im_bytesPerRow = textureSurface->pitch;

	if ((texture_w > image_w)||(texture_h > image_h)) {
		texBytes = malloc(tex_bytes);
		freeTexBytes = YES;

		// do bilinear scaling
		int x, y, n;
		float texel_w = (float)image_w / (float)texture_w;
		float texel_h = (float)image_h / (float)texture_h;

		for ( y = 0; y < texture_h; y++)
		{
			float y_lo = texel_h * y;
			float y_hi = y_lo + texel_h - 0.001;
			int y0 = floor(y_lo);
			int y1 = floor(y_hi);

			float py0 = 1.0;
			float py1 = 0.0;
			if (y1 > y0)
			{
				py0 = (y1 - y_lo) / texel_h;
				py1 = 1.0 - py0;
			}

			for ( x = 0; x < texture_w; x++)
			{
				float x_lo = texel_w * x;
				float x_hi = x_lo + texel_w - 0.001;
				int x0 = floor(x_lo);
				int x1 = floor(x_hi);
				float acc = 0;

				float px0 = 1.0;
				float px1 = 0.0;
				if (x1 > x0)
				{
					px0 = (x1 - x_lo) / texel_w;
					px1 = 1.0 - px0;
				}

				int	xy00 = y0 * im_bytesPerRow + n_planes * x0;
				int	xy01 = y0 * im_bytesPerRow + n_planes * x1;
				int	xy10 = y1 * im_bytesPerRow + n_planes * x0;
				int	xy11 = y1 * im_bytesPerRow + n_planes * x1;

				for (n = 0; n < n_planes; n++)
				{
					acc = py0 * (px0 * imageBuffer[ xy00 + n] + px1 * imageBuffer[ xy10 + n])
						+ py1 * (px0 * imageBuffer[ xy01 + n] + px1 * imageBuffer[ xy11 + n]);
					texBytes[ texi++] = (char)acc;	// float -> char
				}
			}
		}
	}
	else
	{
		// no scaling required - we will use the image data directly
		texBytes = imageBuffer;
		freeTexBytes = NO;
	}

	glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
	glGenTextures(1, &texName);
	glBindTexture(GL_TEXTURE_2D, texName);

	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);	// adjust this
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);	// adjust this

	switch (n_planes)	// fromt he number of planes work out how to treat the image as a texture
	{
		case 4:
			glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, texture_w, texture_h, 0, GL_RGBA, GL_UNSIGNED_BYTE, texBytes);
			break;
		case 3:
			glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, texture_w, texture_h, 0, GL_RGB, GL_UNSIGNED_BYTE, texBytes);
			break;
		case 1:
			glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, texture_w, texture_h, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, texBytes);
			break;
		default:
			texName = 0;
	}

	if (freeTexBytes)
		free(texBytes);

	SDL_FreeSurface(textureSurface);
	return texName;
}
