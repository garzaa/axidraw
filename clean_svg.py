"""
processing exports SVGs twice, one with a stroke and no fill and vice versa
no idea why, but it makes the AxiDraw make 2 passes
we just want strokes, fills don't matter
"""
from bs4 import BeautifulSoup
import argparse
import os

parser = argparse.ArgumentParser()
parser.add_argument("-f",  "--input_file",  help="input SVG to clean up")
parser.add_argument("-d",  "--input_directory",  help="clean everything in this directory")
args = parser.parse_args()

def strip_nonstrokes(text: str) -> None:
	soup = BeautifulSoup(text, "xml")
	for tag in soup.find_all(True):
		style = tag.get("style")
		if style is not None and "stroke:none" in style:
			tag.decompose()
	return soup.prettify()

def clean_file(filename: str) -> None:
	with open(filename, 'r+') as f:
		text = strip_nonstrokes(f.read())
		f.seek(0)
		f.write(text)
		f.truncate()
	print("cleaned up "+filename)

if args.input_file:
	clean_file(args.input_file)

if args.input_directory:
	target_dir = os.path.join(os.getcwd(), args.input_directory)
	for filename in os.listdir(target_dir):
		if filename.endswith(".svg"):
			clean_file(os.path.join(target_dir, filename))

