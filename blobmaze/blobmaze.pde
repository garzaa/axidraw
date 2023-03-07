import java.util.*;
import processing.svg.*;
import controlP5.*;

ControlP5 cp5;
boolean exportSVG = false;

int canvasSize = 800;

// maze params
int cellHeight = 40;
int cells = 10;
int bg = 200;
int strokeColor = 50;

// plumbing
float cellWidth = (float) (Math.sqrt(3)/2f) * cellHeight;
float yRad = cellHeight/2f;
float xRad = cellWidth/2f;

// cells overlap vertically
float mazeWidth = cells * cellWidth;
float mazeHeight = cells * cellHeight * 0.75f;

float marginX = (canvasSize - mazeWidth)/2f;
float marginY = (canvasSize - mazeHeight)/2f;

HexGrid grid;
Random random;

// these are stored at corners now, not faces
public enum Direction {
	N,
  NW, NE,
  SW, SE,
	S
}

Map<Direction, vec2> offsets = new HashMap<Direction, vec2>();
// every odd row has their NW/NE and SW/SE neighbors shifted left by 1
Map<Direction, vec2> oddOffsets = new HashMap<Direction, vec2>();
Map<Direction, Direction> opposites = new HashMap<Direction, Direction>();

Set<Direction> directions;

Map<Direction, Integer> directionArcs = new HashMap<Direction, Integer>();

void initDicts() {
	offsets.put(Direction.N,  new vec2( 0, -2));
	offsets.put(Direction.NW, new vec2(-1, -1));
	offsets.put(Direction.NE, new vec2( 2, -1));
	offsets.put(Direction.SW, new vec2(-1,  1));
	offsets.put(Direction.SE, new vec2( 2,  1));
	offsets.put(Direction.S,  new vec2( 0,  2));

	opposites.put(Direction.N,  Direction.S );
	opposites.put(Direction.NW, Direction.SE);
	opposites.put(Direction.NE, Direction.SW);
	opposites.put(Direction.SW, Direction.NE);
	opposites.put(Direction.SE, Direction.NW);
	opposites.put(Direction.S,  Direction.N );

	oddOffsets.put(Direction.N,  new vec2( 0, -2));
	oddOffsets.put(Direction.NW, new vec2(-2, -1));
	oddOffsets.put(Direction.NE, new vec2( 1, -1));
	oddOffsets.put(Direction.SW, new vec2(-2,  1));
	oddOffsets.put(Direction.SE, new vec2( 1,  1));
	oddOffsets.put(Direction.S,  new vec2( 0,  2));

	directionArcs.put(Direction.N,  0);
	directionArcs.put(Direction.NE, 1);
	directionArcs.put(Direction.SE, 2);
	directionArcs.put(Direction.S,  3);
	directionArcs.put(Direction.SW, 4);
	directionArcs.put(Direction.NW, 5);

	directions = offsets.keySet();
}


public class vec2 {
	float x;
	float y;

	public vec2(float x, float y) {
		this.x = x;
		this.y = y;
	}

	// no pass by value houghough
	public vec2 add(vec2 b) {
		return new vec2(this.x + b.x, this.y + b.y);
	}

	public vec2 scale(float s) {
		return new vec2(this.x * s, this.y * s);
	}

	public String toString() {
		return "("+x+", "+y+")";
	}
}

public HexCell tempCell(float x, float y) {
	return new HexCell((int) x, (int) y, null);
}

public class HexCell {
	Map<Direction, HexCell> connections = new HashMap<Direction, HexCell>();
	Map<HexCell, Direction> neighbors = new HashMap<HexCell, Direction>();
	public float x, y;
	public float px, py;

	boolean filled = false;
	public boolean visited = false;

	HexGrid grid;

	Map<Direction, vec2> dirMap;

