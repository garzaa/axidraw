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

Hashtable D = new Hashtable();
Hashtable DY = new Hashtable();
Hashtable DX = new Hashtable();
Hashtable Opposite = new Hashtable();

// store each cell as a bit-masked integer
ArrayList<ArrayList<Integer>> rows = new ArrayList<ArrayList<Integer>>();

Random random;

void initDicts() {
	D.put(N, N);
	D.put(S, S);
	D.put(E, E);
	D.put(W, W);

	// (0, 0) is at the top left
	DY.put(E, 0);
	DY.put(W, 0);
	DY.put(N, -1);
	DY.put(S, 1);

	DX.put(E, 1);
	DX.put(W, -1);
	DX.put(N, 0);
	DX.put(S, 0);

	Opposite.put(N, S);
	Opposite.put(S, N);
	Opposite.put(E, W);
	Opposite.put(W, E);
}

void initRows() {
	for (int x=0; x<cells; x++) {
		rows.add(new ArrayList<Integer>());
		for (int y=0; y<cells; y++) {
			rows.get(x).add(0);
		}
	}
}

void setup() {
	size(800, 800);
	noFill();

	initDicts();
	initRows();

	random = new Random();

	System.out.println(random.nextInt(0, 10));

	// choose the initial cell, mark as visited and push to the stack
	// while the stack isn't empty:
	// pop a current cell
	// choose one of the unvisited neighbors
	// remove a wall between the current cell and the chosen cell
	// mark the chosen cell as visited and push it to the stack
}

void draw() {

}
