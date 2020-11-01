#  Using XPC to execute Python code in your Mac app

This project contains an example for building a sample application that places a bespoke Python interpreter into an XPC process for execution of python commands. It uses proxy objects to allow for complex data structures in the App to hand back information about themselves.

If you Build & Run PythonTest, you'll get a window containing 4 text boxes:
- Top box is for the formula to calculate
- Second box is for the results of the execution
- The _a_ box is for adding a string variable `a` for execution
- The _b_ box is for adding a numeric variable `b` for execution 
See notes below on what to put in the formula box.

If you Test FormulaExecutor, you will exercise the XPC using a set of pre-defined tests.

## Python Framework sourcing

Due to aging Python frameworks on the Mac (and the threat from Apple that they would be removing the Framework in future versions of the OS), I embedded a relocatable copy of the framework by following the lead of: 
    https://github.com/gregneagle/relocatable-python
modified and now available at:
    https://github.com/cluetrust/relocatable-python

With a couple of adjustments to re-sign the framework. 
NOTE: For 3.8.0-3.8.6, there's a header problem where the cpython/pystate.h includes cpython/initconfig.h instead of initconfig.h; this has to be fixed or it will not compile code that expects to use the framework without 

## Build Notes

1. You will need to grab the Python.framework and place it in `FormulaExecutor` directory, so that it's located for linking. Use the relocator from ClueTrust (https://github.com/cluetrust/relocatable-python) above, as it reloactes in a slightly different manner than the original).
2.  Because of the format of the Python.framework, it can't be resigned by Xcode. Copy without signing and then re-sign when you build your final product.


## Things to try in PythonTest

### Geometry objects

Each call contains a geometry object (named _geometry_ in the interpreter). This is the object whose operations are proxied back into the running application. If you want to see the stack trace, put a break point in MapGeometry's methods.

geometry is set to a box (0,0) width=50, height=20
geometry objects can't be returned directly, but do have methods on them, such as:

- geometry.bbox() : rect (x,y,width,height)
    - geometry.bbox().x
    - geometry.bbox().y
    - geometry.bbox().width
    - geometry.bbox().height
- geometry.length() : length of complete outline (x2)
- geometry.area() : area of complete geometry (x2)
- geometry.length(1) : length of complete outline
- geometry.area(1) : area of complete geometry

### Python strings

Python has a lot of methods on strings (https://docs.python.org/3/library/stdtypes.html#string-methods)

- "hi".upper()
- a.center(20,"*")

### Python datetime

Datetime is loaded, so you can perform date functions; returned values are long strings of the datetime.

- datetime.now()

### Errors

Errors are printed if they are received. The error handler in PyComputation makes a significant effort to give good error messages.
For example try:

- c
- geometry
- sqrt('a')
- 

### Variables

Local variables are sent in the `info` dictionary. In the example program, we let you set a (a string) and b (a number). If you use this in your own application, any translatable data type would be possible.

Try setting a to a string, and b to a number and try:

- a.upper()
- sqrt(b)


