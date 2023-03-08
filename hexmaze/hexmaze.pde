import java.util.*;
import processing.svg.*;
import controlP5.*;

ControlP5 cp5;
boolean exportSVG = false;

int canvasSize = 800;

int cellHeight = 45;
int cells = 15;
float cellWidth = (float) (Math.sqrt(3)/2f) * cellHeight;
float yRad = cellHeight/2f;
float xRad = cellWidth/2f;
float mazeWidth = cells * cellWidth;
float mazeHeight = cells * cellHeight * 0.75f;
float marginX = (canvasSize - mazeWidth)/2f;
float marginY = (canvasSize - mazeHeight)/2f;

boolean drawBorders = true;
boolean drawConnections = false;

float cellSpacing = 1;

int pointsPerLine = 2;

enum Direction {
	NW, NE,
	W, E,
	SW, SE
}

vec2 stripeOffset = new vec2(-1, 0);

color cn = #C5AFA4;
color fg = #031927;
color bg = #BA1200;

Map<Direction, vec2> offsets = new HashMap<Direction, vec2>();
// every odd row has their NW/NE and SW/SE neighbors shifted left by 1
Map<Direction, vec2> oddOffsets = new HashMap<Direction, vec2>();
Map<Direction, Direction> opposites = new HashMap<Direction, Direction>();

void initDicts() {
	offsets.put(Direction.NW, new vec2( 0, -1));
	offsets.put(Direction.NE, new vec2( 1, -1));
	offsets.put(Direction.E,  new vec2( 1,  0));
	offsets.put(Direction.SE, new vec2( 1,  1));
	offsets.put(Direction.SW, new vec2( 0,  1));
	offsets.put(Direction.W,  new vec2( -1, 0));

	opposites.put(Direction.NW, Direction.SE);
	opposites.put(Direction.NE, Direction.SW);
	opposites.put(Direction.E, Direction.W);
	opposites.put(Direction.SE, Direction.NW);
	opposites.put(Direction.SW, Direction.NE);
	opposites.put(Direction.W, Direction.E);

	oddOffsets.put(Direction.NW, new vec2( -1, -1));
	oddOffsets.put(Direction.NE, new vec2( 0, -1));
	oddOffsets.put(Direction.E,  new vec2( 1,  0));
	oddOffsets.put(Direction.SE, new vec2( 0,  1));
	oddOffsets.put(Direction.SW, new vec2( -1,  1));
	oddOffsets.put(Direction.W,  new vec2( -1, 0));
}

public class HexCell {
	public Set<Direction> connections = new HashSet<Direction>();
	List<vec2> vertices = new ArrayList(6);
	public int x = 0;
	public int y = 0;
	public boolean visited = false;

	public boolean highlighted = false;

	public float px, py;

	public HexCell(int x, int y) {
		this.x = x;
		this.y = y;

		this.px = x*cellWidth;
		this.py = y*cellHeight * 0.75f;

		// then move left/right based on the index order
		if (isOdd()) {
			px -= cellWidth/4;
		} else {
			px += cellWidth/4;
		}


		// Y has to be negative because origin is top left
		// clockwise starting from the top (upper left NE vertex)
		vertices.add(new vec2(px, 		py-yRad));
		vertices.add(new vec2(px+xRad, py-yRad*0.5f));
		vertices.add(new vec2(px+xRad, py+yRad*0.5f));
		vertices.add(new vec2(px, 		py+yRad));
		vertices.add(new vec2(px-xRad, py+yRad*0.5f));
		vertices.add(new vec2(px-xRad, py-yRad*0.5f));
	}

	public vec2 getNeighborCoords(Direction d) {
		if (!isOdd()) {
				return new vec2(
				this.x + offsets.get(d).x,
				this.y + offsets.get(d).y
			);
		}
		return new vec2(
			this.x + oddOffsets.get(d).x,
			this.y + oddOffsets.get(d).y
		);
	}

	boolean isOdd() {
		return y % 2 == 1;
	}

	public boolean hasConnection(Direction d) {
		return connections.contains(d);
	}

	public void connect(Direction d) {
		connections.add(d);
	}

	public void draw() {
		// start at center

		// draw the cell borders clockwise from the top
		// https://stackoverflow.com/questions/33967062/how-to-render-a-hex-grid
		// TODO: only draw necessary vertices
		// just draw NW, NE, E (0-2) unless at the left side and below
		// or at the right side and above
		// or at the bottom

		// always draw the top three
		if (drawBorders) {
			stroke(fg);
			if (!hasConnection(Direction.NW)) drawSegment(5);
			if (!hasConnection(Direction.NE)) drawSegment(0);
			if (!hasConnection(Direction.E)) drawSegment(1);

			// if on the bottom, draw the bottom two (4 and 8 oclock)
			if (
				y == cells-1
			) {
				drawSegment(3);
				drawSegment(2);
			}

			// but also take care of when it's jutting out on the side
			if ((isOdd() && x==0)) {
				drawSegment(3);
			} else if (!isOdd() && x==cells-1) {
				drawSegment(2);
			}

			// then if on the left side, draw the left
			if (x == 0) {
				drawSegment(4);
			}
		}

		push();
		// stroke(100);
		// if (isOdd() && !highlighted) {
		// 	ellipse(px, py, 4, 4);
		// }
		
		if (highlighted) {
			// stroke(0xffff0000);
			// line(px+5, py+5, px-5, py-5);
			// line(px-5, py+5, px+5, py-5);
		}
		if (drawConnections) {
			stroke(cn);
			for (Direction d : connections) {
				// this is interesting - it's trying to connect with
				// something outside the grid after the reverse connection
				// even numbered rows are visually 1 too far to the left
				vec2 v = getNeighborCoords(d);
				HexCell c = rows.get((int) v.x).get((int) v.y);
				line(px, py, c.px, c.py);
			}
		}
		pop();
	}

