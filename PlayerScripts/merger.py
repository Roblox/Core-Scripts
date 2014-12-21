#! /usr/bin/python
## Kip Turner 2014

VERSION = "1.1.0"

import os, getopt
import fnmatch
import sys
import subprocess
import re
import uuid

# if os.name == 'nt':
# 	import ctypes
# 	dll_name = "libxml2.dll"
# 	#dllabspath = os.path.dirname(os.path.join(os.path.abspath(__file__), "bin/")) + os.path.sep + dll_name
# 	dllabspath = os.path.dirname(os.path.join(os.getcwd(), "bin/")) + os.path.sep + "zlib1.dll"
# 	myDll = ctypes.CDLL(dllabspath)
# 	dllabspath = os.path.dirname(os.path.join(os.getcwd(), "bin/")) + os.path.sep + "iconv.dll"
# 	myDll = ctypes.CDLL(dllabspath)
# 	dllabspath = os.path.dirname(os.path.join(os.getcwd(), "bin/")) + os.path.sep + dll_name
# 	print(dllabspath)
# 	myDll = ctypes.CDLL(dllabspath)


from lxml import etree
from xml.dom.minidom import parse, parseString

if os.name == 'nt':
	import _winreg

from shutil import *

def copytree(src, dst, symlinks=False, ignore=None):
    names = os.listdir(src)
    if ignore is not None:
        ignored_names = ignore(src, names)
    else:
        ignored_names = set()

    if not os.path.isdir(dst): # This one line does the trick
        os.makedirs(dst)
    errors = []
    for name in names:
        if name in ignored_names:
            continue
        srcname = os.path.join(src, name)
        dstname = os.path.join(dst, name)
        try:
            if symlinks and os.path.islink(srcname):
                linkto = os.readlink(srcname)
                os.symlink(linkto, dstname)
            elif os.path.isdir(srcname):
                copytree(srcname, dstname, symlinks, ignore)
            else:
                # Will raise a SpecialFileError for unsupported file types
                copy2(srcname, dstname)
        # catch the Error from the recursive copytree so that we can
        # continue with other files
        except Error, err:
            errors.extend(err.args[0])
        except EnvironmentError, why:
            errors.append((srcname, dstname, str(why)))
    try:
        copystat(src, dst)
    except OSError, why:
        if WindowsError is not None and isinstance(why, WindowsError):
            # Copying file access times may fail on Windows
            pass
        else:
            errors.extend((src, dst, str(why)))
    if errors:
        raise Error, errors

def findContentFolder():
	if os.name == 'posix':  # OSX
		OSX_ContentPath = r"/Applications/RobloxStudio.app/Contents/Resources/content"
		if os.path.isdir(OSX_ContentPath):
			return OSX_ContentPath
	elif os.name == 'nt': # WIN
		try:
			root_key = _winreg.OpenKey(_winreg.HKEY_CURRENT_USER, r"Software\Roblox\RobloxStudio", 0, _winreg.KEY_READ)
			[Pathname,regtype]=(_winreg.QueryValueEx(root_key, r"ContentFolder"))
			_winreg.CloseKey(root_key)
			if (""==Pathname):
				raise WindowsError
			if os.path.isdir(Pathname):
				return Pathname
		except WindowsError:
			pass
	return None

def findRbxlxInDir(dir):
	matchedFiles = []
	for file in os.listdir(dir):
		if fnmatch.fnmatch(file, '*.rbxlx') and not fnmatch.fnmatch(file, "*output.rbxlx"):
			matchedFiles.append(file)
	return matchedFiles

def findRbxmsInDir(dir):
	matchedFiles = []
	for file in os.listdir(dir):
		if fnmatch.fnmatch(file, '*.rbxmx'):
			matchedFiles.append(file)
	return matchedFiles

#  This func could be faster, I think
def findChildByName(ele, searchName):
	children = ele.findall('Item')
	for child in children:
		props = child.find('Properties')
		if props is not None:
			strings = props.findall('string')
			for string in strings:
				if string.get('name') and string.get('name') == 'Name' and string.text == searchName:
					return child

def findIndexForElement(ele):
	children = ele.findall('Item')
	for child in children:
		if child.get('class') == "NumberValue":
			props = child.find('Properties')
			if props is not None:
				strings = props.findall('string')
				for string in strings:
					if string.get('name') and string.get('name') == 'Name' and string.text == "ZIndex":
						valueProp = props.xpath("double[@name='Value']")
						#print("valueprop %s" % (valueProp))
						if valueProp is not None and len(valueProp) > 0:
							#print("found a numbervalue named Index with value %f" % (float(valueProp[0].text)))
							return float(valueProp[0].text)
	return 0.0

