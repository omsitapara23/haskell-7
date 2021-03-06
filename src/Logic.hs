module Logic where

import Data.Array
import Data.Foldable ( asum )

import Game
import Graphics.Gloss.Interface.Pure.Game

isCoordCorrect (x, y) = elem (x, y) [ (0, 0),
                                      (0, 3),
                                      (0, 6),
                                      (1, 1),
                                      (1, 3),
                                      (1, 5),
                                      (2, 2),
                                      (2, 3),
                                      (2, 4),
                                      (3, 0),
                                      (3, 1),
                                      (3, 2),
                                      (3, 4),
                                      (3, 5),
                                      (3, 6),
                                      (4, 2),
                                      (4, 3),
                                      (4, 4),
                                      (5, 1),
                                      (5, 3),
                                      (5, 5),
                                      (6, 0),
                                      (6, 3),
                                      (6, 6) ]

switchPlayer game checker
    | checker == 1 && gamePlayer game == Player1 = game { gamePlayer = Player2 }
    | checker == 1 && gamePlayer game == Player2 = game { gamePlayer = Player1 }
    | otherwise = game

switchPlayer1 game =
    case gamePlayer game of
        Player1 -> game { gamePlayer = Player2 }
        Player2 -> game { gamePlayer = Player1 }

mousePosAsMenuCellCoord (x, y) = ( floor((y + (fromIntegral screenHeight * 0.5)) / (fromIntegral screenHeight))
                               , floor((x + (fromIntegral screenWidth * 0.5)) / (fromIntegral screenWidth / 2))
                               )

mousePosAsCellCoord :: (Float, Float) -> (Int, Int)
mousePosAsCellCoord (x, y) = ( floor((y + (fromIntegral screenHeight * 0.5)) / cellHeight)
                             , floor((x + (fromIntegral screenWidth * 0.5)) / cellWidth)
                             )

countCells :: Cell -> Board -> Int
countCells cell = length . filter ((==) cell) . elems

checkGameOver game
    | p1 <= 2 =
        game { gameState = GameOver $ Just Player2 }
    | p2 <= 2 =
        game { gameState = GameOver $ Just Player1 }
    | countCells cell board == 0 =
        game { gameState = GameOver Nothing }
    -- 'checkBoardForViable game player' returns 0 if no viable move for 'player' in that game state
    | checkBoardForViable game == 0 && player == Player1 && (player1Stone game) > (maxStone1 game)  =
        game { gameState = GameOver $ Just Player2 }
    | checkBoardForViable game == 0 && player == Player2 && (player1Stone game) > (maxStone1 game) =
        game { gameState = GameOver $ Just Player1 }
    | otherwise = game
    where board = gameBoard game
          cell  = Full Dot
          player = gamePlayer game
          p1    = removeStone1 game
          p2    = removeStone2 game

checkBoardForViable game
    | traverseBoard game (0, 0) == 0 =
        0
    | otherwise = 1

traverseBoard game (x, y)
    | checkNeighbour game (x, y) == 0 && x <= 5 =
        -- Means no viable move for player at (x, y)
        traverseBoard game (x + 1, y)
    | checkNeighbour game (x, y) == 1 && Full player /= board ! (x, y) && x <= 5 =
        -- Means no viable move for player at (x, y)
        traverseBoard game (x + 1, y)
    | checkNeighbour game (x, y) == 0 && x == 6 && y <= 5 =
        traverseBoard game (0, y + 1)
    | checkNeighbour game (x, y) == 1 && Full player /= board ! (x, y) && x == 6 && y <= 5 =
        traverseBoard game (0, y + 1)
    | checkNeighbour game (x, y) == 0 && x == 6 && y == 6 =
        0
    | checkNeighbour game (x, y) == 1 && Full player /= board ! (x, y) && x == 6 && y == 6 =
        0
    | otherwise = 1
        where board = gameBoard game
              player = gamePlayer game