	void drawSegment(int startIndex) {
		int c = vertices.size();
		doLine(vertices.get(startIndex), vertices.get((startIndex+1) % c), pointsPerLine);
	}

	public String toString() {
		String s = "(" + x + ", " + y + ")";
		if (isOdd()) s += " (odd)";
		return s;
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
		float cx = noise(x/perlinXD + perlinXO, y/perlinXD + perlinXO, 0);
		float cy = noise(x/perlinYD + perlinYO, y/perlinYD + perlinYO, 1000);
		// need to map these from (0, 1) to (-1, 1) for centralizing them
		cx = (cx*2 - 1)*perlinXA;
		cy = (cy*2 - 1)*perlinYA;
		return new vec2(x+cx, y+cy);
	}

	public float xydist(vec2 p2) {
		return abs(p2.x-x) + abs(p2.y-y);
	}

	public vec2 selfLerp(vec2 b, float t) {
		return new vec2(lerp(x, b.x, t), lerp(y, b.y, t));
	}

	// no pass by value houghough
	public vec2 add(vec2 b) {
		return new vec2(this.x + b.x, this.y + b.y);
	}
}

// store each cell as a bit-masked integer
ArrayList<ArrayList<HexCell>> rows = new ArrayList<ArrayList<HexCell>>();

Stack<HexCell> cellStack = new Stack<HexCell>();

Random random;

// these should be unperturbed, and then be perturbed along the line
void doLine(vec2 rawStart, vec2 rawEnd, int p) {
	beginShape();
	vec2 prev = null;
	for (float i=0; i<=p; i++) {
		vec2 v = rawStart.selfLerp(rawEnd, i/p).perturb();
		vertex(v.x * cellSpacing, v.y * cellSpacing);
	}
	endShape();
}

void initRows() {
	for (int x=0; x<cells; x++) {
		rows.add(new ArrayList<HexCell>());
		for (int y=0; y<cells; y++) {
			rows.get(x).add(new HexCell(x, y));
		}
	}
}

// TODO: try this, but also switch back to sinewaves but vertical (for a drip effect)
float perlinXA = 1;
float perlinXO = 0;
float perlinXD = 1;

float perlinYA = 1;
float perlinYO = 0;
float perlinYD = 0;

ColorPicker FG;
ColorPicker BG;

void initControls() {
	cp5 = new ControlP5(this);
	cp5
		.addSlider("perlinXA")
		.setLabel("perlinAmp")
		.setRange(0, 100)
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
		.addSlider("perlinYA")
		.setLabel("perlinYAmp")
		.setRange(0, 100)
		.setValue(0)
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

void setup() {
	size(800, 800);
	noFill();

	xRad *= cellSpacing;
	yRad *= cellSpacing;

	initDicts();
	initRows();
	initControls();

	random = new Random();

	// choose the initial cell, mark as visited and push to the stack
	int x = random.nextInt(0, cells);
	int y = random.nextInt(0, cells);
	HexCell startHexCell = rows.get(x).get(y);
	startHexCell.visited = true;
	cellStack.push(startHexCell);

	// turn this off for svg exporting
	pixelDensity(displayDensity());
	carve();
}

void draw() {
	strokeWeight(10);
	background(bg);
	stroke(fg);

	if (exportSVG) {
    	beginRecord(SVG, "exports/export_"+timestamp()+".svg");
  	}

	drawMaze();

	if (exportSVG) {
		exportSVG = false;
		endRecord();
		cp5.setAutoDraw(true);
		System.out.println("exported SVG");
	}
}

HexCell current = null;

void carve() {
	if (current != null) current.highlighted = false;
	// while the stack isn't empty:
	while (!cellStack.empty()) {
		// pop a current cell
		current = cellStack.pop();
		current.highlighted = true;
		// choose one of the unvisited neighbors, then connect them
		ArrayList<Direction> validNeighbors = new ArrayList<Direction>();

		// get all directions first
		for (Direction d : offsets.keySet()) {
			vec2 nc = current.getNeighborCoords(d);
			// if it's in the grid
			if (
				nc.x >= 0
				&& nc.x < cells
				&& nc.y >= 0
				&& nc.y < cells
			) {
				// then add its cell to the list of unvisited neighbors
				if (!rows.get((int) nc.x).get((int) nc.y).visited) {
					validNeighbors.add(d);
				}
			}
		}

		// if there are unvisited neighbors
		if (validNeighbors.size() > 0) {
			// push current cell to the stack
			cellStack.push(current);

			// pick a random neighbor from the list of available coordinates
			Direction d = validNeighbors.get(random.nextInt(0, validNeighbors.size()));

			// then connect the two
			current.connect(d);
			vec2 neighborCoords = current.getNeighborCoords(d);
			HexCell neighbor = rows.get((int) neighborCoords.x).get((int) neighborCoords.y);
			// this will connect with shit outside the grid
			if (drawBorders) {
				neighbor.connect(opposites.get(d));
			}

			// mark the chosen cell as visited and push it to the stk
			neighbor.visited = true;
			cellStack.push(neighbor);
		}
	}
	current.highlighted = false;
}

void drawMaze() {
	push();
			float mod = cells % 2 == 0 ? 1f : 0.5f;
			translate(marginX+cellWidth*mod, marginY+cellHeight * mod);
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
	} else if (key == 'q') {
		exit();
	} else if (key == 's') {
		save("exports/"+timestamp()+".png");
		println("saved png");
	}
}

String timestamp() {
  Calendar now = Calendar.getInstance();
  return String.format("%1$ty%1$tm%1$td_%1$tH%1$tM%1$tS", now);
}
