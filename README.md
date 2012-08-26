Robot Build Fight
=================

Asynchronous multiplayer robot programming game based on wireworld (http://en.wikipedia.org/wiki/Wireworld). To understand the dynamics of the simulation, see the wikipedia page.

When you run a battle, your circuit is uploaded to the server and another player's circuit is downloaded to act as you opponent. The idea is that a metagame will develop, with  circuits in some sense evolving through natural selection as better robots are copied and improved upon. In practice this may not turn out so well as many supporting features were not completed in time and there is unlikely to be a large enough layer base.

Controls
--------
* Left mouse: place/remove wire or paste selection
* Right mouse: select/cut area
* Ctrl+Left mouse: Cycle wire/electron head/electron tail
* L: load last opponent's circuit
* Ctrl+z: undo last change to circuit
* Space: begin battle

Inputs
------
On the left of the circuit are three inputs - three different distance sensors that insert electrons when the robots are a given distance apart (as a percentage of the arena width).

Outputs
-------
There are five outputs on the right hand side of the circuit  that are continuously activated by receiving at least one electron every eight steps - three weapons and two movement controls. The three weapons are the Laser (which does the least damage), the Rocket (which also damages you if the opponent is too close) and the Claw (which can only attack at close range). If two weapons are active at the same time, each deals one half of its usual damage (one third if three are active). The remaining two outputs move your robot forward and back (for your robot, left and right on the battle display respectively).

Battle display
--------------
The number in the top right represents your health and the top left your opponent's. The two boxes in the middle represent the relative spacing of the robots.


I hope to make a windows binary when I've had some sleep. Until then you need love2d (https://love2d.org/) to run it.