def findXmlElementForPath(tree, path):
	pathStack = []
	head = path
	while os.path.dirname(head) != "":
		head, tail = os.path.split(head)
		pathStack.append(tail)
	pathStack.reverse()

	resultEle = tree.getroot()
	for x in range(0, len(pathStack)-1):
		if resultEle is not None:
			resultEle = findChildByName(resultEle, pathStack[x])
	return resultEle

def findRbxmsRecursive(searchDir):
	foundPaths = []
	def visitfunc(arg, dirname, names):
		rbxms = findRbxmsInDir(dirname)
		for rbxm in rbxms:
			root, ext = os.path.splitext(rbxm)
			fullRelPath = os.path.join(dirname, rbxm)
			# print(rbxm + "=" + root + "+" + ext)
			if ext == '.rbxmx' and os.path.isfile(fullRelPath):
				foundPaths.append(fullRelPath)
	os.path.walk(searchDir, visitfunc, "")
	return foundPaths

def addRbxmsFromFolder(baseFileDir, tree):
	seenReferents = countReferentObjects(tree)
	oldDir = os.getcwd()  #  Push the previous directory
	os.chdir(baseFileDir)
	elementsToSort = []
	components = findRbxmsRecursive('.')
	for component in components:
		# Make sure the directory that we are adding the component to exists in the RBXL file
		xmlEle = findXmlElementForPath(tree, component)
		if xmlEle is not None:
			componentFp = open(component)
			filename = os.path.basename(component)
			base, _ = os.path.splitext(filename)

			if base is not None and componentFp is not None:
				componentTree = etree.parse(componentFp)

				# OLD REF COUNTING APPROACH TO REFS
				#offsetAllReferents(componentTree, seenReferents)
				#seenReferents += countReferentObjects(componentTree) # now add all the referents we counted

				# NEW UUID APPROACH TO REFS
				refMap = createReferentMap(componentTree)
				replaceOldReferents(componentTree, refMap)

				# get the root element for our saved out rbxm
				contents = componentTree.findall('Item')
				for item in contents:
					#  print("Adding model: %s" % (filename))
					xmlEle.append(item)
					## Since we just added an rbxm to this "folder" we need to remember to sort it based on its indices later
					if xmlEle not in elementsToSort:
						elementsToSort.append(xmlEle)

			componentFp.close()
	#  Sort XML objects based on indices
	for parentElement in elementsToSort:
		# children = list(parentElement)
		parentElement[:] = sorted(parentElement, key=lambda xmlEle: findIndexForElement(xmlEle), reverse=False)
		# print("Sorting xml elements %s" % (parentElement.xpath("Properties/string[@name='Name'][1]")[0].text))
	if oldDir is not None:
		os.chdir(oldDir) #  Pop the previous directory

def parseRBXRefToNumber(rbxRefString):
	result = None
	prog = re.compile("RBX(\d+)")
	matchResult = prog.match(rbxRefString)
	if matchResult:
		result = int(matchResult.group(1))
	return result



def findAllReferentItems(tree):
	# find all elements with the referent attribute
	return tree.xpath(r".//*[@referent]")

def findAllRefTags(tree):
	# find all Refs (Elements which point at referents)
	return tree.xpath(r".//Ref")

def countReferentObjects(tree):
	referableObjs = findAllReferentItems(tree)
	#for item in referableObjs:
	#	print(item.attrib)
	count = len(referableObjs)
	return count

def countRefTagObjects(tree):
	refObjs = findAllRefTags(tree)
	#for ref in refObjs:
	#	print(ref.text)
	count = len(refObjs)
	return count

def offsetAllReferents(tree, offsetAmount = 0):
	itemsWithReferent = findAllReferentItems(tree)
	for item in itemsWithReferent:
		rbxRefString = item.get("referent")
		if rbxRefString:
			refNumber = parseRBXRefToNumber(rbxRefString)
			if refNumber:
				offsetRefNumber = refNumber + offsetAmount
				item.set("referent", "RBX%d" % offsetRefNumber)
	refTags = findAllRefTags(tree)
	for refTag in refTags:
		rbxRefString = refTag.text
		if rbxRefString:
			refNumber = parseRBXRefToNumber(rbxRefString)
			if refNumber:
				offsetRefNumber = refNumber + offsetAmount
				refTag.text = "RBX%d" % offsetRefNumber

def isOldRefId(refId):
	# this is the most hacky part of the this
	# but I have to assume that if an id is a short string then it must not be a uuid
	return len(refId) < 32

