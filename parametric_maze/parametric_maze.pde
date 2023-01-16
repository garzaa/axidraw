import java.util.*;
import processing.svg.*;
import controlP5.*;

ControlP5 cp5;
boolean exportSVG = false;

int canvasSize = 800;

int cellSize = 6;
int mazeSize = 360;

int cells = mazeSize/cellSize;
int margin = (canvasSize-mazeSize)/2;
int pointsPerLine = 6;

int N = 0b0001;
int S = 0b0010;
int E = 0b0100;
int W = 0b1000;

ArrayList<Integer> D = new ArrayList<Integer>();
Map<Integer, Integer> DY = new HashMap<Integer, Integer>();
Map<Integer, Integer> DX = new HashMap<Integer, Integer>();
Map<Integer, Integer> XD = new HashMap<Integer, Integer>();
Map<Integer, Integer> YD = new HashMap<Integer, Integer>();
Map<Integer, Integer> Opposite = new HashMap<Integer, Integer>();

public class Cell {
	public int direction = 0;
	public int x = 0;
	public int y = 0;
	public boolean visited = false;

	public Cell(int x, int y) {
		this.x = x;
		this.y = y;
	}

	void draw() {
		// start at top left corner
		float px = x*cellSize - cellSize/2;
		float py = y*cellSize - cellSize/2;

		vec2 tl = new vec2(px, py);
		vec2 bl = new vec2(px, py+cellSize);
		vec2 tr = new vec2(px+cellSize, py);
		vec2 br = new vec2(px+cellSize, py+cellSize);

		if ((x == cells-1) || ((direction&E) == 0)) doLine(tr, br);
		if (x == 0) doLine(tl, bl);
		if ((y == cells-1) || ((direction&S) == 0)) doLine(bl, br);
		if (y == 0) doLine(tl, tr);
	}

	// these should be unperturbed, and then be perturbed along the line
	void doLine(vec2 rawStart, vec2 rawEnd) {
		// continuously perturb lines along perturbation axis
		// do multiple segments if the distance is greater than cellsize
		vec2 start = rawStart.perturb();
		vec2 end = rawEnd.perturb();

		if (start.xydist(end) <= cellSize) {
			line(
				start.x, start.y,
				end.x, end.y
			);
		} else {
			// now we draw multi-point lines between perturbed coordinates
			beginShape();
			for (float i=0; i<=pointsPerLine; i++) {
				// lerp the raw point between start and end
				vec2 v = rawStart.selfLerp(rawEnd, i/pointsPerLine).perturb();
				vertex(v.x, v.y);
			}
			endShape();
		}
	}
}

class vec2 {
	float x;
	float y;

	public vec2(float x, float y) {
		this.x = x;
		this.y = y;
	}

	public vec2 perturb() {
		float cx = sin(y/p1/PI + o1) * a1;
		cx *= sin(y/ampP/PI + ampO) * ampA;
		float cy = 0;
		return new vec2(x+cx, y+cy);
	}

	public float xydist(vec2 p2) {
		return abs(p2.x-x) + abs(p2.y-y);
	}

	public vec2 selfLerp(vec2 b, float t) {
		return new vec2(lerp(x, b.x, t), lerp(y, b.y, t));
	}
}

// store each cell as a bit-masked integer
ArrayList<ArrayList<Cell>> rows = new ArrayList<ArrayList<Cell>>();

Stack<Cell> cellStack = new Stack<Cell>();

Random random;

void initDicts() {
	D.add(N);
	D.add(S);
	D.add(E);
	D.add(W);

	// (0, 0) is at the top left
	DY.put(E, 0);
	DY.put(W, 0);
	DY.put(N, -1);
	DY.put(S, 1);

	DX.put(E, 1);
	DX.put(W, -1);
	DX.put(N, 0);
	DX.put(S, 0);

	YD.put(-1, N);
	YD.put(1, S);
	XD.put(-1, W);
	XD.put(1, E);


	Opposite.put(N, S);
	Opposite.put(S, N);
	Opposite.put(E, W);
	Opposite.put(W, E);
}

void initRows() {
	for (int x=0; x<cells; x++) {
		rows.add(new ArrayList<Cell>());
		for (int y=0; y<cells; y++) {
			rows.get(x).add(new Cell(x, y));
		}
	}
}

// horizontal distortion
float a1 = 0;
float o1 = 0;
float p1 = 0;

// horizontal distortion amplitude
float ampA = 0;
float ampO = 0;
float ampP = 0;

