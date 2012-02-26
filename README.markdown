**LiveParametric** for *Google Sketchup*

### Introduction
LiveParametric is a more interactive version of the Parametric class supplied in Sketchup's Ruby examples. It lets you control a plugin in real-time using sliders, dropdown menus, and other UI elements, with a minimum of extra code required. 

### Example

Google's Ruby examples include a parametric model called OnionDome. By supplying different values in the input box, you can change the appearance of the dome significantly.

<table>
    <tr>
        <td align="center">Original Parametric</td>
        <td align="center">LiveParametric</td>
    <tr>
    <tr>
        <td align="center"><img width="350" alt="Original"       src="http://github.com/etjones/LiveParametric/blob/master/ETJ/Documentation/OnionDomeOrig.png?raw=true"></td>
        <td align="center"><img width="350" alt="LiveParametric" src="http://github.com/etjones/LiveParametric/blob/master/ETJ/Documentation/OnionDomeLP.png?raw=true"></td>
    </tr>
</table>

*But*, every time you want to change the dome, you have to right-click on the object, select "Edit Onion Dome", and then type new values.  It's difficult to explore very much with a system like that. 

LiveParametric makes it much easier to try out different appearances of a structure, by letting you change dimensions in realtime with sliders, checkboxes, or other UI elements.  And it required almost no code to convert the original Parametric OnionDome to a LiveParametric one.



### Installation

(parametric.rb, and others, are available [here](http://sketchup.google.com/intl/en/download/rubyscripts.html)).

### Using LiveParametric in your code