def makeNewRefId():
	# TODO: we should check for collisions before saying this is okay to set it to; even though collision chance is astronomical
	return "RBX" + uuid.uuid4().hex  #.upper()

def createReferentMap(tree):
	oldRefToNewRefMap = dict()
	allRefItems = findAllReferentItems(tree)
	for item in allRefItems:
		rbxRefString = item.get("referent")
		if isOldRefId(rbxRefString):
			oldRefToNewRefMap[rbxRefString] = makeNewRefId()
	return oldRefToNewRefMap

def replaceOldReferents(tree, refMap):
	# Replace the ref property of elements
	allRefItems = findAllReferentItems(tree)
	for item in allRefItems:
		rbxRefString = item.get("referent")
		if rbxRefString in refMap:
			item.set("referent", refMap[rbxRefString])

	# Replace the ref pointers to elements
	refTags = findAllRefTags(tree)
	for refTag in refTags:
		rbxRefString = refTag.text
		if rbxRefString in refMap:
			refTag.text = refMap[rbxRefString]


def run():
	global VERSION
	print(("Merger: version %s created by %s") % (VERSION, "Kip Turner"))
	outputedFiles = []
	baseFileDir = '.'
	rbxlxFiles = findRbxlxInDir(baseFileDir)
	for rbxlxFile in rbxlxFiles:
		print("Found and using base roblox file: " + rbxlxFile)

		# Open our template file
		datasource = open(os.path.join(baseFileDir, rbxlxFile), 'r')
		tree = etree.parse(datasource)
		datasource.close()

		root, ext = os.path.splitext(rbxlxFile)
		allPath = os.path.join(baseFileDir, "all")
		rootPath = os.path.join(baseFileDir, root)
		if os.path.exists(allPath):
			print(allPath)
			addRbxmsFromFolder(allPath, tree)
		if os.path.exists(rootPath):
			print(rootPath)
			addRbxmsFromFolder(rootPath, tree)

		outFileName = root + "_output.rbxlx"

		# write out the modified tree
		outFile = open(outFileName, "w")
		outputedFiles.append(outFileName)
		#  I've set method to be html rather than the default xml, this seems weird, but is necassary for
		#  elimating the self-closing tags
		outFile.write(etree.tostring(tree.getroot(),encoding=None, method="html", xml_declaration=None, pretty_print=False, with_tail=True, standalone=None, doctype=None, exclusive=False, with_comments=True, inclusive_ns_prefixes=None))
		outFile.close()

	if len(rbxlxFiles) == 0:
		print "No base rbxlx file found!"

	SourceContent = os.path.join(baseFileDir, os.path.pardir , r"Content")
	ContentFolder = findContentFolder()
	if ContentFolder is not None and os.path.isdir(SourceContent):
		print("Copying from Content Folder: %s to Destination Content Folder: %s" % (SourceContent, ContentFolder))
		copytree(SourceContent, ContentFolder)

	RobloxExePath = None
	if ContentFolder is not None:
		RobloxExePath = os.path.abspath(os.path.join(ContentFolder, os.path.pardir, r"RobloxStudioBeta.exe"))

	try:
		opts, args = getopt.getopt(sys.argv[1:],"ar:", ["runall"])
	except getopt.GetoptError:
		print 'Proper usage: merger.py -r <file>'
		sys.exit(2)
	for opt, arg in opts:
		if opt == '-r':
			for outFile in outputedFiles:
				if arg + "_output.rbxlx" == outFile:
					if os.name == 'posix':  # OSX
						print("Opening: " + outFile)
						subprocess.call(["open", "-a" , "RobloxStudio" , outFile])
					elif os.name == 'nt':
						print("Opening: " + outFile)
						try:
							os.startfile(outFile)
						except WindowsError, why:
							try:
								subprocess.Popen([RobloxExePath , os.path.abspath(outFile)])
							except WindowsError, why:
								print("Error: Unable to find Roblox EXE at: %s , cuz %s" % (RobloxExePath, why))
		elif opt == '--runall' or opt == '-a':
			for outFile in outputedFiles:
				if os.name == 'posix':  # OSX
					print("Opening: " + outFile)
					subprocess.call(["open", "-a" , "RobloxStudio" , outFile])
				elif os.name == 'nt':
					print("Opening: " + outFile)
					try:
						os.startfile(outFile)
					except WindowsError, why:
						try:
							subprocess.Popen([RobloxExePath , os.path.abspath(outFile)])
						except WindowsError, why:
							print("Error: Unable to find Roblox EXE at: %s , cuz %s" % (RobloxExePath, why))

if __name__ == "__main__":
	run()