playerTurn :: Game ->(Int, Int) -> Game
playerTurn game cellCoord
    -- If player1Stone <= maxStone1 and chance = player1
    -- then player1Stone++ and replace cellCoord with Full player
    -- Else don't recognise the click (for now)
    | isCoordCorrect cellCoord && board ! cellCoord == Full Dot && (takeOther game) >= 8 && player == Player1 && (player1Stone game) <= (maxStone1 game) =
         checkGameOver
        $ listUnblockerV
        $ listUnblockerH
        $ switchPlayer game { gameBoard = board // [(cellCoord, Full player)], player1Stone = n1 + 1  }
        $ playerSwitcherConfirm
        $ game { gameBoard = board // [(cellCoord, Full player)], player1Stone = n1 + 1 }
    | isCoordCorrect cellCoord && board ! cellCoord == Full Player1 && player == Player1 && (removeStone1 game) > 3 && (player1Stone game) > (maxStone1 game) && (movedCoordSet game) ==  0 && (takeOther game) >= 8 =
         -- Store the current clicked coordinates (only if atleast one neighbour is a 'dot')
         -- make 'stored' = 1
         -- Don't give chance to the next player
         -- If stored == 1, then check if curent click is a neighbour of stored coords (and then remove the stored coords and render the current clicked coords)
         checkGameOver
         $ setCoords game cellCoord
         $ checkNeighbour game cellCoord
    | isCoordCorrect cellCoord && board ! cellCoord == Full Dot && player == Player1 && (removeStone1 game) > 3 && (player1Stone game) > (maxStone1 game) && (movedCoordSet game) == 1 && (validCellCoords game cellCoord mCoords) && (takeOther game) >= 8 =
          checkGameOver
          $ listUnblockerV
          $ listUnblockerH
          $ switchPlayer game { gameBoard = board // [(cellCoord, Full player), (mCoords, Full Dot)],  moveCoords = (-1, -1), movedCoordSet = 0 }
          $ playerSwitcherConfirm
        --   $ setCoordsBack -- this sets the moveCoords back to (-1, -1)
          $ game { gameBoard = board // [(cellCoord, Full player), (mCoords, Full Dot)] }
    -- Fly Logic when 3 stones are left
    | isCoordCorrect cellCoord && board ! cellCoord == Full Player1 && player == Player1 && (removeStone1 game) <= 3 && (movedCoordSet game) ==  0 && (takeOther game) >= 8 =
         -- Store the current clicked coordinates (only if atleast one neighbour is a 'dot')
         -- make 'stored' = 1
         -- Don't give chance to the next player
         -- If stored == 1, then check if curent click is a neighbour of stored coords (and then remove the stored coords and render the current clicked coords)
         checkGameOver
         $ setCoords game cellCoord 1
    | isCoordCorrect cellCoord && board ! cellCoord == Full Dot && player == Player1 && (removeStone1 game) <= 3 && (movedCoordSet game) == 1 && board ! cellCoord == Full Dot && (takeOther game) >= 8 =
          checkGameOver
          $ listUnblockerV
          $ listUnblockerH
          $ switchPlayer game { gameBoard = board // [(cellCoord, Full player), (mCoords, Full Dot)],  moveCoords = (-1, -1), movedCoordSet = 0 }
          $ playerSwitcherConfirm
        --   $ setCoordsBack -- this sets the moveCoords back to (-1, -1)
          $ game { gameBoard = board // [(cellCoord, Full player), (mCoords, Full Dot)] }
    -- Fly logic ends
    | isCoordCorrect cellCoord && board ! cellCoord == Full Dot && (takeOther game) >= 8 && player == Player2 && (player2Stone game) <= (maxStone2 game) =
         checkGameOver
        $ listUnblockerV
        $ listUnblockerH
        $ switchPlayer game { gameBoard = board // [(cellCoord, Full player)], player2Stone = n2 + 1  }
        $ playerSwitcherConfirm
        $ game { gameBoard = board // [(cellCoord, Full player)], player2Stone = n2 + 1 }
    | isCoordCorrect cellCoord && board ! cellCoord == Full Player2 && player == Player2 && (removeStone2 game) > 3 && (player2Stone game) > (maxStone2 game) && (movedCoordSet game) == 0 && (takeOther game) >= 8 =
         -- Store the current clicked coordinates (only if atleast one neighbour is a 'dot')
         -- make 'stored' = 1
         -- Don't give chance to the next player
         -- If stored == 1, then check if curent click is a neighbour of stored coords (and then remove the stored coords and render the current clicked coords)
         checkGameOver
         $ setCoords game cellCoord
         $ checkNeighbour game cellCoord
    | isCoordCorrect cellCoord && board ! cellCoord == Full Dot && player == Player2 && (removeStone2 game) > 3 && (player2Stone game) > (maxStone2 game) && (movedCoordSet game) == 1 && (validCellCoords game cellCoord mCoords) && (takeOther game) >= 8 =
          checkGameOver
          $ listUnblockerV
          $ listUnblockerH
          $ switchPlayer game { gameBoard = board // [(cellCoord, Full player), (mCoords, Full Dot)],  moveCoords = (-1, -1), movedCoordSet = 0 }
          $ playerSwitcherConfirm
        --   $ setCoordsBack -- this sets the moveCoords back to (-1, -1)
          $ game { gameBoard = board // [(cellCoord, Full player), (mCoords, Full Dot)] }
    -- Fly Logic when 3 stones are left
    | isCoordCorrect cellCoord && board ! cellCoord == Full Player2 && player == Player2 && (removeStone2 game) <= 3 && (movedCoordSet game) ==  0 && (takeOther game) >= 8 =
         -- Store the current clicked coordinates (only if atleast one neighbour is a 'dot')
         -- make 'stored' = 1
         -- Don't give chance to the next player
         -- If stored == 1, then check if curent click is a neighbour of stored coords (and then remove the stored coords and render the current clicked coords)
         checkGameOver
         $ setCoords game cellCoord 1
    | isCoordCorrect cellCoord && board ! cellCoord == Full Dot && player == Player2 && (removeStone2 game) <= 3 && (movedCoordSet game) == 1 && board ! cellCoord == Full Dot && (takeOther game) >= 8 =
          checkGameOver
          $ listUnblockerV
          $ listUnblockerH
          $ switchPlayer game { gameBoard = board // [(cellCoord, Full player), (mCoords, Full Dot)],  moveCoords = (-1, -1), movedCoordSet = 0 }
          $ playerSwitcherConfirm
        --   $ setCoordsBack -- this sets the moveCoords back to (-1, -1)
          $ game { gameBoard = board // [(cellCoord, Full player), (mCoords, Full Dot)] }
    -- Fly logic ends
    | isCoordCorrect cellCoord && board ! cellCoord /= Full Dot && (takeOther game) < 8 && board ! cellCoord /= Full player = switchPlayer1 $ listUnblockerV $ listUnblockerH $ removerV cellCoord  $ removerH cellCoord game
    | otherwise = game
        where board = gameBoard game
              player = gamePlayer game
              mCoords = moveCoords game
              n1 = player1Stone game
              n2 = player2Stone game

-- 'movedCoordSet' = 1 means the movedCoords are set

validCellCoords game (x, y) mCoords
    | isUpNeighbour game (x, y) mCoords == 1 =
        True
    | isDownNeighbour game (x, y) mCoords == 1 =
        True
    | isLeftNeighbour game (x, y) mCoords == 1 =
        True
    | isRightNeighbour game (x, y) mCoords == 1 =
        True
    | otherwise = False

isUpNeighbour game (x, y) mCoords
    | x <= 5 && board ! (x + 1, y) == Empty =
        isUpNeighbour game (x + 1, y) mCoords
    | x <= 5 && (x + 1, y) == mCoords =
        1
    | otherwise = 0
        where board = gameBoard game

isDownNeighbour game (x, y) mCoords
    | x >= 1 && board ! (x - 1, y) == Empty =
        isDownNeighbour game (x - 1, y) mCoords
    | x >= 1 && (x - 1, y) == mCoords =
        1
    | otherwise = 0
        where board = gameBoard game

isLeftNeighbour game (x, y) mCoords
    | y >= 1 && board ! (x, y - 1) == Empty =
        isLeftNeighbour game (x, y - 1) mCoords
    | y >= 1 && (x , y - 1) == mCoords =
        1
    | otherwise = 0
        where board = gameBoard game

isRightNeighbour game (x, y) mCoords
    | y <= 5 && board ! (x, y + 1) == Empty =
        isRightNeighbour game (x, y + 1) mCoords
    | y <= 5 && (x, y + 1) == mCoords =
        1
    | otherwise = 0
        where board = gameBoard game

setCoordsBack game =
    game { moveCoords = (-1, -1), movedCoordSet = 0 }

setCoords game cellCoord checker
    | checker == 1 =
        game { moveCoords = cellCoord, movedCoordSet = 1 }
    | otherwise = game

checkNeighbour game cellCoord
    | isUp game (x, y) == 1 =
        1
    | isDown game (x, y) == 1 =
        1
    | isLeft game (x, y) == 1 =
        1
    | isRight game (x, y) == 1 =
        1
    | otherwise = 0
        where x = fst cellCoord
              y = snd cellCoord

isUp game (x, y)
    | x <= 5 && board ! (x + 1, y) == Empty =
        isUp game (x + 1, y)
    | x <= 5 && board ! (x + 1, y) == Full Dot =
        1
    | otherwise = 0
        where board = gameBoard game

isDown game (x, y)
    | x >= 1 && board ! (x - 1, y) == Empty =
        isDown game (x - 1, y)
    | x >= 1 && board ! (x - 1, y) == Full Dot =
        1
    | otherwise = 0
        where board = gameBoard game

isLeft game (x, y)
    | y >= 1 && board ! (x, y - 1) == Empty =
        isLeft game (x, y - 1)
    | y >= 1 && board ! (x, y - 1) == Full Dot =
        1
    | otherwise = 0
        where board = gameBoard game

isRight game (x, y)
    | y <= 5 && board ! (x, y + 1) == Empty =
        isRight game (x, y + 1)
    | y <= 5 && board ! (x, y + 1) == Full Dot =
        1
    | otherwise = 0
        where board = gameBoard game

transformGame (EventKey (MouseButton LeftButton) Up _ mousePos) game =
    case gameState game of
        Menu -> openGame game $ mousePosAsMenuCellCoord mousePos
        Running -> playerTurn game $ mousePosAsCellCoord mousePos
        GameOver _ -> initialGame
transformGame _ game = game

openGame :: Game ->(Int, Int) -> Game
openGame game menuCell
    | menuCell == (0, 0) = game { gameState = Running }
    | menuCell == (0, 1) = game { gameState = Running }


horizontalLine game  [row, column, distance]    | board!(row, column) == board!(row, column + distance) && board!(row, column) == board!(row, column + 2*distance) && board!(row, column) == player  = player
                                                          | otherwise = Full Dot
                                                                where  board = gameBoard game
                                                                       player = Full $ gamePlayer game

verticleLine game  [column, row, distance]      | board!(row, column) == board!(row + distance, column) && board!(row, column) == board!(row + 2*distance, column) && board!(row, column) == player  = player
                                                          | otherwise = Full Dot
                                                                where  board = gameBoard game
                                                                       player = Full $ gamePlayer game

-- horizontalLine game  [((row, column), data)]                | board!(row, column) == board!(row, column + distance) && board!(row, column) == board!(row, column + 2*distance) && board!(row, column) == player && (data == 10 || data == 7 || data == 4 ) = player
--                                                             | otherwise = Full Dot
--                                                                 where  board = gameBoard game
--                                                                        player = Full $ gamePlayer game

-- verticleLine game  [(row, column), data]                  | board!(row, column) == board!(row + distance, column) && board!(row, column) == board!(row + 2*distance, column) && board!(row, column) == player && (data == 10 || data == 7 || data == 4 ) = player
--                                                           | otherwise = Full Dot
--                                                                 where  board = gameBoard game
--                                                                        player = Full $ gamePlayer game

horizontalLineUnblock game  [row, column, distance]    | (board!(row, column) /= board!(row, column + distance) || board!(row, column) /= board!(row, column + 2*distance))   = Full Dot
                                                          | otherwise = player
                                                                where  board = gameBoard game
                                                                       player = Full $ gamePlayer game

verticleLineUnblock game  [column, row, distance]      | (board!(row, column) /= board!(row + distance, column) || board!(row, column) /= board!(row + 2*distance, column))  = Full Dot
                                                          | otherwise = player
                                                                where  board = gameBoard game
                                                                       player = Full $ gamePlayer game




finalHorizontalCheck game  = map (horizontalLine game) $ gameList game
finalVerticalCheck game = map (verticleLine game) $ gameList game

finalHorizontalCheckUnblocker game  = map (horizontalLineUnblock game) $ gameList game
finalVerticalCheckUnbloccker game = map (verticleLineUnblock game) $ gameList game

-- viewUpdate game     | (finalHorizontalCheck game)!!1 == Full Player1 = game {gameBoard = board // [((3,2), Full Player2)]}
--                     | (finalVerticalCheck game)!!1 == Full Player2 = game {gameBoard = board // [((6,6), Full Player1)]}
--                     | otherwise =  game {gameBoard = board // [((6,0), Full Player1)]}
--                         where board = gameBoard game

takeOtherH game n        | n < 8 && ((finalHorizontalCheck game)!!n == player) && validityH!!n == 1 = n
                        | n == 8 = 8
                        | otherwise =  takeOtherH game (n + 1)
                            where board = gameBoard game
                                  player = Full $ gamePlayer game
                                  validityH = checkListH game

takeOtherV game n       | n < 8 && ((finalVerticalCheck game)!!n == player) && validityV!!n == 1 = n
                        | n == 8 = 8
                        | otherwise =  takeOtherV game (n + 1)
                            where board = gameBoard game
                                  player = Full $ gamePlayer game
                                  validityV = checkListV game

takeOther game         |  (((takeOtherH game 0) < 8) || ((takeOtherV game 0) < 8)) = 1
                        | otherwise = 8

unblockOtherH game k    | k < 8 && ((finalHorizontalCheckUnblocker game)!!k == Full Dot) && validityH!!k == 0 = k
                        | k == 8 = 8
                        | otherwise =  unblockOtherH game (k + 1)
                            where board = gameBoard game
                                  validityH = checkListH game

unblockOtherV game k   | k < 8 && ((finalVerticalCheckUnbloccker game)!!k == Full Dot) && validityV!!k == 0 = k
                        | k == 8 = 8
                        | otherwise =  unblockOtherV game (k + 1)
                            where board = gameBoard game
                                  validityV = checkListV game

listUnblockerH  game | (unblockOtherH game 0) < 8 = game { checkListH = (replaceNth 1 validityH $ unblockOtherH game 0)}
                     | otherwise = game
                        where validityH = checkListH game

listUnblockerV  game | (unblockOtherV game 0) < 8 = game { checkListV = (replaceNth 1 validityV $ unblockOtherV game 0)}
                     | otherwise = game
                        where validityV = checkListV game



-- listUnblocker game    | (unblockOther game 0) < 8 && validityH!!(unblockOther game 0) == 0 && ((finalHorizontalCheckUnblocker game)!!(unblockOther game 0) == Full Dot) = game { checkListH = (replaceNth 1 validityH $ unblockOther game 0)}
--                             | (unblockOther game 0) < 8 && validityV!!(unblockOther game 0) == 0 && ((finalVerticalCheckUnbloccker game)!!(unblockOther game 0) == Full Dot) = game { checkListV = (replaceNth 1 validityV $ unblockOther game 0)}
--                             | otherwise = game
--                                 where
--                                     validityH = checkListV game
--                                     validityV = checkListV game
-- checkListUpdater game n    | n < 8 = game  { checkList = (replaceNth n listf 0) }
--                            | otherwise = game
--                             where
--                                 listf = checkList game

tattiList game = game { checkListV = (replaceNth 1 validityV 0) }
                    where validityV = checkListV game
replaceNth newVal (x:xs) n
                        | n == 0 = newVal:xs
                        | otherwise = x:replaceNth newVal xs (n - 1)



removerH cellCoord game          | (takeOtherH game 0) < 8 && player == Player1  = game { gameBoard = board // [(cellCoord, Full Dot)], removeStone2 = stone2 - 1,   checkListH = (replaceNth 0 listH $ takeOtherH game 0)}
                                 | (takeOtherH game 0) < 8 && player == Player2  = game { gameBoard = board // [(cellCoord, Full Dot)], removeStone1 = stone1 - 1,   checkListH = (replaceNth 0 listH $ takeOtherH game 0)}
                                 | otherwise = game
                                    where board = gameBoard game
                                          listH = checkListH game
                                          player = gamePlayer game
                                          stone1 = removeStone1 game
                                          stone2 = removeStone2 game



removerV cellCoord game          | (takeOtherV game 0) < 8 && player == Player1  = game { gameBoard = board // [(cellCoord, Full Dot)], removeStone2 = stone2 - 1,  checkListV = (replaceNth 0 listV $ takeOtherV game 0)}
                                 | (takeOtherV game 0) < 8 && player == Player2  = game { gameBoard = board // [(cellCoord, Full Dot)], removeStone1 = stone1 - 1,  checkListV = (replaceNth 0 listV $ takeOtherV game 0)}
                                 | otherwise = game
                                    where board = gameBoard game
                                          listV = checkListV game
                                          player = gamePlayer game
                                          stone1 = removeStone1 game
                                          stone2 = removeStone2 game


playerSwitcherConfirm game | (takeOther game)  < 8 = 0
                           | otherwise = 1

printerGame game = print (listV)
                    where listV = checkListV game


-- isTrueTakeOther | takeOther 0 (finalHorizontalCheck game)  < 9 = game {gameBoard = board // [(, Full Player2)]}

-- listUpdater game | elem ([] : player) (finalHorizontalCheck) =  game {gameBoard = board // [((3,2), Full Player2)]}
--                  | elem ([] : player) (finalVerticalCheck) =  game {gameBoard = board // [((6,6), Full Player2)]}
--                  | otherwise  = game {gameBoard = board // [((6,0), Full Player1)]}
--                     where board = gameBoard game
--                           player = Full $ gamePlayer game





-- transformGame (EventKey (MouseButton LeftButton) Up _ mousePos) game =
--     case gameState game of
--         Running -> viewUpdate game
