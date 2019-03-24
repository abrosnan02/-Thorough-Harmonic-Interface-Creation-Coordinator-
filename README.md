# THICC
Thorough Harmonic Interface Creation Coordinator

# What is THICC?
THICC is a library for a library.
It unifies the Gspot GUI library and LOVE2D, making interface creation simple and fast. It is also extremely customizable, and does not require any modification of the base Gspot library.

# Features
1. UDims. UDims make scaling easy. They can be constructed with a table with four number arguments, and cover positioning as well as sizing. There are two types of variables: ```scale``` and ```pixels```. The pixels variable is what you would expect. Scale is the width of the screen multiplied by the x or y. The scale dynamically updates when the screen is resized. These two combine to make scaling UIs quick and easy. Examples are listed below.

Size  
```{xScale, xPixels, yScale, yPixels}```  
```{1, 0, 0, 100}``` This spans the entire screen, but has a consistent Y of 100 pixels.  
```{0.5, 0, 0.5, 100}``` This spans the half of the screen, and half of the height, plus 100 pixels.

Position  
```{xScale, xPixels, yScale, yPixels}```  
```{.5, 100, 0.1, 100}``` This is halfway across the screen, plus 100 pixels. It is also a 10% down plus 100 pixels.  
```{0.25, 0, 0, 50}``` This is a quarter across the screen, and 50 pixels down.  


# Getting Started
Download Gspot here: https://notabug.org/pgimeno/Gspot
Place "gspot.lua" in the same directory as thicc, or change the variable ```gui```.
