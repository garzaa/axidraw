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
}

public class HexCell {
	Set<Direction> connections = new HashSet<Direction>();
	float x, y;
	float px, py;

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
		// ellipse(px, py, cellWidth, cellWidth);
		drawArc(0);
	}

	void drawArc(int segmentNum) {
		// 6 segments, clockwise from 12 oclock
		// arcs always want clockwise
		float a = (segmentNum * (TWO_PI/6f)) - (PI/2F);
		float b = ((segmentNum + 1) * (TWO_PI/6f)) - (PI/2F);
		arc(px, py, cellWidth, cellWidth, a, b);
	}
}

public class HexGrid {
	List<List<HexCell>> rows;
	
	public HexGrid(int xSize, int ySize) {
		rows = new ArrayList<List<HexCell>>(xSize);
		for (int x=0; x<xSize; x++) {
			List<HexCell> row = new ArrayList<HexCell>(ySize);
			for (int y=0; y<ySize; y++) {
				row.add(new HexCell(x, y));
			}
			rows.add(row);
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
}

void setup() {
	size(800, 800);
	grid = new HexGrid(cells, cells);
	noFill();
}

void draw() {
	background(bg);
	stroke(strokeColor);
	stroke(2);
	grid.draw();
}