void initControls() {
	cp5 = new ControlP5(this);
	cp5
		.addSlider("a1")
		.setLabel("amplitude1")
		.setRange(0, 100)
		.setValue(100)
		.setNumberOfTickMarks(100)
		.setColorCaptionLabel(50)
		;
	
	cp5
		.addSlider("o1")
		.setLabel("offset1")
		.setRange(-1, 1)
		.setValue(-0.18)
		.setNumberOfTickMarks(50)
		.setPosition(10, 40)
		.setColorCaptionLabel(50)
		;

	cp5
		.addSlider("p1")
		.setLabel("period1")
		.setRange(0.01, 20)
		.setValue(3)
		.setPosition(10, 50)
		.setColorCaptionLabel(50)
		;

	
	cp5
		.addSlider("ampA")
		.setLabel("amplitudeStrength")
		.setRange(-1, 1)
		.setValue(.55)
		.setNumberOfTickMarks(50)
		.setPosition(210, 30)
		.setColorCaptionLabel(50)
		;
	
	cp5
		.addSlider("ampO")
		.setLabel("amplitudeOffset")
		.setRange(-1, 1)
		.setValue(0.02)
		.setNumberOfTickMarks(50)
		.setPosition(210, 40)
		.setColorCaptionLabel(50)
		;

	cp5
		.addSlider("ampP")
		.setLabel("amplitudePeriod")
		.setRange(0.01, 200)
		.setValue(1)
		.setPosition(210, 50)
		.setColorCaptionLabel(50)
		;
}

void setup() {
	size(800, 800);
	noFill();
	background(255);

	initControls();
	initDicts();
	initRows();

	random = new Random();

	// choose the initial cell, mark as visited and push to the stack
	int x = random.nextInt(0, cells);
	int y = random.nextInt(0, cells);
	Cell startCell = rows.get(x).get(y);
	startCell.visited = true;
	cellStack.push(startCell);
}

void draw() {
	background(255);

	if (exportSVG) {
    	beginRecord(SVG, "exports/export_"+timestamp()+".svg");
  	}

	// while the stack isn't empty:
	if (!cellStack.empty()) {
		// pop a current cell
		Cell current = cellStack.pop();
		// choose one of the unvisited neighbors
		// remove a wall between the current cell and the chosen cell
		ArrayList<Cell> neighbors = new ArrayList<Cell>();
		int cx = current.x;
		int cy = current.y;
		for (Integer direction : D) {
			// get coordinates of the current neighbor
			int nx = cx + DX.get(direction);
			int ny = cy + DY.get(direction);

			// if that neighbor is in the grid
			if (nx>=0 && nx<cells && ny>=0 && ny<cells) {
				// add that neighbor to the list of neighbors
				Cell neighborCell = rows.get(nx).get(ny);
				if (!neighborCell.visited) {
					neighbors.add(neighborCell);
				}
			}
		}

		// if there are unvisited neighbors
		if (neighbors.size() > 0) {
			// push current cell to the stack
			cellStack.push(current);

			// pick a random unvisited neighbor
			Cell chosenNeighbor = neighbors.get(random.nextInt(0, neighbors.size()));
			// remove walls between it and the current cell
			int dx = chosenNeighbor.x - current.x;
			int dy = chosenNeighbor.y - current.y;
			if (dx != 0) {
				current.direction = current.direction | XD.get(dx);
				chosenNeighbor.direction = chosenNeighbor.direction | XD.get(-dx);
			}
			if (dy != 0) {
				current.direction = current.direction | YD.get(dy);
				chosenNeighbor.direction = chosenNeighbor.direction | YD.get(-dy);
			}
			// mark the chosen cell as visited and push it to the stack
			chosenNeighbor.visited = true;
			cellStack.push(chosenNeighbor);
		}
	}

	drawMaze();

	if (exportSVG) {
    endRecord();
    exportSVG = false;
	cp5.setAutoDraw(true);
    System.out.println("exported SVG");
  }
}

void drawMaze() {
	push();
		translate(margin, margin);
		for (int i=0; i<rows.size(); i++) {
			for (int j=0; j<rows.get(i).size(); j++) {
				rows.get(i).get(j).draw();
			}
		}
	pop();
}

void keyPressed() {
	if (key == 'e') {
		System.out.println("exporting SVG");
		cp5.setAutoDraw(false);
		exportSVG = true;
	}
}

String timestamp() {
  Calendar now = Calendar.getInstance();
  return String.format("%1$ty%1$tm%1$td_%1$tH%1$tM%1$tS", now);
}
