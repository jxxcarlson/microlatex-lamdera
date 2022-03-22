module Parser.Forest exposing (Forest)

import Tree exposing (Tree)


type alias Forest a =
    List (Tree a)
