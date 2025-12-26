# Assembly Pong!!

A game of Pong written entirely in assembly, made by drawing each pixel to the frame buffer - /dev/fb0.

![Demo](../assets/pong.gif)

## Installation

Installation is actually pretty simple, but you need to be on a specific type of machine:

  * Runinng x86_64 architecture
  * Has /dev/fb0
  * Allows TTY (text only terminals)

If you have all of these, then you can clone this repo into any directory you want:
```bash
git clone https://github.com/tesinclair/asm-pong.git
```
Then press CTRL-ALT-F5 to enter tty mode - or your preferred tty.
cd to the newly cloned repo, and run:

```bash
make && sudo build/a.out
```
And Boom! Your game of pong should be running.

Any time you want to run it after that you can simply run:
```bash
sudo build/a.out
```

*Writing to /dev/fb0 required root privs*

And if you really like the game, you can even add it to your path!

## Gameplay
The gameplay is quite simple, there is an ai which chases the ball, and you can use `w` and `s` to move your paddel up and down. The first side to get 10 points wins, and the game ends.

### Future

The list of things to do in the future is:
* Figure out why the movement is so jittery
* Add score rendering
