<p align="center">

&#x20; <img src="https://github.com/Vladislav07v/Duckmension-VS/tree/main/extra/logo3d.png" alt="Duckmension VS logo" />

</p>

# Duckmension-VS

A multiplatform multiplayer platformer game starring a duck



## Features

1. 50 levels to race through.

2\. Multiplayer and singleplayer play with two game modes (Timed Run and Full Run).

3\. Play with a keyboard, mouse or a controller.

4\. Buy cosmetics for your duck with the cookies you've earned from your wins.

5\. Easy server hosting and joining with a lobby system for more private sessions.

6\. Easily portable to other platforms. It already has a Windows and a Nintendo 3DS port.



## How to play

Simply download the game from the releases page or from itch.io and hit "singleplayer" or "multiplayer" on the title screen.



## How to create and connect to a server

1. Download <a href="https://nightly.link/love2d/love/workflows/main/main">LÖVE 12.0</a> and `main\_server.lua`.
2. Rename the lua file to `main.lua` and open it with lovec.exe.
3. On the command prompt, copy the IP address, port and encryption key into the text fields in the connection menu. The text below would turn green to indicate the client has connected and a message would pop up in the server's console.



## How to compile from source

1. Download the Duckmension VS source code and install a LUA IDE like <a href="https://studio.zerobrane.com/">ZeroBrane Studio</a>.
2. Set the path to the compiler (LÖVE 12.0) and change the preferred version of LUA to LÖVE.
3. Execute the project.



## Libraries used in the project

* <a href="https://github.com/lovebrew/lovepotion">Lovepotion</a> for easy compiling and conversion of assets for multiple game consoles.
* <a href="https://github.com/tesselode/baton">Baton</a> for setting controls.
* <a href="https://github.com/lovebrew/nest">nëst</a> for quickly testing console compatibility.
* <a href="https://github.com/lunarmodules/luasocket">Luasocket</a> for the multiplayer functionality and sharing data between the game and website.

