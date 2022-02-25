module Evergreen.V5.L0 exposing (..)

import Evergreen.V5.Parser.Block
import Tree


type alias SyntaxTree =
    List (Tree.Tree Evergreen.V5.Parser.Block.ExpressionBlock)
