import java.util.*;
import processing.svg.*;
import controlP5.*;

ControlP5 cp5;
boolean exportSVG = false;

int canvasSize = 800;

int cellHeight = 20;
int cells = 20;
float cellWidth = (float) (Math.sqrt(3)/2f) * cellHeight;
float yRad = cellHeight/2f;
float xRad = cellWidth/2f;
float mazeWidth = cells * cellWidth;
float mazeHeight = cells * cellHeight;

int pointsPerLine = 1;

enum Direction {
	NW, NE,
	W, E,
	SW, SE
}

Map<Direction, vec2> offsets = new HashMap<Direction, vec2>();
void initDicts() {
	offsets.put(Direction.NW, new vec2( 0, -1));
	offsets.put(Direction.NE, new vec2( 1, -1));
	offsets.put(Direction.W,  new vec2( 0, -1));
	offsets.put(Direction.E,  new vec2( 0,  1));
	offsets.put(Direction.SW, new vec2( 0,  1));
	offsets.put(Direction.SE, new vec2( 1,  1));
}

public class HexCell {
	public Set<Direction> directions = new HashSet<Direction>();
	List<vec2> vertices = new ArrayList(6);
	public int x = 0;
	public int y = 0;
	public boolean visited = false;

	public HexCell(int x, int y) {
		this.x = x;
		this.y = y;

		float px = x*cellWidth;
		float py = y*cellHeight * 0.75f;

		// then move left/right based on the index order
		if (y % 2 == 0) {
			px += cellWidth/4;
		} else {
			px -= cellWidth/4;
		}

		vertices.add(new vec2(px, 		py+yRad));
		vertices.add(new vec2(px+xRad, py+yRad*0.5f));
		vertices.add(new vec2(px+xRad, py-yRad*0.5f));
		vertices.add(new vec2(px, 		py-yRad));
		vertices.add(new vec2(px-xRad, py-yRad*0.5f));
		vertices.add(new vec2(px-xRad, py+yRad*0.5f));
	}

	public List<vec2> getNeighborCoords() {
		List<vec2> v = new LinkedList<vec2>();
		for (Direction d : offsets.keySet()) {
			v.add(offsets.get(d));
		}
		return v;
	}

	public boolean hasDirection(Direction d) {
		return directions.contains(d);
	}

	void draw() {
		// start at center

		// draw the cell borders clockwise from the top
		// https://stackoverflow.com/questions/33967062/how-to-render-a-hex-grid
		// TODO: only draw necessary vertices
		// just draw NW, NE, E (0-2) unless at the left side and below
		// or at the right side and above
		// or at the bottom
		for (int i=0; i<vertices.size()-1; i++) {
			doLine(vertices.get(i), vertices.get(i+1), pointsPerLine);
		}
		doLine(vertices.get(5), vertices.get(0), pointsPerLine);
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
	// continuously perturb lines along perturbation axis
	line(rawStart.x, rawStart.y, rawEnd.x, rawEnd.y);
	// vec2 start = rawStart;//.perturb();
	// vec2 end = rawEnd;//.perturb();

	// do a multi-point line
	// SVGs will export duplicate shapes, 1 stroke and 1 fill
	// even if one of those isn't set
	// which means the AxiDraw makes 2 passes on shapes (bad)
	beginShape();
	vec2 prev = null;
	for (float i=0; i<=p; i++) {
		vec2 v = rawStart.selfLerp(rawEnd, i/p);//.perturb();
		vertex(v.x, v.y);
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

void initControls() {
	cp5 = new ControlP5(this);
	cp5
		.addSlider("perlinXA")
		.setLabel("perlinAmp")
		.setRange(0, 100)
		.setValue(100)
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
		.setValue(66)
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
	background(255);

	initDicts();
	initRows();

	random = new Random();

	// choose the initial cell, mark as visited and push to the stack
	int x = random.nextInt(0, cells);
	int y = random.nextInt(0, cells);
	HexCell startHexCell = rows.get(x).get(y);
	startHexCell.visited = true;
	cellStack.push(startHexCell);

	// turn this off for svg exporting
	pixelDensity(displayDensity());
}

void draw() {
	background(255);

	if (exportSVG) {
    	beginRecord(SVG, "exports/export_"+timestamp()+".svg");
  	}

	// while the stack isn't empty:
	if (!cellStack.empty() && false) {
		// pop a current cell
		HexCell current = cellStack.pop();
		// choose one of the unvisited neighbors
		// remove a wall between the current cell and the chosen cell
		ArrayList<HexCell> neighbors = new ArrayList<HexCell>();
		int cx = current.x;
		int cy = current.y;

		// TODO: refactor this algorithm for hex grids
		// need to prune neighbor coordinates too
		// for (Integer direction : D) {
		// 	// get coordinates of the current neighbor
		// 	int nx = cx + DX.get(direction);
		// 	int ny = cy + DY.get(direction);

		// 	// if that neighbor is in the grid
		// 	if (nx>=0 && nx<cells && ny>=0 && ny<cells) {
		// 		// add that neighbor to the list of neighbors
		// 		HexCell neighborHexCell = rows.get(nx).get(ny);
		// 		if (!neighborHexCell.visited) {
		// 			neighbors.add(neighborHexCell);
		// 		}
		// 	}
		// }

		// if there are unvisited neighbors
		if (neighbors.size() > 0) {
			// // push current cell to the stack
			// cellStack.push(current);

			// // pick a random unvisited neighbor
			// HexCell chosenNeighbor = neighbors.get(random.nextInt(0, neighbors.size()));
			// // remove walls between it and the current cell
			// int dx = chosenNeighbor.x - current.x;
			// int dy = chosenNeighbor.y - current.y;
			// if (dx != 0) {
			// 	current.direction = current.direction | XD.get(dx);
			// 	chosenNeighbor.direction = chosenNeighbor.direction | XD.get(-dx);
			// }
			// if (dy != 0) {
			// 	current.direction = current.direction | YD.get(dy);
			// 	chosenNeighbor.direction = chosenNeighbor.direction | YD.get(-dy);
			// }
			// // mark the chosen cell as visited and push it to the stack
			// chosenNeighbor.visited = true;
			// cellStack.push(chosenNeighbor);
		}
	}

	drawMaze();

	if (exportSVG) {
		exportSVG = false;
		endRecord();
		cp5.setAutoDraw(true);
		System.out.println("exported SVG");
	}
}

void drawMaze() {
	push();
		translate((canvasSize-mazeWidth)/2f, (canvasSize-mazeHeight)/2f);
		// and then start in the middle of the top left cell
		translate(cellWidth/2f, cellHeight/2f);
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
	}
}

String timestamp() {
  Calendar now = Calendar.getInstance();
  return String.format("%1$ty%1$tm%1$td_%1$tH%1$tM%1$tS", now);
}
