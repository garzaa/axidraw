// https://weblog.jamisbuck.org/2010/12/27/maze-generation-recursive-backtracking

var canvasSize = 800;

var bg = 200;
var fg = 50;

var cellSize = 6;
var lineWeight = 3;
var xSize = 360;
var ySize = 360;
var xCount = xSize/cellSize;
var yCount = ySize/cellSize;
var ts = 12;
var xMargin = (canvasSize-xSize)/2;
var yMargin = (canvasSize-ySize)/2;

var N = 1;
var S = 2;
var E = 4;
var W = 8;

var D = {
    N: N,
    S: S,
    E: E,
    W: W
}

var DX = {
    E: 1,
    W: -1,
    S: 0,
    N: 0
}

// p5 js starts at the top left
// more y = going lower
var DY = {
    E: 0,
    W: 0,
    N: -1,
    S: 1
}

var OPPOSITE = {
    E: W,
    W: E,
    N: S,
    S: N
}

var rows = []
rangeIter(yCount, x=>rows.push(new Array(xCount).fill(0)))

function carvePassages(cx, cy, rows) {
    var directions = shuffle(["N", "S", "E", "W"]);

    directions.forEach(function(direction) {
        var nx = cx + DX[direction];
        var ny = cy + DY[direction];

        if ((ny>=0) && (ny<yCount) && (nx>=0) && (nx<xCount) && !rows[ny][nx]) {
            rows[cy][cx] = rows[cy][cx] | D[direction];
            rows[ny][nx] = rows[ny][nx] | OPPOSITE[direction];
            carvePassages(nx, ny, rows);
        }
    });
}

function makeRows(rows) {
    carvePassages(0, 0, rows);
}

function setup() {
    createCanvas(canvasSize, canvasSize);
    noLoop();
    strokeCap(PROJECT)
    strokeWeight(lineWeight);
    noFill();
    background(bg);
    stroke(fg);
    makeRows(rows);
    textSize(ts);
}


function drawCell(cell, i, j) {
    push();
        translate(j*cellSize, i*cellSize);

        if ((j == xCount-1) || !(cell & E))    rightLine();
        if ((j == 0))                             leftLine();
        if (((i == yCount-1) || !(cell & S)))  bottomLine();
        if ((i == 0))                             topLine();
    pop();
}

function leftLine() {
    line(0, cellSize, 0, 0);
}

function rightLine() {
    line(cellSize, 0, cellSize, cellSize);
}

function bottomLine() {
    line(cellSize, cellSize, 0, cellSize);
}

function topLine() {
    line(0, 0, cellSize, 0);
}

function draw() {
    background(bg);
    push();
    translate(xMargin, yMargin);
    for (var i=0; i<rows.length; i++) {
        for (var j=0; j<rows[i].length; j++) {
            drawCell(rows[i][j], i, j);
        }
    }
    pop();
}
