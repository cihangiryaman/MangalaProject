module Main where

import Data.List (intercalate)
import System.IO (BufferMode (NoBuffering), hSetBuffering, stdout)
import Text.Printf (printf)
import Text.Read (readMaybe)

data Player = Player1 | Player2 deriving (Eq)

data Board = Board
  { player1Holes :: [Int],
    player2Holes :: [Int],
    player1Store :: Int,
    player2Store :: Int
  }

data Position = Hole Player Int | Store Player deriving (Eq)

initialBoard :: Board
initialBoard = Board (replicate 6 4) (replicate 6 4) 0 0

main :: IO ()
main = do
  hSetBuffering stdout NoBuffering
  putStrLn "Modified Mangala"
  firstPlayer <- askFirstPlayer
  putStrLn ""
  putStrLn "Initial board:"
  printBoard initialBoard
  gameLoop initialBoard firstPlayer

gameLoop :: Board -> Player -> IO ()
gameLoop board currentPlayer
  | isGameOver board = announceGameOver board
  | otherwise = do
      putStrLn ""
      putStrLn $ showPlayer currentPlayer ++ "'s turn."
      hole <- askHoleSelection board currentPlayer
      let (nextBoard, nextPlayer, message) = playTurn board currentPlayer hole
      putStrLn message
      printBoard nextBoard
      gameLoop nextBoard nextPlayer

askFirstPlayer :: IO Player
askFirstPlayer = do
  putStr "Select the first player (1 or 2): "
  input <- getLine
  case readMaybe input :: Maybe Int of
    Just 1 -> pure Player1
    Just 2 -> pure Player2
    _ -> do
      putStrLn "Invalid input. Please enter 1 or 2."
      askFirstPlayer

askHoleSelection :: Board -> Player -> IO Int
askHoleSelection board player = do
  putStr $ "Choose a hole (1-6) for " ++ showPlayer player ++ ": "
  input <- getLine
  case readMaybe input :: Maybe Int of
    Nothing -> retry "Invalid input. Please enter a number."
    Just idx
      | idx < 1 || idx > 6 -> retry "Invalid hole number. Please choose between 1 and 6."
      | getHoleCount board player idx == 0 -> retry "That hole is empty. Choose a non-empty hole."
      | otherwise -> pure idx
  where
    retry msg = putStrLn msg >> askHoleSelection board player

playTurn :: Board -> Player -> Int -> (Board, Player, String)
playTurn board player idx
  | pickedStones == 1 =
      let board0 = setHoleCount board player idx 0
          landingPos = nextPosition player (Hole player idx)
          board1 = addStone board0 landingPos
          boardFinal = finalizeGameIfNeeded board1
          msg = showPlayer player ++ " moved 1 stone to the right; turn passes."
       in (boardFinal, otherPlayer player, msg)
  | otherwise =
      let board0 = setHoleCount board player idx 0
          board1 = addStone board0 (Hole player idx) -- One stone goes back to selected hole.
          (board2, lastPos) = distributeStones board1 player (Hole player idx) (pickedStones - 1)
          board3 = applyCaptureRule board2 player lastPos
          extraTurn = lastPos == Store player
          boardFinal = finalizeGameIfNeeded board3
          nextPlayer = if extraTurn then player else otherPlayer player
          msg =
            if extraTurn
              then showPlayer player ++ " gets an extra turn."
              else "Turn passes to " ++ showPlayer nextPlayer ++ "."
       in (boardFinal, nextPlayer, msg)
  where
    pickedStones = getHoleCount board player idx

distributeStones :: Board -> Player -> Position -> Int -> (Board, Position)
distributeStones board _ currentPos 0 = (board, currentPos)
distributeStones board movingPlayer currentPos n =
  let nextPos = nextPosition movingPlayer currentPos
      board' = addStone board nextPos
   in distributeStones board' movingPlayer nextPos (n - 1)

applyCaptureRule :: Board -> Player -> Position -> Board
applyCaptureRule board player lastPos =
  case lastPos of
    Hole holeOwner holeIdx
      | holeOwner == player
          && getHoleCount board player holeIdx == 1
          && oppositeCount > 0 ->
          let board1 = setHoleCount board player holeIdx 0
              board2 = setHoleCount board1 (otherPlayer player) oppositeIdx 0
              captured = 1 + oppositeCount
           in addToStore board2 player captured
    _ -> board
  where
    oppositeIdx = 7 - holeIndex lastPos
    oppositeCount = getHoleCount board (otherPlayer player) oppositeIdx

