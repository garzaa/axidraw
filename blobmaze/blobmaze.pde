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

public enum Direction {
	NW, NE,
	W, E,
	SW, SE
}

Map<Direction, vec2> offsets = new HashMap<Direction, vec2>();
// every odd row has their NW/NE and SW/SE neighbors shifted left by 1
Map<Direction, vec2> oddOffsets = new HashMap<Direction, vec2>();
Map<Direction, Direction> opposites = new HashMap<Direction, Direction>();

Set<Direction> directions;

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
}

public class HexCell {
	Set<Direction> connections = new HashSet<Direction>();
	Set<Direction> neighborDirections = new HashSet<Direction>();
	float x, y;
	float px, py;

	boolean filled = false;

	HexGrid grid;

	Map<Direction, vec2> dirMap;

	public HexCell(int x, int y, HexGrid grid) {
		this.x = x;
		this.y = y;

		this.px = x*cellWidth;
		this.py = y*cellHeight * 0.75f;

		this.grid = grid;

		// then move left/right based on the index order
		// put this at the end so it only gets caught by the render loop
		// ideally should put it in the render loop, but whatever
		// just don't reference px and py after this block
		if (isOdd()) {
			px -= cellWidth/4;
		} else {
			px += cellWidth/4;
		}

		dirMap = isOdd() ? oddOffsets : offsets;

		// then fill based on the offset
		int rowOffset = isOdd() ? 0 : -1;
		filled = (x + rowOffset)  % 3 == 0;


		addNeighborDirections();
	}

	public void connect(Direction d) {
		connections.add(d);
	}

	public boolean hasConnection(Direction d) {
		return connections.contains(d);
	}

	boolean isOdd() {
		return y%2 == 1;
	}

	public void draw() {
		ellipse(px, py, cellWidth, cellWidth);
		if (filled) {
			ellipse(px, py, cellWidth/2f, cellWidth/2f);
		}
		// drawArc(0);
	}

	void drawArc(int segmentNum) {
		// 6 segments, clockwise from 12 oclock
		// arcs always want clockwise
		float a = (segmentNum * (TWO_PI/6f)) - (PI/2F);
		float b = ((segmentNum + 1) * (TWO_PI/6f)) - (PI/2F);
		arc(px, py, cellWidth, cellWidth, a, b);
	}

	public void addNeighborDirections() {

	}

	public boolean hasNeighborDirection(Direction d) {
		return neighborDirections.contains(d);
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
		return x > 0 && x < cells && y > 0 && y < cells;
	}

	public boolean inBounds(vec2 v) {
		return inBounds((int) v.x, (int) v.y);
	}
}

void setup() {
	size(800, 800);
	noFill();
	initDicts();

	grid = new HexGrid(cells, cells);
}

void draw() {
	background(bg);
	stroke(strokeColor);
	stroke(2);
	grid.draw();
}
