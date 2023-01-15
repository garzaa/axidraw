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
    System.out.println("exported SVG");
  }
}

void drawMaze() {
	push();
		translate(margin, margin);
		for (int i=0; i<rows.size(); i++) {
			for (int j=0; j<rows.get(i).size(); j++) {
				drawCell(rows.get(i).get(j));
			}
		}
	pop();
}

// non-corner cells should just draw their
// bottom right neighbors to avoid overlapping wall lines
void drawCell(Cell cell) {
	push();
		// start at top right corner
		translate(
			cell.x*cellSize - cellSize/2,
			cell.y*cellSize - cellSize/2
		);

		if ((cell.x == cells-1) || ((cell.direction&E) == 0)) rightLine();
		if (cell.x == 0) leftLine();
		if ((cell.y == cells-1) || ((cell.direction&S) == 0)) bottomLine();
		if (cell.y == 0) topLine();
	pop();
}

void leftLine() {
    line(0, cellSize, 0, 0);
}

void rightLine() {
    line(cellSize, 0, cellSize, cellSize);
}

void bottomLine() {
    line(cellSize, cellSize, 0, cellSize);
}

void topLine() {
    line(0, 0, cellSize, 0);
}

void keyPressed() {
	if (key == 'e') {
		System.out.println("exporting SVG");
		exportSVG = true;
	}
}

String timestamp() {
  Calendar now = Calendar.getInstance();
  return String.format("%1$ty%1$tm%1$td_%1$tH%1$tM%1$tS", now);
}
