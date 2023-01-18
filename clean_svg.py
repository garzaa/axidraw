# remove non-stroked SVG paths
# so axidraw doesn't make double passes
"""
processing exports SVGs twice, one with a stroke and no fill and vice versa
no idea why, but it makes the AxiDraw make 2 passes
we just want strokes, fills don't matter
"""
from bs4 import BeautifulSoup
import io
import argparse

parser = argparse.ArgumentParser()
parser.add_argument("-f",  "--input_file",  help="input SVG to clean up")
args = parser.parse_args()

def strip_nonstrokes(text: str) -> None:
	soup = BeautifulSoup(text, "xml")
	for tag in soup.find_all(True):
		style = tag.get("style")
		if style is not None and "stroke:none" in style:
			tag.decompose()
	return soup.prettify()


with open(args.input_file, 'r+') as f:
	text = strip_nonstrokes(f.read())
	f.seek(0)
	f.write(text)
	f.truncate()

