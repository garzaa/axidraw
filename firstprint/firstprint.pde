import processing.svg.*;
import java.util.*;
import controlP5.*;

ControlP5 cp5;

boolean exportSVG = false;

int nPoints = 3;
float nShapes = 20;
float rMin = 10;
float rMax = 200;

float sliderTicks2;

float nWaves = 1;
float angleRotation = 0.4;

boolean showingControls = true;

void setup() {
  size(800, 800);
  noFill();
  cp5 = new ControlP5(this);

  cp5
    .addSlider("nPoints")
    .setLabel("nPoints")
    .setRange(3, 10)
    .setValue(5)
    .setNumberOfTickMarks(7)
  ;

  cp5
    .addSlider("angleRotation")
    .setLabel("angleMax")
    .setRange(0, 1)
    .setValue(1)
  ;

  cp5
    .addSlider("nShapes")
    .setLabel("nShapes")
    .setRange(5, 100)
    .setNumberOfTickMarks(45)
    .setValue(20)
  ;

  cp5
    .addRange("radius")
    .setBroadcast(false)
    .setLabel("radius range")
    .setRange(0,300)
    .setRangeValues(rMin,rMax)
    .setBroadcast(true)
  ;
}

void controlEvent(ControlEvent theControlEvent) {
  if (theControlEvent.isFrom("radius")) {
    rMin = int(theControlEvent.getController().getArrayValue(0));
    rMax = int(theControlEvent.getController().getArrayValue(1));
  }
}

void draw() {
  background(255);

  if (exportSVG) {
    beginRecord(SVG, "exports/export_"+timestamp()+".svg");
  }

  for (int i=0; i<nShapes; i++) {
    circle(
      nPoints,
      map(i, 0, nShapes-1, rMax, rMin), 
      map(i, 0, nShapes-1, 0, nWaves)
    );
  }

  if (exportSVG) {
    endRecord();
    exportSVG = false;
    System.out.println("exported SVG");
  }
}

void keyPressed() {
  if (key == 'c') {
    System.out.println("c key pressed");
    showingControls = !showingControls;
    cp5.setAutoDraw(showingControls);
  } else if (key == 'e') {
    System.out.println("exporting SVG");
    hideControls();
    exportSVG = true;
  }
}

void hideControls() {
  showingControls = false;
  cp5.setAutoDraw(showingControls);
}

void circle(int p, float radius, float frac) {
  push();
  translate(400, 400);
  beginShape();
  for (int i=0; i<p; i++) {
    float angle = -PI/2 + float(i)*TWO_PI / float(p);
    angle += (angleRotation/PI) * sin(TWO_PI * frac);
    vertex(radius * cos(angle), radius*sin(angle));
  }
  endShape(CLOSE);
  pop();
}

String timestamp() {
  Calendar now = Calendar.getInstance();
  return String.format("%1$ty%1$tm%1$td_%1$tH%1$tM%1$tS", now);
}
