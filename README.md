# THICC
Thorough Harmonic Interface Creation Coordinator

# What is THICC?
THICC is a library for a library.
It unifies the Gspot GUI library and LOVE2D, making interface creation simple and fast. It is also extremely customizable, and does not require any modification of the base Gspot library.  

It is designed to reduce development time by integrating drawing, input, and other functions into the library.

# Features
1. UDims. UDims make scalable UIs easy. UDims allow for two types of sizes: scale and pixel. Scale takes the current width of the window or parent object, then multiplies it by your input. If you inputted, 0.5, it would take up half of the corresponding axis, and so on.  

2. Dominant Axes. When positioning an object, it can have a normal (XY) axis, or either a YY or XX. When these are set, both scale sizes are multiplied by the dominant axis (if one is set), rather thaan the normal XY.  



# Getting Started
Download Gspot here: https://notabug.org/pgimeno/Gspot  
Place "gspot.lua" in the same directory as THICC, or change the variable ```gui```.
