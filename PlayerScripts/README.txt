How to use the Merge Tool:

INSTALL
On Windows:
	Download Python 2.7 from the Python website
	Then install lxml from this site:
		http://www.lfd.uci.edu/~gohlke/pythonlibs/#lxml
	Make sure to pick the package that matches your installation of python 2.7 (x86/x64)

On Mac:
	Download Python 2.7 from the python website
	Then install lxml from cmd line:
		the following CFLAGS is a work-around for a clang error in OSX mavericks (10.9)
		sudo CFLAGS="-O0"  pip install lxml (if you don't have pip: sudo easy_install pip)

RUN
From the command line type merger.py
	This will create output files for all the base rbxlxs in the folder.
	It will put the entirety of the components from the all folder into the output file.
	It will also put in components from one additional folder that matches the name of the base file.

