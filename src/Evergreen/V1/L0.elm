module Evergreen.V1.L0 exposing (..)

import Evergreen.V1.Parser.Block
import Tree


type alias SyntaxTree =
    List (Tree.Tree Evergreen.V1.Parser.Block.ExpressionBlock)
