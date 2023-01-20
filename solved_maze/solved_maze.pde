import java.util.*;
import processing.svg.*;
import controlP5.*;

ControlP5 cp5;
boolean exportSVG = false;

// 8x6 in
int w = 768;
int h = 576;

int cellSize = 3;
int mazeSize = 300;

int cells = mazeSize/cellSize;
int marginX = (w-mazeSize)/2;
int marginY = (h-mazeSize)/2;
int pointsPerLine = cellSize;

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

List<Cell> solutionPath = null;

public class Cell {
	public int direction = 0;
	public int x = 0;
	public int y = 0;
	public boolean visited = false;

	public Cell(int x, int y) {
		this.x = x;
		this.y = y;
	}

	public String toString() {
		return "("+x+","+y+")";
	}

	void draw() {
		// start at top left corner
		float px = x*cellSize - cellSize/2;
		float py = y*cellSize - cellSize/2;

		vec2 tl = new vec2(px, py);
		vec2 bl = new vec2(px, py+cellSize);
		vec2 tr = new vec2(px+cellSize, py);
		vec2 br = new vec2(px+cellSize, py+cellSize);

		if ((x == cells-1) || ((direction&E) == 0)) doLine(tr, br, pointsPerLine);
		if (x == 0) doLine(tl, bl, pointsPerLine);
		if ((y == cells-1) || ((direction&S) == 0)) doLine(bl, br, pointsPerLine);
		if (y == 0) doLine(tl, tr, pointsPerLine);
	}

	public List<Cell> getNeighbors() {
		LinkedList<Cell> n = new LinkedList<Cell>();
		// y increases as it goes down REMEMEBR
		if ((direction&N) > 0) n.add(rows.get(x).get(y-1));
		if ((direction&S) > 0) n.add(rows.get(x).get(y+1));
		if ((direction&E) > 0) n.add(rows.get(x+1).get(y));
		if ((direction&W) > 0) n.add(rows.get(x-1).get(y));
		return n;
	}
}

