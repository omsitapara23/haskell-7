module Main where

import Graphics.Gloss
import Graphics.Gloss.Data.Color

import Game
import Logic
import Rendering

window = InWindow "Functional" (screenWidth, screenHeight) (100, 100)
backgroundColor = makeColor 255 248 220 255

main :: IO ()
main = play window backgroundColor 30 initialGame gameAsPicture transformGame (const id)
