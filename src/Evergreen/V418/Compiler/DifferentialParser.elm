module Evergreen.V418.Compiler.DifferentialParser exposing (..)

import Evergreen.V418.Compiler.AbstractDifferentialParser
import Evergreen.V418.Compiler.Acc
import Evergreen.V418.Parser.Block
import Evergreen.V418.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V418.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V418.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V418.Parser.Block.ExpressionBlock) Evergreen.V418.Compiler.Acc.Accumulator