holeIndex :: Position -> Int
holeIndex (Hole _ idx) = idx
holeIndex (Store _) = error "Store position has no hole index."

nextPosition :: Player -> Position -> Position
nextPosition movingPlayer pos =
  case pos of
    Hole owner idx
      | owner == movingPlayer ->
          if idx < 6 then Hole owner (idx + 1) else Store owner
      | idx < 6 -> Hole owner (idx + 1)
      | otherwise -> Hole movingPlayer 1
    Store owner
      | owner == movingPlayer -> Hole (otherPlayer movingPlayer) 1
      | otherwise -> error "Opponent's store is not part of sowing path."

finalizeGameIfNeeded :: Board -> Board
finalizeGameIfNeeded board
  | all (== 0) (player1Holes board) =
      let remaining = sum (player2Holes board)
       in board
            { player2Holes = replicate 6 0,
              player1Store = player1Store board + remaining
            }
  | all (== 0) (player2Holes board) =
      let remaining = sum (player1Holes board)
       in board
            { player1Holes = replicate 6 0,
              player2Store = player2Store board + remaining
            }
  | otherwise = board

isGameOver :: Board -> Bool
isGameOver board = all (== 0) (player1Holes board) || all (== 0) (player2Holes board)

announceGameOver :: Board -> IO ()
announceGameOver board = do
  putStrLn ""
  putStrLn "Game over."
  putStrLn "Final board:"
  printBoard board
  putStrLn $ showPlayer Player1 ++ " store: " ++ show (player1Store board)
  putStrLn $ showPlayer Player2 ++ " store: " ++ show (player2Store board)
  putStrLn $
    case compare (player1Store board) (player2Store board) of
      GT -> "Winner: " ++ showPlayer Player1
      LT -> "Winner: " ++ showPlayer Player2
      EQ -> "Result: Draw"

printBoard :: Board -> IO ()
printBoard board = do
  let topValues = reverse (player2Holes board)
      bottomValues = player1Holes board
      topLabels = reverse [1 .. 6 :: Int]
      bottomLabels = [1 .. 6 :: Int]
      topRow = formatRow topLabels topValues
      bottomRow = formatRow bottomLabels bottomValues
      gap = replicate (length topRow - 18) ' '
  putStrLn "              Player 2 (top)"
  putStrLn $ "      " ++ topRow
  putStrLn $ printf "  P2 Store [%2d]%sP1 Store [%2d]" (player2Store board) gap (player1Store board)
  putStrLn $ "      " ++ bottomRow
  putStrLn "              Player 1 (bottom)"

formatRow :: [Int] -> [Int] -> String
formatRow labels values =
  intercalate " " $
    zipWith (\lbl val -> printf "[%d:%2d]" lbl val) labels values

otherPlayer :: Player -> Player
otherPlayer Player1 = Player2
otherPlayer Player2 = Player1

showPlayer :: Player -> String
showPlayer Player1 = "Player 1"
showPlayer Player2 = "Player 2"

getHoleCount :: Board -> Player -> Int -> Int
getHoleCount board Player1 idx = player1Holes board !! (idx - 1)
getHoleCount board Player2 idx = player2Holes board !! (idx - 1)

setHoleCount :: Board -> Player -> Int -> Int -> Board
setHoleCount board player idx value =
  case player of
    Player1 -> board {player1Holes = updateAt (idx - 1) value (player1Holes board)}
    Player2 -> board {player2Holes = updateAt (idx - 1) value (player2Holes board)}

addToStore :: Board -> Player -> Int -> Board
addToStore board Player1 n = board {player1Store = player1Store board + n}
addToStore board Player2 n = board {player2Store = player2Store board + n}

addStone :: Board -> Position -> Board
addStone board pos =
  case pos of
    Hole p idx -> setHoleCount board p idx (getHoleCount board p idx + 1)
    Store p -> addToStore board p 1

updateAt :: Int -> a -> [a] -> [a]
updateAt idx value xs = take idx xs ++ [value] ++ drop (idx + 1) xs