	public HexCell(int x, int y, HexGrid grid) {
		this.grid = grid;
		
		this.x = x;
		this.y = y;

		this.px = x*cellWidth;
		this.py = y*cellHeight * 0.75f;


		if (isOdd()) {
			px -= cellWidth/4;
		} else {
			px += cellWidth/4;
		}

		dirMap = isOdd() ? oddOffsets : offsets;

		int rowOffset = isOdd() ? 0 : -1;
		filled = ((x + rowOffset) % 3) == 0;
	}

	public void connect(Direction d, HexCell c) {
		connections.put(d, c);
	}

	boolean isOdd() {
		return y%2 == 1;
	}

	public void draw() {
		if (filled) {
			// connecting lines to neighbors
			for (HexCell c : connections.values()) {
				vec2 v = c.worldPos();
				// line(px, py, v.x, v.y);
			}

			for (Direction d : directions) {
				if (!connections.containsKey(d)) {
					// first, draw closed segments
					drawArc(directionArcs.get(d));
				} else {
					// now the hard part...draw additional cells' arcs
					HexCell n = connections.get(d);

					// x offsets are gonna be FUN with alternating rows
					int xm = isOdd() ? 1 : 0;
					int nm = isOdd() ? 0 : -1;

					// ONLY NEED TO DO THREE OF THESE THANK CHRIST
					if (d == Direction.SW) {
						// SE, we want 1 left of self (this can be outside boundaries)
						tempCell(x-1, y).drawArc(Direction.SE, Direction.S);
						// and 1 right of the connection
						tempCell(n.x+1, n.y).drawArc(Direction.NW, Direction.N);
					} else if (d == Direction.S) {
						// s, one below self
						tempCell(x - xm, y+1).drawArc(Direction.NE, Direction.SE);
						// and one above target
						tempCell(n.x - nm, n.y-1).drawArc(Direction.NW, Direction.SW);
					} else if (d == Direction.SE) {
						// se, one right of self draws bottom and bottom left
						tempCell(x+1, y).drawArc(Direction.S, Direction.SW);
						// and one left of target? draws top, top right
						tempCell(n.x-1, n.y).drawArc(Direction.N, Direction.NE);
					}
				}

			}
		} else {
			// stroke(150);
			// ellipse(px, py, cellWidth*0.8f, cellWidth*0.8f);
			// line(px+2, py+2, px-2, py-2);
			// line(px-2, py+2, px+2, py-2);
			// stroke(strokeColor);
		}
	}

	public void drawArc(Direction d1, Direction d2) {
		drawArc(directionArcs.get(d1));
		drawArc(directionArcs.get(d2));
	}

	public void drawArc(Direction d) {
		drawArc(directionArcs.get(d));
	}

	public void drawArc(int segmentNum) {
		// 6 segments, clockwise from 12 oclock
		// arcs always want clockwise
		float a = (segmentNum * (TWO_PI/6f)) - (PI/2F) - (PI/6f);
		float b = ((segmentNum + 1) * (TWO_PI/6f)) - (PI/2F) - (PI/6f);
		float rad = filled ? cellWidth * 1.2f : cellWidth * 0.8f;
		arc(px, py, rad, rad, a, b);
	}

	public void addNeighbors() {
		// for each direction
		for (Direction d : directions) {
			// if the cell in that direction is in bounds
			vec2 cellCoords = gridPos().add(dirMap.get(d));
			if (grid.inBounds(cellCoords)) {
				// then get the cell at that position
				// and add it to neighbors
				neighbors.put(grid.get(cellCoords), d);
			}
		}
	}

	public List<HexCell> getUnvisitedNeighbors() {
		List<HexCell> n = new LinkedList<HexCell>();
		for (HexCell c : neighbors.keySet()) {
			if (!c.visited) n.add(c);
		}
		return n;
	}

	public vec2 worldPos() {
		return new vec2(px, py);
	}

	public vec2 gridPos() {
		return new vec2(x, y);
	}

	public boolean isFilled() {
		return filled;
	}

