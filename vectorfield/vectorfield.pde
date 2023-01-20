import java.util.*;
import processing.svg.*;
import controlP5.*;

ControlP5 cp5;
boolean exportSVG = false;

// 8x6 in
int w = 768;
int h = 576;

int xSize = 600;
int ySize = 300;

float thetaBias = 1;
float perlinXO = 0;
float perlinXD = 1;

float magBias = 1;
float perlinYO = 0;
float perlinYD = 0;

int stepSize = 1;

// TODO: add line length variance?
// also based on perlin noise?
float lineLength = 10;
int marginX = (w-xSize)/2;
int marginY = (h-ySize)/2;

void settings() {
	size(w, h);
}

void setup() {
	noFill();
	initControls();
	background(255);

	// vector fields for both x and y
	// draw lines in a grid, distort the space around them?
	// write a function that takes a vec2 and perturbs it
	// then a certain amount of segments per line
	// ok
}

void draw() {
	background(255);
	if (exportSVG) {
    	beginRecord(SVG, "export_"+timestamp()+".svg");
  	}
	// rect(marginX, marginY, xSize, ySize);
	// draw diagonal lines
	// these are ending at xSize-margin
	for (int i=marginX; i<xSize+marginX; i+=lineLength) {
		for (int j=marginY; j<ySize+marginY; j+=lineLength) {
			drawline(i, j);
		}
	}

	if (exportSVG) {
		exportSVG = false;
		endRecord();
		cp5.setAutoDraw(true);
		System.out.println("exported SVG");
		println("done");
	}
}

void drawline(int x, int y) {
	// random walk from 0 to lineLength
	PVector v = new PVector(x, y);
	beginShape();
	vertex(v.x, v.y);
	for (int i=0; i<lineLength; i+=stepSize) {
		// move stepsize in the direction at the current vertex
		float a = theta(v);
		float m = mag(v);
		v.x += cos(a)*m;
		v.y += sin(a)*m;
		// then drop a vertex there
		vertex(v.x, v.y);
	}
	endShape();
}

// get a vector in 2d perlin-space, convert to a radians rotation
float theta(PVector v) {
	float x = noise((v.x + perlinXO)/perlinXD, (v.y + perlinYO)/perlinYD, 0);
	return x * TWO_PI + thetaBias;
}

// then also get a random magnitude
float mag(PVector v) {
	float x = noise((v.x + perlinXO)/perlinXD, (v.y + perlinYO)/perlinYD, 1000);
	return (x) * magBias;
}

void initControls() {
	cp5 = new ControlP5(this);
	cp5
		.addSlider("thetaBias")
		.setLabel("thetaBias")
		.setRange(0, TWO_PI)
		.setValue(0)
		.setNumberOfTickMarks(100)
		.setColorCaptionLabel(50)
		;
	
	cp5
		.addSlider("perlinXO")
		.setLabel("perlinXOff")
		.setRange(-100, 100)
		.setValue(-33)
		.setNumberOfTickMarks(201)
		.setPosition(10, 40)
		.setColorCaptionLabel(50)
		;

	cp5
		.addSlider("perlinXD")
		.setLabel("perlinXD")
		.setRange(10, 1000)
		.setValue(340)
		.setPosition(10, 50)
		.setColorCaptionLabel(50)
		;
	
	cp5
		.addSlider("magBias")
		.setLabel("magBias")
		.setRange(0.01, 50)
		.setValue(1)
		.setNumberOfTickMarks(100)
		.setPosition(210, 30)
		.setColorCaptionLabel(50)
		;
	
	cp5
		.addSlider("perlinYO")
		.setLabel("perlinYOff")
		.setRange(-100, 100)
		.setValue(-17)
		.setNumberOfTickMarks(201)
		.setPosition(210, 40)
		.setColorCaptionLabel(50)
		;

	cp5
		.addSlider("perlinYD")
		.setLabel("perlinYD")
		.setRange(10, 1000)
		.setValue(340)
		.setPosition(210, 50)
		.setColorCaptionLabel(50)
		;
}

void keyPressed() {
	if (key == 'e') {
		System.out.println("exporting SVG");
		cp5.setAutoDraw(false);
		exportSVG = true;
	} else if (key == 'q') {
		exit();
	}
}

String timestamp() {
  Calendar now = Calendar.getInstance();
  return String.format("%1$ty%1$tm%1$td_%1$tH%1$tM%1$tS", now);
}
