{-# OPTIONS_GHC -Wall #-}

module LogAnalysis where

import Log
import Safe (headMay, readMay)

parseMessage :: String -> LogMessage
parseMessage m = parseHelper $ words m

parseHelper :: [String] -> LogMessage
parseHelper [] = Unknown ""
parseHelper [_] = Unknown ""
parseHelper wrds@(x:y:ys) = case x of
    "I" -> LogMessage Info (read y) (unwords ys)
    "W" -> LogMessage Warning (read y) (unwords ys)
    "E" -> case (parseLevel ys) of
             Just n -> LogMessage (Error $ read y) n (unwords $ drop 1 ys)
             Nothing -> Unknown $ unwords wrds
    _   -> Unknown $ unwords wrds

parseLevel :: [String] -> Maybe Int
parseLevel = (readMay =<<) . headMay

parse :: String -> [LogMessage]
parse = map parseMessage . lines

insert :: LogMessage -> MessageTree -> MessageTree
insert (Unknown _)         t        = t
insert msg                 Leaf     = Node Leaf msg Leaf
insert msg                (Node l lm r) 
    | getLevel msg < getLevel lm    = Node (insert msg l) lm r
    | getLevel msg >= getLevel lm   = Node l lm (insert msg r)
insert (LogMessage _ _ _) (Node _ _  _)
                                    = error "We should not get here"

getLevel :: LogMessage -> Int
getLevel (LogMessage _ l _) = l
getLevel (Unknown _)        = error "LogMessage Unknown has no level"

build :: [LogMessage] -> MessageTree
build = foldr insert Leaf

inOrder :: MessageTree -> [LogMessage]
inOrder Leaf          = []
inOrder (Node l lm r) = inOrder l ++ [lm] ++ inOrder r

whatWentWrong :: [LogMessage] -> [String]
whatWentWrong = map show . filter ((>50) . getLevel) 