	public Direction getNeighborDirection(HexCell c) {
		return neighbors.get(c);
	}
}

public class HexGrid {
	List<List<HexCell>> rows;
	
	public HexGrid(int xSize, int ySize) {
		rows = new ArrayList<List<HexCell>>(xSize);

		// first pass: initialize cells
		for (int x=0; x<xSize; x++) {
			List<HexCell> row = new ArrayList<HexCell>(ySize);
			for (int y=0; y<ySize; y++) {
				row.add(new HexCell(x, y, this));
			}
			rows.add(row);
		}

		// second pass: connect them in a checkerboard
		for (int x=0; x<xSize; x++) {
			for (int y=0; y<ySize; y++) {
				HexCell cell = get(x, y);
				if (cell.isFilled()) {
					cell.addNeighbors();
				}
			}
		}
	}

	public void draw() {
		push();
			translate(marginX, marginY);
			for (List<HexCell> row : rows) {
				for (HexCell cell : row) {
					cell.draw();
				}
			}
		pop();
	}

	public HexCell get(int x, int y) {
		return rows.get(x).get(y);
	}

	public HexCell get(vec2 v) {
		return get((int) v.x, (int) v.y);
	}

	public boolean inBounds(int x, int y) {
		return x >= 0 && x < cells && y >= 0 && y < cells;
	}

	public boolean inBounds(vec2 v) {
		boolean b =  inBounds((int) v.x, (int) v.y);
		return b;
	}

	public HexCell randomFilledCell() {
		List<HexCell> cells = new LinkedList<HexCell>();
		for (List<HexCell> row : rows) {
			for (HexCell cell : row) {
				if (cell.isFilled()) {
					cells.add(cell);
				}
			}
		}

		return cells.get(random.nextInt(cells.size()));
	}
}

void carve() {
	Stack<HexCell> cellStack = new Stack<HexCell>();

	// THIS NEEDS TO BE A FILLED CELL
	HexCell startCell = grid.randomFilledCell();

	startCell.visited = true;
	cellStack.push(startCell);

	// while the cell stack isn't empty
	while (!cellStack.empty()) {
		// pop a cell, make it current
		HexCell current = cellStack.pop();
		
		// choose an unvisited neighbor, then connect them
		List<HexCell> neighbors = current.getUnvisitedNeighbors();
		// if there's a valid neighbor
		if (!neighbors.isEmpty()) {
			HexCell targetNeighbor = neighbors.get(random.nextInt(neighbors.size()));
			// push the current cell to the stack
			cellStack.push(current);

			// connect the two
			Direction direction = current.getNeighborDirection(targetNeighbor);
			current.connect(direction, targetNeighbor);
			targetNeighbor.connect(opposites.get(direction), current);

			// mark the chosen cell as visited and push it to the stack
			targetNeighbor.visited = true;
			cellStack.push(targetNeighbor);
		}

	}
}

void setup() {
	random = new Random();
	size(800, 800);
	noFill();
	initDicts();

	grid = new HexGrid(cells, cells);

	// turn off for svg exports
	pixelDensity(displayDensity());

	carve();

	noLoop();
}

void draw() {
	background(bg);
	stroke(strokeColor);

	if (exportSVG) {
    	beginRecord(SVG, "exports/export_"+timestamp()+".svg");
  	}

	grid.draw();

	if (exportSVG) {
		exportSVG = false;
		endRecord();
		// cp5.setAutoDraw(true);
		System.out.println("exported SVG");
	}
}

void keyPressed() {
	if (key == 'e') {
		System.out.println("exporting SVG");
		// cp5.setAutoDraw(false);
		exportSVG = true;
	} else if (key == 'q') {
		exit();
	}
}

String timestamp() {
	Calendar now = Calendar.getInstance();
	return String.format("%1$ty%1$tm%1$td_%1$tH%1$tM%1$tS", now);
}