// these should be unperturbed, and then be perturbed along the line
void doLine(vec2 rawStart, vec2 rawEnd, int p) {
		// continuously perturb lines along perturbation axis
		vec2 start = rawStart.perturb();
		vec2 end = rawEnd.perturb();

		// do multiple segments if the distance is greater than cellsize
		if (start.xydist(end) <= cellSize) {
			line(
				start.x, start.y,
				end.x, end.y
			);
		} else {
			// do a multi-point line
			// SVGs will export duplicate shapes, 1 stroke and 1 fill
			// even if one of those isn't set
			// which means the AxiDraw makes 2 passes on shapes (bad)
			if (exportSVG) {
				vec2 prev = null;
				for (float i=0; i<=p; i++) {
					vec2 v = rawStart.selfLerp(rawEnd, i/p).perturb();
					if (prev != null) {
						line(prev.x, prev.y, v.x, v.y);
					}
					prev = v;
				}
			} else {
				beginShape();
				vec2 prev = null;
				for (float i=0; i<=p; i++) {
					vec2 v = rawStart.selfLerp(rawEnd, i/p).perturb();
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
		float cx = noise((x + perlinXO)/perlinXD, (y + perlinXO)/perlinXD, 0);
		float cy = noise((x + perlinYO)/perlinYD, (y + perlinYO)/perlinYD, 1000);
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
}

// store each cell as a bit-masked integer
ArrayList<ArrayList<Cell>> rows = new ArrayList<ArrayList<Cell>>(cells);

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
	rows.clear();
	for (int x=0; x<cells; x++) {
		rows.add(new ArrayList<Cell>(cells));
		for (int y=0; y<cells; y++) {
			rows.get(x).add(new Cell(x, y));
		}
	}
}

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

	cp5
		.addButton("redraw")
		.setLabel("redraw")
		;
}

void redraw() {
	System.out.println("reset button pressed");
	setup();
}

void settings() {
	size(w, h);
}

void setup() {
	noFill();
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

	// while the stack isn't empty:
	while (!cellStack.empty()) {
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

	solutionPath = solveMaze();
}

class CellComparator implements Comparator<Cell> {
	Cell start;

	public CellComparator(Cell start) {
		this.start = start;
	}

	public int compare(Cell a, Cell b) {
		int da = h(start, a);
		int db = h(start, b);
		if (da < db) return 1;
		else if (da > db) return -1;
		else return 0;
	}
}

int h(Cell a, Cell b) {
	//cheaper manhattan distance since it's a grid
	return (b.x-a.x) + (b.y-a.y);
}

List<Cell> reconstructPath(HashMap<Cell, Cell> cameFrom, Cell current) {
	LinkedList<Cell> total_path = new LinkedList<Cell>();
	total_path.add(current);
	while (cameFrom.containsKey(current)) {
		// cameFrom doesn't have current
		current = cameFrom.get(current);
		total_path.addFirst(current);
	}
	return total_path;
}

List<Cell> aStar(Cell start, Cell goal) {
	// set of discovered Cells
	// priority queue for logN lookup later
	PriorityQueue<Cell> openSet = new PriorityQueue<Cell>(new CellComparator(start));
	openSet.add(start);

	// camefrom[n] is the immediately preceding Cell
	HashMap<Cell, Cell> cameFrom = new HashMap<Cell, Cell>();

	// gScore[n] is the Cell's heuristic score
	HashMap<Cell, Integer> gScore = new HashMap<Cell, Integer>();
	gScore.put(start, 0);

	// estimated cost of route through fscore[n]
	HashMap<Cell, Integer> fScore = new HashMap<Cell, Integer>();
	fScore.put(start, h(start, start));

	while (!openSet.isEmpty()) {
		// pqueues are sorted ascending
		Cell current = openSet.peek();
		if (current == goal) {
			// start is 0, 0, cameFrom is valid, yes
			return reconstructPath(cameFrom, current);
		}

		openSet.remove(current);
		// for each neighbor of current
		for (Cell neighbor : current.getNeighbors()) {
			// 1 is the weight of the path to the neighbor
            // tentative_gScore is the distance from start to the neighbor through current
			int tentative_gScore = gScore.get(current) + 1;
			if (!gScore.containsKey(neighbor) || tentative_gScore < gScore.get(neighbor)) {
				// This path to neighbor is better than any previous one. Record it!
				cameFrom.put(neighbor, current);
				gScore.put(neighbor, tentative_gScore);
				fScore.put(neighbor, tentative_gScore + h(start, neighbor));
				if (!openSet.contains(neighbor)) openSet.add(neighbor);
			}
		}
	}

	return null;
}

List<Cell> solveMaze() {
	System.out.println("solving maze with A*");
	List<Cell> path = aStar(
		rows.get(0).get(0),
		rows.get(cells-1).get(cells-1)
	);
	System.out.println("maze solved!");
	return path;
}

void draw() {
	background(255);
	String ts = timestamp();
	if (exportSVG) {
    	beginRecord(SVG, "export_"+ts+".svg");
  	}

	drawMaze();

	if (exportSVG) {
		endRecord();
		System.out.println("exported maze SVG");
	}

	if (exportSVG) {
    	beginRecord(SVG, "export_"+ts+"_SOLUTION.svg");
  	}

	drawSolution();

	if (exportSVG) {
		exportSVG = false;
		endRecord();
		cp5.setAutoDraw(true);
		System.out.println("exported solution SVG");
		println("done");
	}
}

void drawMaze() {
	push();
		translate(marginX, marginY);
		for (int i=0; i<rows.size(); i++) {
			for (int j=0; j<rows.get(i).size(); j++) {
				rows.get(i).get(j).draw();
			}
		}
	pop();
}

void drawSolution() {
	push();
		translate(marginX, marginY);
		stroke(0xffff0000);
		beginShape();
		for (Cell pathNode : solutionPath) {
			vec2 v = new vec2(pathNode.x * cellSize, pathNode.y * cellSize);
			v = v.perturb();
			vertex(v.x, v.y);
		}
		endShape(OPEN);
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
