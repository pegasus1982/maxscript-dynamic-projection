# Max Script Requirements

## ​​Short Pitch:

​​ Write a max script that takes a list of positions in 2d, a target object and a starting position selection by the user as inputs to generate a list of positions in 3d based on a deformation of the 2d positions over the object.

​​  

## ​​Details:

​​The objective of the script would be to take an array of pre-defined positions in 2d space (around 100 dots in a grid-like configuration) and project them over a 3d body to generate a new set of positions in 3d.

​​The process would work similarly to a "project" modifier, but dynamic and interactive. 

​​  

​​In order for the script to place the array properly, it needs some inputs from the user.

​​  

## ​​Components:

1. ​​The source file for the 2d array (a CSV file with a Point ID and an X and Y position value)

​​  

3. ​​A selected position placed over the surface. A null object can mark the spot. This selected position corresponds to the midpoint of both the 2d and 3d arrays. This point is also oriented along the normal of the surface.

4. ​​A radius setting. Essentially configuring the distance between the center and the border of the 2d array.

5. ​​An orientation setting to define the array rotation.

​​  

​​The final "projected" positions should be visible in the view-port and interactive in real time. They can be displayed as null objects for example.

​​The script also needs to handle two arrays simultaneously.

## ​​Proposed user interface:

![Positioning Example](screenshots/1.png)

​​The user selects a file that contains the 2d array positions

![Positioning Example](screenshots/2.jpeg)

​​The user clicks a button on the script to activate the desired array to be placed. (left or right)

![Positioning Example](screenshots/3.png)

​​The user clicks on the target object. A single click selects the object and sets the center point in the click location.

![Positioning Example](screenshots/4.png)

​​A null object appears over the surface, alongside with a circle representing the radius parameter and a handle that controls the orientation. An array of nulls are also placed over the surface at the correct projected positions.

​​The user can grab the center null tu adjust the position, and the points move in real time.

![Positioning Example](screenshots/5.png)

​​The user can grab the handle to rotate the array, and the nulls move in real time.

![Positioning Example](screenshots/6.png)

​​After the user is done adjusting, they can select the other array and repeat the process.

![Positioning Example](screenshots/7.png)

![Positioning Example](screenshots/8.png)

![Positioning Example](screenshots/9.png)

![Positioning Example](screenshots/10.png)

​​The script features a radius parameter that affects both arrays simultaniously.

![Positioning Example](screenshots/11.png)

​​After both arrays are placed, the user can click on the export button to export a list of 3d position.

![Positioning Example](screenshots/12.png)

​​The output should be a CSV file saved in the same folder as the source array. The name of the file should be the name of the object. 

## Extended Feature:

Spherical projection.

Current projection is planar. 
![Positioning Example](screenshots/13.png)

We need a feature that enables “spherical projection”

Essentially, a circle is created with the center of the array as the center and the position of the point as the radius, the third reference axis is the normal orientation. The point is then placed at the intersection between the circle and the object. 

Here is a 2d representation of this:
![Positioning Example](screenshots/14.png)

Here is a representation of a single line of points in 3d
![Positioning Example](screenshots/15.png)

The script needs to create a circle for each point 